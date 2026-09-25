/// Attaches the access token, and refreshes it exactly once when it expires.
///
/// The single-flight guard is the point. A screen like Home fires several
/// requests at once; when the hour-long access token expires they all come
/// back 401 together. Without a guard that is six concurrent refreshes, and
/// because the server rotates refresh tokens and blacklists the spent one,
/// five of them would fail and sign the user out. So the first 401 starts a
/// refresh and every other 401 waits on the same future.
///
/// Refresh is attempted once per failure. If it fails, the session is over --
/// note that a password change also invalidates refresh tokens server-side
/// (CHECK_REVOKE_TOKEN), so "refresh failed" is a real state, not a blip, and
/// must land on the sign-in screen rather than retry forever.
library;

import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_store.dart';
import 'api_failure.dart';

/// Called when the session cannot be recovered. The app routes to sign-in.
typedef OnSessionLost = void Function();

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.refreshClient,
    required this.onSessionLost,
  });

  final TokenStore tokenStore;

  /// A bare Dio with no interceptors. Refreshing through the main client
  /// would recurse: a 401 from the refresh call would trigger a refresh.
  final Dio refreshClient;

  final OnSessionLost onSessionLost;

  Future<StoredSession?>? _inFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] == true) return handler.next(options);

    final session = await tokenStore.read();
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    final shouldTry =
        status == 401 &&
        options.extra[skipAuthKey] != true &&
        options.extra[_retriedKey] != true;

    if (!shouldTry) return handler.next(err);

    // QueuedInterceptor serialises errors, so by the time the second of a
    // batch of 401s is handled the first has usually already refreshed. In
    // that case the stored token is no longer the one this request sent, and
    // there is nothing to refresh -- just replay with the current token.
    // Without this check a batch of N expiring requests performs N refreshes,
    // and because the server rotates and blacklists, all but the first fail.
    final current = await tokenStore.read();
    final sentToken = options.headers['Authorization'];
    if (current != null && 'Bearer ${current.accessToken}' != sentToken) {
      return _replay(options, current, handler);
    }

    final session = await _refresh();
    if (session == null) {
      onSessionLost();
      return handler.reject(
        DioException(
          requestOptions: options,
          response: err.response,
          error: const ApiUnauthenticated(),
        ),
      );
    }

    return _replay(options, session, handler);
  }

  /// Re-sends a request with a known-good token, once.
  Future<void> _replay(
    RequestOptions options,
    StoredSession session,
    ErrorInterceptorHandler handler,
  ) async {
    // Marked so that a second 401 cannot loop.
    options.extra[_retriedKey] = true;
    options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    try {
      final response = await refreshClient.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// One refresh at a time. Concurrent callers await the same future.
  Future<StoredSession?> _refresh() {
    return _inFlight ??= _performRefresh().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<StoredSession?> _performRefresh() async {
    final current = await tokenStore.read();
    if (current == null || current.refreshToken.isEmpty) return null;

    try {
      final response = await refreshClient.post<dynamic>(
        '${current.host}/api/v1/auth/refresh/',
        data: {'refresh': current.refreshToken},
      );

      final body = response.data;
      if (body is! Map) return null;
      final access = body['access'];
      if (access is! String || access.isEmpty) return null;

      // Rotation is on server-side, so the response carries a replacement
      // refresh token and the one just spent is now blacklisted. Keeping the
      // old one would sign the user out at the next refresh.
      final rotated = body['refresh'];
      final updated = current.copyWith(
        accessToken: access,
        refreshToken: rotated is String && rotated.isNotEmpty
            ? rotated
            : current.refreshToken,
      );
      await tokenStore.write(updated);
      return updated;
    } on DioException {
      await tokenStore.clear();
      return null;
    }
  }

  /// Marks a request that must not carry a token (sign-in, health probe).
  static const skipAuthKey = 'horilla.skipAuth';
  static const _retriedKey = 'horilla.retried';
}
