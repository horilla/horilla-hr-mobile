/// Session state, and the providers that hang off it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_models.dart';
import '../api/api_client.dart';
import '../api/api_failure.dart';
import '../api/host.dart';
import 'token_store.dart';

/// Who is signed in, if anyone.
@immutable
class Session {
  const Session({
    required this.host,
    required this.user,
    required this.capabilities,
    required this.isCleartext,
    required this.geoFencingEnabled,
    required this.faceDetectionEnabled,
  });

  final String host;
  final SignedInUser user;
  final Capabilities capabilities;

  /// Surfaced in the UI so an unencrypted connection is never invisible.
  final bool isCleartext;

  final bool geoFencingEnabled;
  final bool faceDetectionEnabled;
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStore: ref.watch(tokenStoreProvider),
    onSessionLost: () => ref.read(sessionProvider.notifier).signOut(),
  );
});

final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final sessionProvider =
    NotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Signs in, and only then persists anything.
  ///
  /// Order matters: probe the host, then authenticate, then store. A failure
  /// at any step leaves nothing behind, so a half-finished sign-in cannot
  /// strand a token belonging to a server the user never reached.
  Future<void> signIn({
    required String rawHost,
    required String username,
    required String password,
  }) async {
    final normalised = normaliseHost(rawHost);
    if (!normalised.isValid) {
      throw ApiIncompatibleServer(normalised.error!);
    }
    final host = normalised.host;

    final api = ref.read(authApiProvider);
    await api.probe(host);

    final result = await api.signIn(
      host: host,
      username: username,
      password: password,
    );

    // The pre-flight catches a server that reports an old version, but one
    // that reports no version at all still reaches here. Credentials were
    // correct; the server simply cannot support the app. Nothing is stored,
    // so this leaves no half-session behind.
    if (!result.hasMobileApi) {
      throw const ApiIncompatibleServer(
        'Signed in, but this Horilla server is missing the mobile API. '
        'It needs updating before the app can use it.',
      );
    }

    await ref.read(tokenStoreProvider).write(
          StoredSession(
            host: host,
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
          ),
        );
    ref.read(apiClientProvider).useHost(host);

    state = Session(
      host: host,
      user: result.user,
      capabilities: result.capabilities,
      isCleartext: normalised.isCleartext,
      geoFencingEnabled: result.geoFencingEnabled,
      faceDetectionEnabled: result.faceDetectionEnabled,
    );
  }

  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = null;
  }
}
