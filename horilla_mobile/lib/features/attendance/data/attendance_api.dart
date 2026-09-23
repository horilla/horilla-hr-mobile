import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  Future<AttendanceOverview> fetchOverview({
    required int employeeId,
    required DateTime month,
    int pageSize = 100,
  }) async {
    final monthName = DateFormat('MMMM', 'en').format(month);
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final day = DateFormat('yyyy-MM-dd');

    try {
      final responses = await Future.wait([
        // Scoped to this person and this month. Unscoped, the endpoint
        // returns every employee's rows the caller may see -- 948 for an
        // admin on the demo -- and "the first row" was somebody's September
        // only by ordering luck.
        _dio.get<dynamic>(
          '/attendance/attendance-hour-account/',
          queryParameters: {
            'employee_id': employeeId,
            'month': monthName,
            'year': '${month.year}',
          },
        ),
        _dio.get<dynamic>(
          '/attendance/my-attendance/',
          // The list ignores date filters, so fetch a generous page and
          // narrow client-side; 100 is the server's page-size cap.
          queryParameters: {'page_size': pageSize},
        ),
      ]);

      final (late, early) = await _lateAndEarly(
        employeeId,
        day.format(first),
        day.format(last),
      );

      return AttendanceOverview(
        hourAccount: _hourAccountFor(
          responses[0].data,
          employeeId: employeeId,
          month: monthName,
          year: month.year,
        ),
        days: responses[1].data is Map<String, dynamic>
            ? Paged.fromJson<AttendanceDay>(
                responses[1].data as Map<String, dynamic>,
                AttendanceDay.fromJson,
              )
            : const Paged<AttendanceDay>(results: [], count: 0),
        month: first,
        lateIns: late,
        earlyOuts: early,
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

  /// Late check-ins and early check-outs for the month.
  ///
  /// Allowed to fail on its own. The counters are secondary to the hour
  /// account, and this endpoint is the one most likely to change its access
  /// rules; a failure here shows "—", not an error over the whole screen.
  Future<(int?, int?)> _lateAndEarly(
    int employeeId,
    String from,
    String to,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '/attendance/late-come-early-out-view/',
        queryParameters: {
          'employee_id': employeeId,
          'attendance_date__gte': from,
          'attendance_date__lte': to,
        },
      );
      final body = response.data;
      if (body is! List) return (null, null);
      var late = 0, early = 0;
      for (final row in body) {
        if (row is! Map) continue;
        // Filter again locally: if the server ever ignores the parameter,
        // this still counts only this person.
        final who = row['employee_id'];
        if (who is int && who != employeeId) continue;
        switch (row['type']) {
          case 'late_come':
            late++;
          case 'early_out':
            early++;
        }
      }
      return (late, early);
    } on DioException {
      return (null, null);
    }
  }

  /// The row for this person and month -- matched, not assumed to be first.
  HourAccount _hourAccountFor(
    Object? body, {
    required int employeeId,
    required String month,
    required int year,
  }) {
    if (body is! Map<String, dynamic>) return HourAccount.empty;
    final results = body['results'];
    if (results is! List) return HourAccount.empty;
    for (final row in results) {
      if (row is! Map<String, dynamic>) continue;
      final who = row['employee_id'];
      final m = row['month'];
      final y = row['year'];
      if ((who is int && who != employeeId) ||
          (m is String && m.toLowerCase() != month.toLowerCase()) ||
          (y != null && '$y' != '$year')) {
        continue;
      }
      return HourAccount.fromJson(row);
    }
    return HourAccount.empty;
  }
}

final attendanceApiProvider = Provider<AttendanceApi>(
  (ref) => AttendanceApi(ref.watch(apiClientProvider).dio),
);

/// The month the attendance screen is showing; the first of that month.
class AttendanceMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void select(DateTime month) => state = DateTime(month.year, month.month);
}

final attendanceMonthProvider = NotifierProvider<AttendanceMonth, DateTime>(
  AttendanceMonth.new,
);

final attendanceOverviewProvider = FutureProvider<AttendanceOverview>((ref) {
  final employeeId = ref.watch(sessionProvider)?.user.id ?? 0;
  return ref
      .watch(attendanceApiProvider)
      .fetchOverview(
        employeeId: employeeId,
        month: ref.watch(attendanceMonthProvider),
      );
});
