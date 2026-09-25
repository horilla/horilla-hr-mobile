/// Assembling "my team today" from four endpoints, because no single one
/// answers it.
///
/// * Who reports to me: work-information rows, filtered here by
///   `reporting_manager_id`. The server scopes the list (everything for an
///   admin, self and reports for a manager), so an admin sees their own
///   direct reports -- not the whole company -- once filtered.
/// * Their names: the directory list, since work-information carries none.
/// * Who is in: today's attendance rows.
/// * Who is off, and when: approved leave overlapping this week
///   (`overall_leave=week`, Monday to Sunday server-side).
///
/// ponytail: four round trips on every open. A `mobile/team/` aggregate like
/// `mobile/home/` would make it one; worth it if this screen feels slow.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'team_models.dart';

class TeamApi {
  TeamApi(this._dio);

  final Dio _dio;

  static const _pageSize = 100;
  static const _maxPages = 10;

  Future<TeamToday> fetchToday({required int selfId, DateTime? now}) async {
    final today = now ?? DateTime.now();

    final reports = <int, String?>{};
    for (final row in await _rows('/employee/employee-work-information/')) {
      if (row is! Map<String, dynamic>) continue;
      final id = row['employee_id'];
      if (row['reporting_manager_id'] == selfId && id is int && id != selfId) {
        final position = row['job_position_name'];
        reports[id] = position is String && position.isNotEmpty
            ? position
            : null;
      }
    }
    if (reports.isEmpty) return TeamToday.empty;

    final day = DateFormat('yyyy-MM-dd').format(today);
    final results = await Future.wait([
      _names(reports.keys.toSet()),
      _rows('/attendance/attendance/', {'date_attendance': day}),
      _rows('/leave/request/', {'overall_leave': 'week'}),
    ]);
    final names = results[0] as Map<int, String>;
    final attendance = results[1] as List<Object?>;
    final leaveRows = results[2] as List<Object?>;

    final clockIns = <int, String>{};
    for (final row in attendance) {
      if (row is! Map<String, dynamic>) continue;
      final id = row['employee_id'];
      final clockIn = row['attendance_clock_in'];
      if (id is int && clockIn is String && clockIn.length >= 5) {
        clockIns[id] = clockIn.substring(0, 5);
        names.putIfAbsent(id, () => _flatName(row));
      }
    }

    final leaves = <TeamLeave>[];
    for (final row in leaveRows) {
      if (row is! Map<String, dynamic> || row['status'] != 'approved') {
        continue;
      }
      final employee = row['employee_id'];
      final start = DateTime.tryParse('${row['start_date']}');
      final end = DateTime.tryParse('${row['end_date']}') ?? start;
      if (employee is! Map || employee['id'] is! int || start == null) {
        continue;
      }
      final id = employee['id'] as int;
      final name = '${employee['full_name'] ?? ''}'.trim();
      final type = row['leave_type_id'];
      leaves.add(
        TeamLeave(
          employeeId: id,
          name: name.isEmpty ? (names[id] ?? 'Employee') : name,
          start: start,
          end: end!,
          type: type is Map && type['name'] is String
              ? type['name'] as String
              : null,
        ),
      );
      if (name.isNotEmpty) names.putIfAbsent(id, () => name);
    }

    return TeamToday.build(
      reports: reports,
      names: names,
      clockIns: clockIns,
      leaves: leaves,
      today: today,
    );
  }

  /// Names for [ids], from the directory. Stops paging once all are found.
  Future<Map<int, String>> _names(Set<int> ids) async {
    final names = <int, String>{};
    for (var page = 1; page <= _maxPages; page++) {
      final body = await _get('/employee/list/employees/', {
        'page_size': _pageSize,
        'page': page,
      });
      for (final row in _results(body)) {
        if (row is! Map<String, dynamic>) continue;
        final id = row['id'];
        if (id is int && ids.contains(id)) names[id] = _flatName(row);
      }
      if (names.length == ids.length || !_hasNext(body)) break;
    }
    return names;
  }

  Future<List<Object?>> _rows(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final rows = <Object?>[];
    for (var page = 1; page <= _maxPages; page++) {
      final body = await _get(path, {
        ...?query,
        'page_size': _pageSize,
        'page': page,
      });
      rows.addAll(_results(body));
      if (!_hasNext(body)) break;
    }
    return rows;
  }

  Future<Object?> _get(String path, Map<String, dynamic> query) async {
    try {
      return (await _dio.get<dynamic>(path, queryParameters: query)).data;
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  static List<Object?> _results(Object? body) => switch (body) {
    {'results': final List list} => list,
    final List list => list,
    _ => const [],
  };

  static bool _hasNext(Object? body) =>
      body is Map<String, dynamic> && body['next'] != null;

  static String _flatName(Map<String, dynamic> row) => [
    row['employee_first_name'],
    row['employee_last_name'],
  ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
}

final teamApiProvider = Provider<TeamApi>(
  (ref) => TeamApi(ref.watch(apiClientProvider).dio),
);

final teamTodayProvider = FutureProvider<TeamToday>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null || !session.capabilities.isManager) {
    return TeamToday.empty;
  }
  return ref.watch(teamApiProvider).fetchToday(selfId: session.user.id);
});
