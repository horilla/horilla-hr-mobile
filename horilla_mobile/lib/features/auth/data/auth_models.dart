/// Models for the auth exchange.
///
/// Hand-written fromJson rather than generated. The API's null shape is
/// inconsistent enough -- empty strings where you expect null, relative media
/// URLs, optional nested objects -- that these want to be tolerant parsers,
/// and tolerant parsing is exactly what a code generator fights.
library;

/// What the server says it is. Returned unauthenticated by `/health/`.
class ServerInfo {
  const ServerInfo({required this.version});

  final String version;

  static ServerInfo? fromJson(Map<String, dynamic> json) {
    // `status` identifies this as a Horilla health endpoint; `version` was
    // added for exactly this probe. Without both, assume it is some other
    // server that happens to answer on /health/.
    if (json['status'] != 'ok') return null;
    final version = json['version'];
    if (version is! String || version.isEmpty) return null;
    return ServerInfo(version: version);
  }
}

/// Role, permissions and installed features, resolved server-side.
///
/// The app never derives these itself -- a client that decides its own
/// permissions only fools itself and collects 403s.
class Capabilities {
  const Capabilities({
    required this.role,
    required this.permissions,
    required this.features,
  });

  final String role;
  final Map<String, bool> permissions;
  final Map<String, bool> features;

  static const empty = Capabilities(
    role: 'employee',
    permissions: {},
    features: {},
  );

  bool can(String permission) => permissions[permission] ?? false;
  bool has(String feature) => features[feature] ?? false;

  bool get isManager => role == 'manager' || role == 'hrexec';
  bool get isHrExec => role == 'hrexec';

  static Capabilities fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return Capabilities(
      role: json['role'] is String ? json['role'] as String : 'employee',
      permissions: _bools(json['permissions']),
      features: _bools(json['features']),
    );
  }

  static Map<String, bool> _bools(Object? value) {
    if (value is! Map) return const {};
    final result = <String, bool>{};
    value.forEach((key, v) {
      if (key is String && v is bool) result[key] = v;
    });
    return result;
  }
}

class SignedInUser {
  const SignedInUser({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  final int id;
  final String fullName;
  final String? avatarUrl;

  static SignedInUser fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SignedInUser(id: 0, fullName: '');
    final id = json['id'];
    final name = json['full_name'];
    final avatar = json['employee_profile'];
    return SignedInUser(
      id: id is int ? id : 0,
      fullName: name is String ? name : '',
      // Empty string rather than null is common here; treat both as absent.
      avatarUrl: avatar is String && avatar.isNotEmpty ? avatar : null,
    );
  }
}

class SignInResult {
  const SignInResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.capabilities,
    required this.geoFencingEnabled,
    required this.faceDetectionEnabled,
  });

  final String accessToken;
  final String refreshToken;
  final SignedInUser user;
  final Capabilities capabilities;
  final bool geoFencingEnabled;
  final bool faceDetectionEnabled;

  static SignInResult? fromJson(Map<String, dynamic> json) {
    final access = json['access'];
    if (access is! String || access.isEmpty) return null;
    final refresh = json['refresh'];

    return SignInResult(
      accessToken: access,
      // A server that predates the refresh endpoint returns no refresh token.
      // Parsing still succeeds; the version gate is what refuses those.
      refreshToken: refresh is String ? refresh : '',
      user: SignedInUser.fromJson(
        json['employee'] is Map<String, dynamic>
            ? json['employee'] as Map<String, dynamic>
            : null,
      ),
      capabilities: Capabilities.fromJson(
        json['capabilities'] is Map<String, dynamic>
            ? json['capabilities'] as Map<String, dynamic>
            : null,
      ),
      geoFencingEnabled: json['geo_fencing'] == true,
      faceDetectionEnabled: json['face_detection'] == true,
    );
  }
}
