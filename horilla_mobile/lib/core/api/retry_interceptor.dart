/// Retries only what is safe to retry.
///
/// GET only, and that restriction is the whole design. A retried clock-in is
/// a double punch; a retried approval is a double approval. The server allows
/// 600 requests a minute per user, so 429 should be rare in normal use and a
/// short backoff is enough when it happens.
library;

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.client,
    this.maxAttempts = 3,
    Random? random,
  }) : _random = random ?? Random();

  final Dio client;
  final int maxAttempts;
  final Random _random;

  static const _attemptKey = 'horilla.retryAttempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    if (options.method.toUpperCase() != 'GET') return handler.next(err);

    final attempt = (options.extra[_attemptKey] as int?) ?? 0;
    if (attempt >= maxAttempts - 1) return handler.next(err);

    final delay = _delayFor(err, attempt);
    if (delay == null) return handler.next(err);

    await Future<void>.delayed(delay);

    options.extra[_attemptKey] = attempt + 1;
    try {
      final response = await client.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Null means "do not retry this".
  Duration? _delayFor(DioException err, int attempt) {
    final status = err.response?.statusCode;

    if (status == 429) {
      final header = err.response?.headers.value('retry-after');
      final seconds = int.tryParse(header ?? '');
      if (seconds != null) return Duration(seconds: seconds);
      return _backoff(attempt);
    }

    // Transport-level trouble is worth one more go; a 4xx is not.
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return _backoff(attempt);
      default:
        if (status != null && status >= 500) return _backoff(attempt);
        return null;
    }
  }

  /// 500ms, 1s, ... with jitter, so a fleet of clients that all lost
  /// connectivity at once do not return in lockstep.
  Duration _backoff(int attempt) {
    final base = 500 * pow(2, attempt).toInt();
    return Duration(milliseconds: base + _random.nextInt(250));
  }
}
