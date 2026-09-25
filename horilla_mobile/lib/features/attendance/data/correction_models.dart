/// Asking for an attendance day to be corrected.
///
/// The server owns the hard part: `AttendanceRequestForm` rebuilds the record
/// and writes `requested_data` itself, so the app never constructs that JSON
/// blob. What it sends is the corrected day as ordinary fields, plus a reason.
///
/// Note what is *not* editable here. Shift and work type are carried back
/// unchanged from the existing record because the form requires them, not
/// because someone should be changing them in a correction -- a correction
/// fixes times, and letting it quietly re-assign a shift would make it a
/// different request than the one HR thinks it is approving.
library;

import 'package:flutter/foundation.dart';

@immutable
class AttendanceCorrection {
  const AttendanceCorrection({
    required this.attendanceId,
    required this.employeeId,
    required this.attendanceDate,
    required this.clockIn,
    required this.reason,
    this.clockOut,
    this.shiftId,
    this.workTypeId,
    this.minimumHour,
  });

  final int attendanceId;
  final int employeeId;
  final DateTime attendanceDate;

  /// `HH:MM`, as the server's time widgets expect.
  final String clockIn;
  final String? clockOut;

  final String reason;
  final int? shiftId;
  final int? workTypeId;

  /// The day's existing `minimum_hour`. The server's form requires it (and
  /// `attendance_worked_hour`) and rejects the correction without them.
  final String? minimumHour;

  bool get isValid => clockIn.isNotEmpty && reason.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'attendance_date': _date(attendanceDate),
    // The clock-in date defaults to the attendance date. An overnight
    // shift's clock-out can land on the next day, which is why only the
    // out-date is allowed to differ.
    'attendance_clock_in_date': _date(attendanceDate),
    'attendance_clock_in': clockIn,
    if (clockOut != null && clockOut!.isNotEmpty) ...{
      'attendance_clock_out': clockOut,
      'attendance_clock_out_date': _date(_clockOutDate),
    },
    'request_description': reason.trim(),
    'attendance_worked_hour': workedHour,
    'minimum_hour': (minimumHour?.isNotEmpty ?? false) ? minimumHour : '00:00',
    if (shiftId != null) 'shift_id': shiftId,
    if (workTypeId != null) 'work_type_id': workTypeId,
  };

  /// Rolls the clock-out to the next day when it reads earlier than the
  /// clock-in, which is what an overnight shift looks like.
  DateTime get _clockOutDate {
    final out = clockOut;
    if (out == null || out.isEmpty) return attendanceDate;
    return _minutes(out) < _minutes(clockIn)
        ? attendanceDate.add(const Duration(days: 1))
        : attendanceDate;
  }

  /// `HH:MM` between clock-in and clock-out, overnight-aware; `00:00` while
  /// the day has no clock-out.
  String get workedHour {
    final out = clockOut;
    if (out == null || out.isEmpty) return '00:00';
    var span = _minutes(out) - _minutes(clockIn);
    if (span < 0) span += 24 * 60;
    return '${(span ~/ 60).toString().padLeft(2, '0')}:'
        '${(span % 60).toString().padLeft(2, '0')}';
  }

  static int _minutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
