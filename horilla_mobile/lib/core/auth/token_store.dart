/// Where the session lives.
///
/// Tokens go in the Keychain / Keystore, never in shared_preferences -- the
/// previous version of this app kept its JWT in plaintext on disk.
///
/// The host is stored *with* the tokens as one record, and that is the point:
/// this app lets the user type their own server address, so a token minted by
/// one Horilla install must never be sent to another. Storing them together
/// makes that a single atomic fact rather than two values that can drift.
library;

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A session: the tokens, and the host they are valid for.
class StoredSession {
  const StoredSession({
    required this.host,
    required this.accessToken,
    required this.refreshToken,
  });

  final String host;
  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'host': host,
        'access': accessToken,
        'refresh': refreshToken,
      };

  static StoredSession? fromJson(Map<String, dynamic> json) {
    final host = json['host'];
    final access = json['access'];
    final refresh = json['refresh'];
    if (host is! String || access is! String || refresh is! String) return null;
    if (host.isEmpty || access.isEmpty) return null;
    return StoredSession(
      host: host,
      accessToken: access,
      refreshToken: refresh,
    );
  }

  StoredSession copyWith({String? accessToken, String? refreshToken}) =>
      StoredSession(
        host: host,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
      );
}

class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'horilla.session';

  final FlutterSecureStorage _storage;

  /// Returns null when there is no session, and *also* when the store cannot
  /// be read.
  ///
  /// Android's EncryptedSharedPreferences has a well-known failure mode where
  /// the entry becomes undecryptable after a backup restore or a keystore
  /// reset. Treating that as "signed out" costs the user one sign-in;
  /// letting it throw would crash the app on launch with no way back.
  Future<StoredSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return StoredSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(StoredSession session) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    } catch (_) {
      // Same reasoning as read(): a store that will not accept a write leaves
      // the user signed out next launch, which is recoverable. Crashing here
      // would lose a sign-in that otherwise succeeded.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing useful to do; the session is already being discarded.
    }
  }
}
