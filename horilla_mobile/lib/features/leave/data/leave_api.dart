import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'leave_models.dart';

class LeaveApi {
  LeaveApi(this._dio);

  final Dio _dio;

  /// Balances, my requests and upcoming holidays.
  ///
  /// Three separate resources, so three requests, issued concurrently. There
  /// is no aggregate for these and inventing one would be premature -- unlike
  /// home, where eight fragments of a single view justified it.
  Future<LeaveOverview> fetchOverview() async {
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>('/leave/available-leave/'),
        _dio.get<dynamic>('/leave/user-request/'),
        _dio.get<dynamic>('/leave/holiday/'),
      ]);

      return LeaveOverview(
        balances: _list(responses[0].data, LeaveBalance.fromJson),
        requests: _list(responses[1].data, LeaveRequestSummary.fromJson),
        holidays: _upcoming(_list(responses[2].data, Holiday.fromJson)),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  Future<void> requestAllocation(
    LeaveAllocationRequest request,
    int employeeId,
  ) async {
    try {
      await _dio.post<dynamic>(
        '/leave/user-allocation-request/',
        data: request.toJson(employeeId),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// Books the leave. Returns the new request's id, for Undo; null if the
  /// server did not say.
  Future<int?> apply(LeaveApplication application, int employeeId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/leave/user-request/',
        data: application.toJson(employeeId),
      );
      final body = response.data;
      final id = body is Map ? body['id'] : null;
      return id is int ? id : null;
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// Withdraws a request that is still awaiting approval -- the toast's Undo.
  ///
  /// The server only allows this while the status is "requested", which is
  /// always true inside the few seconds Undo is on screen. The approver was
  /// already notified when the request was created, and that notification is
  /// not recalled.
  Future<void> withdraw(int requestId) async {
    try {
      await _dio.delete<dynamic>('/leave/user-request/$requestId/');
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  /// Handles both a paginated envelope and a bare list, because this API is
  /// not consistent about which it returns.
  List<T> _list<T>(Object? body, T? Function(Object?) item) {
    final raw = switch (body) {
      final Map<String, dynamic> map => map['results'],
      final List list => list,
      _ => null,
    };
    if (raw is! List) return const [];
    return raw.map(item).whereType<T>().toList();
  }

  /// Past holidays are history, not plans.
  List<Holiday> _upcoming(List<Holiday> holidays) {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day);
    return holidays.where((h) => !h.startDate.isBefore(cutoff)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}

final leaveApiProvider = Provider<LeaveApi>(
  (ref) => LeaveApi(ref.watch(apiClientProvider).dio),
);

final leaveOverviewProvider = FutureProvider<LeaveOverview>((ref) {
  return ref.watch(leaveApiProvider).fetchOverview();
});
