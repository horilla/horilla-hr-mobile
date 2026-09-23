import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'attendance_models.dart';
import 'correction_models.dart';

class AttendanceApi {
  AttendanceApi(this._dio);

  final Dio _dio;

  /// Hour account and the recent activity log, fetched together.
  ///
  /// Two requests rather than one: unlike the home screen these are separate
  /// resources with different lifetimes, and there is no aggregate for them.
  /// They are issued concurrently, so the screen waits for one round trip's
  /// worth of latency rather than two.
  Future<AttendanceOverview> fetchOverview({int pageSize = 30}) async {
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>('/attendance/attendance-hour-account/'),
        _dio.get<dynamic>(
          '/attendance/my-attendance/',
          // Honoured since the server started reading page_size; on an older
          // release it is ignored and the page is simply shorter.
          queryParameters: {'page_size': pageSize},
        ),
      ]);

      return AttendanceOverview(
        hourAccount: _firstHourAccount(responses[0].data),
        days: responses[1].data is Map<String, dynamic>
            ? Paged.fromJson<AttendanceDay>(
                responses[1].data as Map<String, dynamic>,
                AttendanceDay.fromJson,
              )
            : const Paged<AttendanceDay>(results: [], count: 0),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// Fetches one day in full, so a correction form can carry back the fields
  /// the server's form requires but the list payload does not include.
  Future<Map<String, dynamic>> fetchDay(int attendanceId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/attendance/my-attendance-detailed/$attendanceId/',
      );
      final body = response.data;
      return body is Map<String, dynamic> ? body : const {};
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// Submits a correction for an existing attendance day.
  ///
  /// This endpoint answers oddly and the mapping has to account for it: a
  /// *validation* failure comes back as 404, not 400 (see
  /// AttendanceRequestView.post). Left unhandled, a rejected correction would
  /// tell the person "that is no longer available", sending them to look for
  /// a missing record instead of at the field they got wrong.
  Future<void> requestCorrection(AttendanceCorrection correction) async {
    try {
      await _dio.put<dynamic>(
        '/attendance/attendance-request/${correction.attendanceId}',
        data: correction.toJson(),
      );
    } on DioException catch (e) {
      final failure = e.error;
      if (failure is ApiNotFound) {
        throw const ApiValidation(
          {},
          'The server rejected this correction. Check the times and try '
          'again.',
        );
      }
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// The endpoint returns a paginated list; the current month is the first row.
  HourAccount _firstHourAccount(Object? body) {
    if (body is! Map<String, dynamic>) return HourAccount.empty;
    final results = body['results'];
    if (results is! List || results.isEmpty) return HourAccount.empty;
    final first = results.first;
    return first is Map<String, dynamic>
        ? HourAccount.fromJson(first)
        : HourAccount.empty;
  }
}

final attendanceApiProvider = Provider<AttendanceApi>(
  (ref) => AttendanceApi(ref.watch(apiClientProvider).dio),
);

final attendanceOverviewProvider = FutureProvider<AttendanceOverview>((ref) {
  return ref.watch(attendanceApiProvider).fetchOverview();
});
