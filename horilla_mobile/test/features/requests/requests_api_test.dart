/// Work-type create's phantom failure.
///
/// The server saves the request, then fails to notify the reporting manager
/// and answers 400 with an empty body. Reproduced live on
/// hr.demo.horilla.com: the "failed" create left a real request behind. The
/// app must not report that as a failure -- the next tap would duplicate it.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/api/error_interceptor.dart';
import 'package:horilla_mobile/features/requests/data/request_models.dart';
import 'package:horilla_mobile/features/requests/data/requests_api.dart';

/// Answers each (method, path) with a canned status and JSON body.
class _Stub implements HttpClientAdapter {
  _Stub(this.routes);

  final Map<String, (int, Object?)> routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) =
        routes['${options.method} ${options.path}'] ?? (404, {});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

RequestsApi api(Map<String, (int, Object?)> routes) {
  final dio = Dio(BaseOptions(baseUrl: 'https://hr.example.test/api/v1'))
    ..httpClientAdapter = _Stub(routes)
    ..interceptors.add(ErrorInterceptor());
  return RequestsApi(dio);
}

final draft = ShiftOrWorkTypeRequest(
  forShift: false,
  requestedId: 4,
  previousId: null,
  requestedDate: DateTime(2027, 3, 1),
  requestedTill: DateTime(2027, 3, 5),
  reason: 'Trial remote week',
);

Map<String, dynamic> saved({int workType = 4, bool approved = false}) => {
  'id': 12,
  'employee_id': 7,
  'work_type_id': workType,
  'requested_date': '2027-03-01',
  'approved': approved,
  'canceled': false,
};

void main() {
  test('a 400 after the request was saved counts as submitted', () async {
    final requests = api({
      'POST /base/worktype-requests/': (400, {}),
      'GET /base/worktype-requests/': (
        200,
        {
          'count': 1,
          'results': [saved()],
        },
      ),
    });

    await requests.submitShiftOrWorkType(draft, 7);
  });

  test('a 400 with nothing saved is still a failure', () async {
    final requests = api({
      'POST /base/worktype-requests/': (400, {}),
      'GET /base/worktype-requests/': (
        200,
        {
          'count': 1,
          'results': [saved(workType: 9)],
        },
      ),
    });

    expect(
      () => requests.submitShiftOrWorkType(draft, 7),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('a real validation error is never second-guessed', () async {
    final requests = api({
      'POST /base/worktype-requests/': (
        400,
        {
          'requested_till': ['Requested till field is required.'],
        },
      ),
      // Even if a matching row happens to exist, a field error means the
      // server refused this one.
      'GET /base/worktype-requests/': (
        200,
        {
          'count': 1,
          'results': [saved()],
        },
      ),
    });

    expect(
      () => requests.submitShiftOrWorkType(draft, 7),
      throwsA(isA<ApiValidation>()),
    );
  });
}
