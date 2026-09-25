/// A manager's queue, normalised from six sources that agree on almost
/// nothing: leave and allocation requests carry a `status` string and a
/// nested employee object, shift and work-type requests two booleans and
/// flat name fields, attendance corrections are pending by virtue of being
/// in their list at all, and reimbursements a lower-case `status`.
///
/// Every source list also includes the caller's own requests (the server's
/// subordinate filters add "self" on purpose), and a manager cannot approve
/// their own -- so each parser drops rows belonging to [selfId].
library;

import 'package:intl/intl.dart';

enum ApprovalFilter {
  all('All'),
  leave('Leave'),
  workType('Work type'),
  expense('Expense'),
  attendance('Attendance');

  const ApprovalFilter(this.label);

  final String label;
}

enum ApprovalKind {
  leave('Leave', ApprovalFilter.leave),
  allocation('Leave allocation', ApprovalFilter.leave),
  attendance('Attendance fix', ApprovalFilter.attendance),
  shift('Shift change', ApprovalFilter.workType),
  workType('Work type', ApprovalFilter.workType),
  reimbursement('Reimbursement', ApprovalFilter.expense);

  const ApprovalKind(this.label, this.filter);

  final String label;
  final ApprovalFilter filter;
}

class ApprovalItem {
  const ApprovalItem({
    required this.kind,
    required this.id,
    required this.employeeId,
    required this.name,
    required this.ask,
    this.reason,
    this.submitted,
    this.warning,
    this.canReject = true,
    this.encashAmount,
  });

  final ApprovalKind kind;
  final int id;
  final int employeeId;
  final String name;

  /// What is being asked for, in one line.
  final String ask;
  final String? reason;
  final DateTime? submitted;

  /// Advisory, never blocking -- the design's rule.
  final String? warning;

  /// False where the server has no working reject for this kind.
  final bool canReject;

  /// Set only for leave/bonus encashment claims, whose approve call must
  /// echo the amount back.
  final double? encashAmount;

  /// Unique across kinds -- ids are only unique within one source.
  String get key => '${kind.name}-$id';

  static final _day = DateFormat('d MMM');

  // --- one adapter per source --------------------------------------------

  static ApprovalItem? fromLeave(Object? v, {required int selfId}) {
    if (v is! Map<String, dynamic> || v['status'] != 'requested') return null;
    final employee = _nested(v['employee_id']);
    if (employee == null || employee.$1 == selfId) return null;
    final start = _date(v['start_date']);
    final end = _date(v['end_date']);
    final days = _num(v['requested_days']);
    final clashes = v['leave_clashes_count'];
    return ApprovalItem(
      kind: ApprovalKind.leave,
      id: _int(v['id']),
      employeeId: employee.$1,
      name: employee.$2,
      ask: [
        _nestedName(v['leave_type_id']) ?? 'Leave',
        if (start != null) _range(start, end),
        if (days != null) _days(days),
      ].join(' · '),
      warning: clashes is int && clashes > 0
          ? 'Overlaps $clashes approved '
                '${clashes == 1 ? 'leave' : 'leaves'} in the team.'
          : null,
    );
  }

  static ApprovalItem? fromAllocation(Object? v, {required int selfId}) {
    if (v is! Map<String, dynamic> || v['status'] != 'requested') return null;
    final employee = _nested(v['employee_id']);
    if (employee == null || employee.$1 == selfId) return null;
    final days = _num(v['requested_days']);
    return ApprovalItem(
      kind: ApprovalKind.allocation,
      id: _int(v['id']),
      employeeId: employee.$1,
      name: employee.$2,
      ask: [
        _nestedName(v['leave_type_id']) ?? 'Leave',
        if (days != null) '+${_days(days)}',
      ].join(' · '),
      reason: _text(v['description']),
    );
  }

  /// Attendance corrections are pending by being in the list; approving one
  /// removes it. The server's reject for these is unsafe (see
  /// ApprovalsApi.decide), so they are approve-only here.
  static ApprovalItem? fromAttendanceRequest(Object? v, {required int selfId}) {
    if (v is! Map<String, dynamic>) return null;
    final employeeId = v['employee_id'];
    if (employeeId is! int || employeeId == selfId) return null;
    final date = _date(v['attendance_date']);
    final inTime = _hm(v['attendance_clock_in']);
    final outTime = _hm(v['attendance_clock_out']);
    return ApprovalItem(
      kind: ApprovalKind.attendance,
      id: _int(v['id']),
      employeeId: employeeId,
      name: _flatName(v),
      ask: [
        date == null ? 'Correction' : 'Correction for ${_day.format(date)}',
        if (inTime != null) '$inTime–${outTime ?? '…'}',
      ].join(' · '),
      reason: _text(v['request_description']),
      canReject: false,
    );
  }

  static ApprovalItem? fromShift(Object? v, {required int selfId}) =>
      _fromShiftLike(v, selfId: selfId, kind: ApprovalKind.shift);

  static ApprovalItem? fromWorkType(Object? v, {required int selfId}) =>
      _fromShiftLike(v, selfId: selfId, kind: ApprovalKind.workType);

