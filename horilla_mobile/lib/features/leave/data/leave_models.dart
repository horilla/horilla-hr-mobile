/// Leave models.
library;

/// Half-day handling, as the server names it.
enum LeaveBreakdown {
  fullDay('full_day', 'Full day'),
  firstHalf('first_half', 'First half'),
  secondHalf('second_half', 'Second half');

  const LeaveBreakdown(this.wire, this.label);

  final String wire;
  final String label;

  static LeaveBreakdown fromWire(Object? value) =>
      LeaveBreakdown.values.firstWhere(
        (b) => b.wire == value,
        orElse: () => LeaveBreakdown.fullDay,
      );
}

/// Where a request has got to. Unknown values fall back to [requested] rather
/// than throwing: a server that adds a status should not break the screen.
enum LeaveStatus {
  requested('requested', 'Pending'),
  approved('approved', 'Approved'),
  cancelled('cancelled', 'Cancelled'),
  rejected('rejected', 'Rejected');

  const LeaveStatus(this.wire, this.label);

  final String wire;
  final String label;

  static LeaveStatus fromWire(Object? value) => LeaveStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => LeaveStatus.requested,
      );
}

class LeaveType {
  const LeaveType({required this.id, required this.name});

  final int id;
  final String name;

  static LeaveType? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final name = value['name'];
    if (name is! String || name.isEmpty) return null;
    return LeaveType(
      id: value['id'] is int ? value['id'] as int : 0,
      name: name,
    );
  }
}

/// One row of the balance grid.
class LeaveBalance {
  const LeaveBalance({
    required this.id,
    required this.type,
    required this.availableDays,
    required this.carryforwardDays,
  });

  final int id;
  final LeaveType type;
  final double availableDays;
  final double carryforwardDays;

  /// What the employee can actually take. The server sends this too, but it
  /// is derived, so it is recomputed rather than trusted to be present.
  double get totalDays => availableDays + carryforwardDays;

  static LeaveBalance? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final type = LeaveType.fromJson(value['leave_type_id']);
    if (type == null) return null;
    return LeaveBalance(
      id: value['id'] is int ? value['id'] as int : 0,
      type: type,
      availableDays: _toDouble(value['available_days']) ?? 0,
      carryforwardDays: _toDouble(value['carryforward_days']) ?? 0,
    );
  }
}

class LeaveRequestSummary {
  const LeaveRequestSummary({
    required this.id,
    required this.type,
    required this.startDate,
    required this.status,
    required this.requestedDays,
    this.endDate,
  });

  final int id;
  final LeaveType? type;
  final DateTime startDate;
  final DateTime? endDate;
  final LeaveStatus status;
  final double requestedDays;

  static LeaveRequestSummary? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final start = value['start_date'];
    final startDate = start is String ? DateTime.tryParse(start) : null;
    if (startDate == null) return null;

    final end = value['end_date'];
    return LeaveRequestSummary(
      id: value['id'] is int ? value['id'] as int : 0,
      type: LeaveType.fromJson(value['leave_type_id']),
      startDate: startDate,
      endDate: end is String ? DateTime.tryParse(end) : null,
      status: LeaveStatus.fromWire(value['status']),
      requestedDays: _toDouble(value['requested_days']) ?? 0,
    );
  }
}

class Holiday {
  const Holiday({required this.id, required this.name, required this.startDate});

  final int id;
  final String name;
  final DateTime startDate;

  static Holiday? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final name = value['name'];
    final start = value['start_date'];
    final startDate = start is String ? DateTime.tryParse(start) : null;
    if (name is! String || name.isEmpty || startDate == null) return null;
    return Holiday(
      id: value['id'] is int ? value['id'] as int : 0,
      name: name,
      startDate: startDate,
    );
  }
}

class LeaveOverview {
  const LeaveOverview({
    required this.balances,
    required this.requests,
    required this.holidays,
  });

  final List<LeaveBalance> balances;
  final List<LeaveRequestSummary> requests;
  final List<Holiday> holidays;
}

/// What the apply form sends.
class LeaveApplication {
  const LeaveApplication({
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.startBreakdown,
    required this.endBreakdown,
    required this.reason,
  });

  final int leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final LeaveBreakdown startBreakdown;
  final LeaveBreakdown endBreakdown;
  final String reason;

  /// Days this request consumes.
  ///
  /// Calendar days, adjusted for half-days at either end. Weekends and
  /// holidays are NOT excluded here -- the server owns that, because it knows
  /// the company's weekly-off configuration and holiday calendar. This is a
  /// preview to set expectations, and the screen says so rather than
  /// presenting it as the final figure.
  double get estimatedDays {
    final span = endDate.difference(startDate).inDays + 1;
    if (span <= 0) return 0;
    if (span == 1) {
      return startBreakdown == LeaveBreakdown.fullDay ? 1 : 0.5;
    }
    var days = span.toDouble();
    if (startBreakdown != LeaveBreakdown.fullDay) days -= 0.5;
    if (endBreakdown != LeaveBreakdown.fullDay) days -= 0.5;
    return days;
  }

  Map<String, dynamic> toJson(int employeeId) => {
        'employee_id': employeeId,
        'leave_type_id': leaveTypeId,
        'start_date': _date(startDate),
        'end_date': _date(endDate),
        'start_date_breakdown': startBreakdown.wire,
        'end_date_breakdown': endBreakdown.wire,
        'description': reason,
      };

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

double? _toDouble(Object? value) => switch (value) {
      final double d => d,
      final int i => i.toDouble(),
      final String s => double.tryParse(s),
      _ => null,
    };

/// Asking HR for more days of a leave type.
///
/// Distinct from applying for leave: this does not book time off, it asks for
/// the balance itself to be increased. The handoff notes it is HR-approved
/// rather than manager-approved, which is why the screen says so -- someone
/// expecting their manager to action it would otherwise wait on the wrong
/// person.
class LeaveAllocationRequest {
  const LeaveAllocationRequest({
    required this.leaveTypeId,
    required this.requestedDays,
    required this.reason,
  });

  final int leaveTypeId;
  final double requestedDays;
  final String reason;

  bool get isValid => requestedDays > 0 && reason.trim().isNotEmpty;

  Map<String, dynamic> toJson(int employeeId) => {
        'employee_id': employeeId,
        'leave_type_id': leaveTypeId,
        'requested_days': requestedDays,
        'description': reason.trim(),
      };
}
