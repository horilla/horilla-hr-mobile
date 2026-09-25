/// Converts everything Dio can throw into an [ApiFailure].
///
/// Runs last, so nothing above it in the app ever handles a DioException.
library;

import 'package:dio/dio.dart';

import 'api_failure.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapFailure(err),
      ),
    );
  }

  /// Public so it can be tested as the pure function it is, rather than
  /// through a Dio handler that cannot be observed.
  ApiFailure mapFailure(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiTimeout();
      case DioExceptionType.badCertificate:
        return const ApiTls();
      case DioExceptionType.connectionError:
        return const ApiNetwork();
      case DioExceptionType.cancel:
        return const ApiUnknown('Request cancelled.');
      case DioExceptionType.unknown:
        if (err.error is ApiFailure) return err.error as ApiFailure;
        return const ApiNetwork();
      case DioExceptionType.badResponse:
        break;
    }

    final response = err.response;
    final status = response?.statusCode;
    final body = response?.data;

    switch (status) {
      case 400:
        return _validationOrUnknown(body);
      case 401:
        return const ApiUnauthenticated();
      case 403:
        // The tenant-scoped auth class refuses accounts with no company. The
        // user cannot fix that themselves, so it must not look like a
        // password problem.
        return _mentionsCompany(body)
            ? const ApiNoCompany()
            : ApiForbidden(_detail(body) ?? "You don't have access to that.");
      case 404:
        return const ApiNotFound();
      case 429:
        // Two different things share this status: the request throttle, and
        // django-axes locking the account after five failed passwords.
        if (_mentionsLockout(body)) return const ApiLockedOut();
        return ApiThrottled(retryAfter: _retryAfter(response));
      case 503:
        return ApiServer(_detail(body) ?? 'The server is unavailable.');
    }

    if (status != null && status >= 500) return const ApiServer();
    return ApiUnknown(_detail(body) ?? 'Something went wrong.');
  }

  /// DRF field errors arrive as {"field": ["problem", ...]}. Anything that
  /// does not fit that shape is not forced into it.
  ApiFailure _validationOrUnknown(Object? body) {
    if (body is! Map) return ApiUnknown(_detail(body) ?? 'Invalid request.');

    final fields = <String, List<String>>{};
    body.forEach((key, value) {
      if (key is! String) return;
      // These are headline keys, not field names -- folding them into the
      // field map would put "error" on a form input that does not exist.
      if (_headlineKeys.contains(key)) return;
      if (value is List) {
        final messages = value.whereType<Object>().map((v) => '$v').toList();
        if (messages.isNotEmpty) fields[key] = messages;
      } else if (value is String) {
        fields[key] = [value];
      }
    });

    if (fields.isEmpty) return ApiUnknown(_detail(body) ?? 'Invalid request.');

    // Endpoints here report a single problem under `error` or `message` as
    // often as they report per-field errors; surface that as the headline.
    // Otherwise the headline is the server's first complaint: forms show
    // only a field or two inline, and a generic "check the form" over a
    // rejection like "a shift request already exists" leaves the person
    // guessing at a form that has nothing wrong with it.
    return ApiValidation(fields, _detail(body) ?? _firstComplaint(fields));
  }

  /// "Requested till: This field is required." -- or the bare message for
  /// errors that belong to no field.
  static String _firstComplaint(Map<String, List<String>> fields) {
    final MapEntry(:key, :value) = fields.entries.first;
    final message = value.first.trim();
    final label = key.replaceAll(RegExp(r'_id$'), '').replaceAll('_', ' ');
    if (label.isEmpty || key == 'non_field_errors' || key == '__all__') {
      return message;
    }
    return '${label[0].toUpperCase()}${label.substring(1)}: $message';
  }

  static const _headlineKeys = {'error', 'message', 'detail'};

  String? _detail(Object? body) {
    if (body is! Map) return null;
    for (final key in _headlineKeys) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  bool _mentionsCompany(Object? body) {
    final text = _detail(body)?.toLowerCase();
    return text != null && text.contains('company');
  }

  bool _mentionsLockout(Object? body) {
    final text = _detail(body)?.toLowerCase();
    if (text == null) return false;
    return text.contains('failed login') || text.contains('failed sign');
  }

  Duration? _retryAfter(Response<dynamic>? response) {
    final header = response?.headers.value('retry-after');
    final seconds = int.tryParse(header ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