  static ApprovalItem? _fromShiftLike(
    Object? v, {
    required int selfId,
    required ApprovalKind kind,
  }) {
    if (v is! Map<String, dynamic>) return null;
    if (v['approved'] == true || v['canceled'] == true) return null;
    final employeeId = v['employee_id'];
    if (employeeId is! int || employeeId == selfId) return null;

    final isShift = kind == ApprovalKind.shift;
    final to = _text(v[isShift ? 'shift_name' : 'work_type_name']);
    final from = _text(
      v[isShift ? 'previous_shift_name' : 'previous_work_type_name'],
    );
    final start = _date(v['requested_date']);
    final till = _date(v['requested_till']);
    final permanent =
        v[isShift ? 'is_permanent_shift' : 'is_permanent_work_type'] == true;

    return ApprovalItem(
      kind: kind,
      id: _int(v['id']),
      employeeId: employeeId,
      name: _flatName(v),
      ask: [
        from == null ? (to ?? kind.label) : '$from → ${to ?? '?'}',
        if (start != null)
          permanent
              ? 'from ${_day.format(start)}, permanent'
              : _range(start, till),
      ].join(' · '),
      reason: _text(v['description']),
      submitted: _date(v['created_at']),
    );
  }

  static ApprovalItem? fromReimbursement(
    Object? v, {
    required int selfId,
    String? currencySymbol,
  }) {
    if (v is! Map<String, dynamic> || v['status'] != 'requested') return null;
    final employeeId = v['employee_id'];
    if (employeeId is! int || employeeId == selfId) return null;
    final amount = _num(v['amount']);
    final isEncashment = v['type'] != null && v['type'] != 'reimbursement';
    return ApprovalItem(
      kind: ApprovalKind.reimbursement,
      id: _int(v['id']),
      employeeId: employeeId,
      name: _text(v['employee_full_name']) ?? 'Employee',
      ask: [
        _text(v['title']) ?? 'Reimbursement',
        if (amount != null) '${currencySymbol ?? ''}${_money(amount)}',
      ].join(' · '),
      reason: _text(v['description']),
      submitted: _date(v['created_at']),
      encashAmount: isEncashment ? amount : null,
    );
  }

  // --- helpers -------------------------------------------------------------

  static (int, String)? _nested(Object? v) {
    if (v is! Map<String, dynamic>) return null;
    final id = v['id'];
    if (id is! int) return null;
    return (id, _text(v['full_name']) ?? 'Employee');
  }

  static String? _nestedName(Object? v) =>
      v is Map<String, dynamic> ? _text(v['name']) : null;

  static String _flatName(Map<String, dynamic> v) {
    final name = [
      _text(v['employee_first_name']),
      _text(v['employee_last_name']),
    ].whereType<String>().join(' ');
    return name.isEmpty ? 'Employee' : name;
  }

  static String? _text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static int _int(Object? v) => v is int ? v : 0;

  static double? _num(Object? v) => switch (v) {
    final int i => i.toDouble(),
    final double d => d,
    final String s => double.tryParse(s),
    _ => null,
  };

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  /// "08:51:00" -> "08:51".
  static String? _hm(Object? v) =>
      v is String && v.length >= 5 ? v.substring(0, 5) : null;

  static String _range(DateTime start, DateTime? end) =>
      end == null || _sameDay(start, end)
      ? _day.format(start)
      : '${_day.format(start)} – ${_day.format(end)}';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _days(double d) {
    final text = d == d.roundToDouble()
        ? d.toStringAsFixed(0)
        : d.toStringAsFixed(1);
    return '$text ${d == 1 ? 'day' : 'days'}';
  }

  static String _money(double d) =>
      d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(2);
}

/// Everything waiting on this manager, newest first.
class ApprovalInbox {
  const ApprovalInbox(this.items);

  final List<ApprovalItem> items;

  static const empty = ApprovalInbox([]);

  int countFor(ApprovalFilter filter) => filter == ApprovalFilter.all
      ? items.length
      : items.where((i) => i.kind.filter == filter).length;

  List<ApprovalItem> visible(ApprovalFilter filter) =>
      filter == ApprovalFilter.all
      ? items
      : items.where((i) => i.kind.filter == filter).toList();

  /// "3 leave · 1 shift change" -- the Home band's subline. The three
  /// largest kinds only, so it stays one line when everything is pending.
  String summary() {
    final counts = <String, int>{};
    for (final item in items) {
      final label = item.kind.label.toLowerCase();
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return summarizeCounts(counts);
  }
}

/// Shared by [ApprovalInbox.summary] and [PendingApprovals.summary]: the
/// three largest labels, then "N more" for the rest, so it stays one line
/// however many kinds are actually pending.
String summarizeCounts(Map<String, int> counts) {
  final ranked = counts.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final shown = ranked.take(3).map((e) => '${e.value} ${e.key}');
  final rest = ranked.skip(3).fold<int>(0, (sum, e) => sum + e.value);
  return [...shown, if (rest > 0) '$rest more'].join(' · ');
}

/// The Home aggregate's cheap stand-in for a full [ApprovalInbox] fetch --
/// just the counts, one per kind, so the band on Home can show "N pending"
/// without pulling six paginated lists just to count them.
class PendingApprovals {
  const PendingApprovals({required this.total, required this.byKind});

  final int total;
  final Map<ApprovalKind, int> byKind;

  static const _keys = {
    'leave': ApprovalKind.leave,
    'allocation': ApprovalKind.allocation,
    'attendance': ApprovalKind.attendance,
    'shift': ApprovalKind.shift,
    'work_type': ApprovalKind.workType,
    'reimbursement': ApprovalKind.reimbursement,
  };

  static PendingApprovals? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final total = value['total'];
    final byKindJson = value['by_kind'];
    if (total is! int || byKindJson is! Map<String, dynamic>) return null;
    final byKind = <ApprovalKind, int>{
      for (final MapEntry(:key, :value) in byKindJson.entries)
        if (_keys[key] case final kind?)
          if (value is int) kind: value,
    };
    return PendingApprovals(total: total, byKind: byKind);
  }

  String summary() => summarizeCounts({
    for (final MapEntry(:key, :value) in byKind.entries)
      key.label.toLowerCase(): value,
  });
}
