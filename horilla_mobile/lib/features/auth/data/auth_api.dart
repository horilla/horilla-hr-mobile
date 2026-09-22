import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/auth_interceptor.dart';
import 'auth_models.dart';

/// This app targets Horilla **v2** and does not support v1.
///
/// The boundary is not a preference, it is structural. v1 (1.3 - 1.6.1)
/// mounts its API at `/api/` only and ships an auth module with nothing but
/// `login/` -- no refresh, so a session would die after an hour with no way
/// to renew it, and no capabilities, so the role-adaptive navigation this
/// design is built around has nothing to read. Supporting it would mean a
/// second app, not a compatibility shim.
///
/// v1 installs upgrade via the v1-to-v2 migration tool; that is the path,
/// and the error this throws says so rather than leaving someone guessing.
const String kMinimumServerVersion = '2.0.0';

/// Route that exists on v2 and not on v1, used to tell them apart when the
/// server is too old to report its own version.
///
/// This is a route-existence check, not feature detection: a registered route
/// answering the wrong method returns 405, an unregistered one returns 404.
/// That distinction is reliable in a way that probing for a *feature* is not.
const String _versionedApiProbePath = '/api/v1/auth/login/';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Confirms a host is a Horilla v2 server *before* any credentials are sent.
  ///
  /// The reason this runs first: without it a typo'd hostname comes back as
  /// "invalid credentials", which sends people off checking a password when
  /// the address is what is wrong.
  ///
  /// Three outcomes are told apart, because the thing to do next differs:
  /// not a Horilla server at all, a Horilla v1 that needs migrating, and a
  /// v2 too old to carry the mobile API.
  Future<ServerInfo> probe(String host) async {
    final body = await _get(host, '/health/');

    // Every Horilla release answers /health/ with this. Its absence means we
    // are not talking to Horilla.
    if (body is! Map || body['status'] != 'ok') {
      throw const ApiIncompatibleServer();
    }

    final version = body['version'];
    if (version is String && version.isNotEmpty) {
      if (!isAtLeast(version, kMinimumServerVersion)) {
        throw ApiIncompatibleServer(
          'This server runs Horilla $version. The app needs Horilla '
          '$kMinimumServerVersion or newer.',
        );
      }
      return ServerInfo(version: version);
    }

    // No version field: the server predates the release that added it. Work
    // out which side of the v1/v2 line it sits on, because "migrate to v2"
    // and "update your v2" are very different jobs for whoever runs it.
    final hasVersionedApi = await _hasVersionedApi(host);
    throw ApiIncompatibleServer(
      hasVersionedApi
          ? 'This server runs an older Horilla 2. Update it to a release that '
              'includes the mobile API.'
          : 'This server runs Horilla 1, which the app does not support. '
              'It needs migrating to Horilla 2.',
    );
  }

  /// True when `/api/v1/` is mounted, which is v2 and later.
  Future<bool> _hasVersionedApi(String host) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '$host$_versionedApiProbePath',
        options: Options(
          extra: {AuthInterceptor.skipAuthKey: true},
          validateStatus: (_) => true,
        ),
      );
      // 404 means the route is not registered at all. Anything else -- 405 for
      // the wrong method, 401, even 200 -- means it is.
      return response.statusCode != 404;
    } on DioException {
      return false;
    }
  }

  Future<Object?> _get(String host, String path) async {
    try {
      final response = await _client.dio.get<dynamic>(
        '$host$path',
        options: Options(
          extra: {AuthInterceptor.skipAuthKey: true},
          // A wrong host often answers with something; inspect it rather than
          // letting the status alone raise.
          validateStatus: (_) => true,
        ),
      );
      return response.data;
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiNetwork();
    }
  }

  Future<SignInResult> signIn({
    required String host,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '$host$kApiPrefix/auth/login/',
        data: {'username': username, 'password': password},
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      );

      final body = response.data;
      final result =
          body is Map<String, dynamic> ? SignInResult.fromJson(body) : null;
      if (result == null) throw const ApiIncompatibleServer();
      return result;
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

/// Dotted-version comparison, tolerant of suffixes like `2.2.0-rc1`.
bool isAtLeast(String version, String minimum) {
  final actual = _parts(version);
  final required = _parts(minimum);
  for (var i = 0; i < required.length; i++) {
    final a = i < actual.length ? actual[i] : 0;
    final b = required[i];
    if (a > b) return true;
    if (a < b) return false;
  }
  return true;
}

List<int> _parts(String version) => version
    .split('.')
    .map((part) => int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '') ?? 0)
    .toList();
