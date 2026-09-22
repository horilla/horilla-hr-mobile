/// The non-secret half of a session.
///
/// Tokens live in the Keychain; this holds what the app needs to draw its
/// first frame -- the person's own name, and the capability set the
/// navigation branches on. None of it is secret (it is the user's own name,
/// and a list of what they may do), so it belongs in shared_preferences
/// rather than taking up space in secure storage.
///
/// Keeping it means a returning user sees their app immediately instead of a
/// spinner, and can open it with no connection at all. Capabilities are
/// refreshed from the server afterwards, so a change of role corrects itself
/// without a sign-out.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_models.dart';

class StoredProfile {
  const StoredProfile({
    required this.user,
    required this.capabilities,
    required this.isCleartext,
    required this.geoFencingEnabled,
    required this.faceDetectionEnabled,
  });

  final SignedInUser user;
  final Capabilities capabilities;
  final bool isCleartext;
  final bool geoFencingEnabled;
  final bool faceDetectionEnabled;

  Map<String, dynamic> toJson() => {
        'user': {
          'id': user.id,
          'full_name': user.fullName,
          'employee_profile': user.avatarUrl,
        },
        'capabilities': {
          'role': capabilities.role,
          'permissions': capabilities.permissions,
          'features': capabilities.features,
          'currency_symbol': capabilities.currencySymbol,
        },
        'cleartext': isCleartext,
        'geo_fencing': geoFencingEnabled,
        'face_detection': faceDetectionEnabled,
      };

  static StoredProfile? fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) return null;
    return StoredProfile(
      user: SignedInUser.fromJson(user),
      capabilities: Capabilities.fromJson(
        json['capabilities'] is Map<String, dynamic>
            ? json['capabilities'] as Map<String, dynamic>
            : null,
      ),
      isCleartext: json['cleartext'] == true,
      geoFencingEnabled: json['geo_fencing'] == true,
      faceDetectionEnabled: json['face_detection'] == true,
    );
  }
}

class ProfileStore {
  ProfileStore({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'horilla.profile';

  final SharedPreferencesAsync _prefs;

  Future<StoredProfile?> read() async {
    try {
      final raw = await _prefs.getString(_key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return StoredProfile.fromJson(decoded);
    } catch (_) {
      // Corrupt or unreadable: treat as absent. The session is still valid
      // (the token is what proves that); the app just re-fetches instead of
      // restoring instantly.
      return null;
    }
  }

  Future<void> write(StoredProfile profile) async {
    try {
      await _prefs.setString(_key, jsonEncode(profile.toJson()));
    } catch (_) {
      // Losing this costs a slower first frame, nothing more.
    }
  }

  Future<void> clear() async {
    try {
      await _prefs.remove(_key);
    } catch (_) {}
  }
}
