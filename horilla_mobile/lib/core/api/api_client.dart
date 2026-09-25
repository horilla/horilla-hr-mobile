/// Assembles the Dio stack.
///
/// Order matters: auth first so a 401 is resolved before anything else looks
/// at it, then retry, then the error mapper last so nothing above sees a
/// DioException.
library;

import 'package:dio/dio.dart';

import '../auth/token_store.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'retry_interceptor.dart';

/// Everything under /api/v1/. The unversioned /api/ alias is deprecated.
const String kApiPrefix = '/api/v1';

class ApiClient {
  ApiClient({
    required TokenStore tokenStore,
    required OnSessionLost onSessionLost,
    Dio? dio,
    Dio? refreshDio,
  }) : _dio = dio ?? Dio(),
       _refreshDio = refreshDio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers['Accept'] = 'application/json';

    _refreshDio.options
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers['Accept'] = 'application/json';

    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenStore: tokenStore,
        refreshClient: _refreshDio,
        onSessionLost: onSessionLost,
      ),
      RetryInterceptor(client: _refreshDio),
      ErrorInterceptor(),
    ]);
  }

  final Dio _dio;
  final Dio _refreshDio;

  Dio get dio => _dio;

  /// Points the client at a host. Called after sign-in, and on restore.
  void useHost(String host) {
    _dio.options.baseUrl = '$host$kApiPrefix';
  }
}
