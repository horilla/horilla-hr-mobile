/// The error mapper decides "what went wrong" for the whole app. The cases
/// worth pinning are the ones where the backend overloads a status code and
/// the UI has to tell two very different situations apart.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/api/error_interceptor.dart';

final _interceptor = ErrorInterceptor();

ApiFailure mapError({
  int? status,
  Object? body,
  Map<String, List<String>>? headers,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(path: '/x');
  return _interceptor.mapFailure(
    DioException(
      requestOptions: options,
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: options,
              statusCode: status,
              data: body,
              headers: Headers.fromMap(headers ?? {}),
            ),
    ),
  );
}

void main() {
  group('status mapping', () {
    test('401 is unauthenticated', () {
      expect(mapError(status: 401), isA<ApiUnauthenticated>());
    });

    test('404 is not found', () {
      expect(mapError(status: 404), isA<ApiNotFound>());
    });

    test('500 is a server failure', () {
      expect(mapError(status: 500), isA<ApiServer>());
    });
  });

  group('403 covers two situations', () {
    test('a plain 403 is forbidden', () {
      expect(
        mapError(status: 403, body: {'error': 'No permission'}),
        isA<ApiForbidden>(),
      );
    });

    test('an unassigned company is its own case', () {
      // The user cannot fix this one; it must not read as a password problem.
      expect(
        mapError(
          status: 403,
          body: {'detail': 'This account is not assigned to a company.'},
        ),
        isA<ApiNoCompany>(),
      );
    });
  });

  group('429 covers two situations', () {
    test('throttling carries Retry-After when the server sends it', () {
      final failure = mapError(
        status: 429,
        body: {'detail': 'Request was throttled.'},
        headers: {
          'retry-after': ['30'],
        },
      );
      expect(failure, isA<ApiThrottled>());
      expect((failure as ApiThrottled).retryAfter, const Duration(seconds: 30));
    });

    test('an axes lockout is distinguished from throttling', () {
      expect(
        mapError(
          status: 429,
          body: {'error': 'Too many failed login attempts. Try again later.'},
        ),
        isA<ApiLockedOut>(),
        reason:
            '"slow down" and "your account is locked" need different messages',
      );
    });
  });

  group('400 bodies', () {
    test('DRF field errors are preserved per field', () {
      final failure = mapError(
        status: 400,
        body: {
          'reason': ['This field is required.'],
          'start_date': ['Enter a valid date.'],
        },
      );
      expect(failure, isA<ApiValidation>());
      final validation = failure as ApiValidation;
      expect(validation.forField('reason'), 'This field is required.');
      expect(validation.forField('start_date'), 'Enter a valid date.');
      expect(validation.forField('absent'), isNull);
    });

    test('a validation body under another status can still be read', () {
      // Attendance corrections answer form errors with 404.
      final failure = ErrorInterceptor().fromBadRequest({
        'minimum_hour': ['This field is required.'],
      });
      expect(failure, isA<ApiValidation>());
      expect(failure.message, 'Minimum hour: This field is required.');
    });

    test("the headline is the server's first complaint, not a generic one", () {
      // Forms show one or two fields inline. A rejection about anything else
      // -- an overlapping request, a date rule -- must still say what it is.
      expect(
        mapError(
          status: 400,
          body: {
            'requested_till': ['Requested till field is required.'],
          },
        ).message,
        'Requested till: Requested till field is required.',
      );
      expect(
        mapError(
          status: 400,
          body: {
            'non_field_errors': ['A shift request already exists.'],
          },
        ).message,
        'A shift request already exists.',
      );
      expect(
        mapError(
          status: 400,
          body: {
            'employee_id': ['Invalid pk "9" - object does not exist.'],
          },
        ).message,
        'Employee: Invalid pk "9" - object does not exist.',
      );
    });

    test('a single message is not forced into a field map', () {
      // e.g. clock-in answering {"message": "Already clocked-in"}
      final failure = mapError(
        status: 400,
        body: {'error': 'Already clocked-in'},
      );
      expect(failure, isA<ApiUnknown>());
      expect(failure.message, 'Already clocked-in');
    });
  });

  group('transport failures', () {
    test('connection error is a network failure', () {
      expect(
        mapError(type: DioExceptionType.connectionError),
        isA<ApiNetwork>(),
      );
    });

    test('timeouts are their own case', () {
      expect(
        mapError(type: DioExceptionType.receiveTimeout),
        isA<ApiTimeout>(),
      );
    });

    test('a bad certificate reports TLS, not a network drop', () {
      expect(mapError(type: DioExceptionType.badCertificate), isA<ApiTls>());
    });
  });
}
