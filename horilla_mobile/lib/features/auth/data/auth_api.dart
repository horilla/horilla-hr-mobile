import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/auth_interceptor.dart';
import 'auth_models.dart';

/// Lowest server version this app can talk to.
///
/// The mobile client depends on endpoints that do not exist in earlier
/// releases -- token refresh above all, without which a session dies after an
/// hour with no way to renew it. Probing for them individually is not
/// possible: DRF answers 404 both for "no such route" and "no such object",
/// so a probe cannot tell "not deployed" from "not found".
///
/// Raise this to the release that ships those endpoints once it is cut. It is
/// deliberately a single constant so that is a one-line change.
const String kMinimumServerVersion = '2.1.7';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Confirms a host is a Horilla server, and new enough, *before* any
  /// credentials are sent.
  ///
  /// The reason this runs first: without it a typo'd hostname comes back as
  /// "invalid credentials", which sends people off checking their password
  /// when the address is what is wrong.
  Future<ServerInfo> probe(String host) async {
    final Response<dynamic> response;
    try {
      response = await _client.dio.get<dynamic>(
        '$host/health/',
        options: Options(
          extra: {AuthInterceptor.skipAuthKey: true},
          // A wrong host often answers with something; treat any status as a
          // response to inspect rather than an exception to map.
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiNetwork();
    }

    final body = response.data;
    final info =
        body is Map<String, dynamic> ? ServerInfo.fromJson(body) : null;
    if (info == null) throw const ApiIncompatibleServer();

    if (!isAtLeast(info.version, kMinimumServerVersion)) {
      throw ApiIncompatibleServer(
        'This server runs Horilla ${info.version}. '
        'The app needs $kMinimumServerVersion or newer.',
      );
    }
    return info;
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
