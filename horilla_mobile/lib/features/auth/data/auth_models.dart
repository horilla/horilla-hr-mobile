/// Models for the auth exchange.
///
/// Hand-written fromJson rather than generated. The API's null shape is
/// inconsistent enough -- empty strings where you expect null, relative media
/// URLs, optional nested objects -- that these want to be tolerant parsers,
/// and tolerant parsing is exactly what a code generator fights.
library;

/// What the server says it is. Returned unauthenticated by `/health/`.
class ServerInfo {
  const ServerInfo({required this.apiContract});

  /// The `/health/` API contract number, not a release string. See
  /// [kMinimumApiContract] for why the server does not report its version.
  final int apiContract;

  static ServerInfo? fromJson(Map<String, dynamic> json) {
    // `status` marks this as a health endpoint, `product` says which product,
    // and `api` is the contract to check against. Without all three, assume
    // some other server that happens to answer on /health/.
    if (json['status'] != 'ok' || json['product'] != 'horilla') return null;
    final contract = json['api'];
    if (contract is! int) return null;
    return ServerInfo(apiContract: contract);
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
    this.currencySymbol,
  });

  final String role;
  final Map<String, bool> permissions;
  final Map<String, bool> features;

  /// Configured per install (`PayrollSettings.currency_symbol`), so it has to
  /// come from the server. Null when this release does not send it -- money
  /// is then rendered without a symbol rather than in a guessed currency.
  final String? currencySymbol;

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
    final currency = json['currency_symbol'];
    return Capabilities(
      role: json['role'] is String ? json['role'] as String : 'employee',
      permissions: _bools(json['permissions']),
      features: _bools(json['features']),
      currencySymbol:
          currency is String && currency.isNotEmpty ? currency : null,
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
    // Login sends full_name / employee_profile. The home aggregate sends
    // name / avatar. Reading only the login keys left Home as "Welcome"
    // with a blank avatar while Me, which uses the login payload, was fine.
    String? text(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return SignedInUser(
      id: id is int ? id : 0,
      fullName: text('full_name') ?? text('name') ?? '',
      avatarUrl: text('employee_profile') ?? text('avatar'),
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

  /// Whether this server carries the mobile API this app is built against.
  ///
  /// Both are v2 additions. Without [refreshToken] a session dies after an
  /// hour with no way to renew it; without capabilities the role-adaptive
  /// navigation has nothing to read. Either one missing means the server is
  /// older than the app supports, and the app must say so instead of signing
  /// someone in to something that will break an hour later.
  bool get hasMobileApi =>
      refreshToken.isNotEmpty && capabilities.permissions.isNotEmpty;

  static SignInResult? fromJson(Map<String, dynamic> json) {
    final access = json['access'];
    if (access is! String || access.isEmpty) return null;
    final refresh = json['refresh'];

    return SignInResult(
      accessToken: access,
      // Empty when the server predates the refresh endpoint. Parsed rather
      // than rejected here so the caller can say *why* it is unusable --
      // "your server is too old" rather than "login failed".
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
