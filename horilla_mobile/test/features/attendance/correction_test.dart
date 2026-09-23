/// Attendance corrections.
///
/// The payload is the interesting part: the server's form requires fields a
/// correction is not changing, and an overnight shift needs its clock-out
/// dated to the following day or the record reads as a negative day.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/attendance/data/correction_models.dart';

AttendanceCorrection correction({
  String clockIn = '09:00',
  String? clockOut = '18:00',
  String reason = 'Forgot to clock out',
  int? shiftId = 3,
  int? workTypeId = 4,
  DateTime? date,
}) =>
    AttendanceCorrection(
      attendanceId: 11,
      employeeId: 42,
      attendanceDate: date ?? DateTime(2026, 9, 22),
      clockIn: clockIn,
      clockOut: clockOut,
      reason: reason,
      shiftId: shiftId,
      workTypeId: workTypeId,
    );

void main() {
  group('validity', () {
    test('times and a reason make a request', () {
      expect(correction().isValid, isTrue);
    });

    test('no reason is not a request', () {
      expect(correction(reason: '').isValid, isFalse);
      expect(correction(reason: '   ').isValid, isFalse);
    });

    test('no start time is not a request', () {
      expect(correction(clockIn: '').isValid, isFalse);
    });

    test('an open day with no finish time is still a valid request', () {
      // Someone correcting a day they are still working should be able to.
      expect(correction(clockOut: null).isValid, isTrue);
      expect(correction(clockOut: '').isValid, isTrue);
    });
  });

  group('payload', () {
    test('carries the day, the times and the reason', () {
      final json = correction().toJson();

      expect(json['employee_id'], 42);
      expect(json['attendance_date'], '2026-09-22');
      expect(json['attendance_clock_in'], '09:00');
      expect(json['attendance_clock_out'], '18:00');
      expect(json['request_description'], 'Forgot to clock out');
    });

    test('dates are zero-padded', () {
      final json = correction(date: DateTime(2026, 1, 5)).toJson();
      expect(json['attendance_date'], '2026-01-05');
    });

    test('the reason is trimmed', () {
      final json = correction(reason: '  Missed the terminal  ').toJson();
      expect(json['request_description'], 'Missed the terminal');
    });

    test('shift and work type are carried back unchanged', () {
      // The form requires them. They are echoed rather than edited: letting a
      // correction re-assign a shift would make it a different request than
      // the one being approved.
      final json = correction().toJson();
      expect(json['shift_id'], 3);
      expect(json['work_type_id'], 4);
    });

    test('an absent shift or work type is omitted, not sent as null', () {
      final json = correction(shiftId: null, workTypeId: null).toJson();
      expect(json.containsKey('shift_id'), isFalse);
      expect(json.containsKey('work_type_id'), isFalse);
    });

    test('an open day sends no clock-out at all', () {
      final json = correction(clockOut: null).toJson();
      expect(json.containsKey('attendance_clock_out'), isFalse);
      expect(json.containsKey('attendance_clock_out_date'), isFalse);
    });
  });

  group('overnight shifts', () {
    test('a normal day clocks out on the same date', () {
      final json = correction(clockIn: '09:00', clockOut: '18:00').toJson();
      expect(json['attendance_clock_out_date'], '2026-09-22');
    });

    test('finishing earlier than starting rolls to the next day', () {
      // 22:00 to 06:00 is a night shift, not eight hours of negative time.
      final json = correction(clockIn: '22:00', clockOut: '06:00').toJson();
      expect(json['attendance_clock_in_date'], '2026-09-22');
      expect(json['attendance_clock_out_date'], '2026-09-23');
    });

    test('rolling over a month end lands on the first', () {
      final json = correction(
        clockIn: '22:00',
        clockOut: '06:00',
        date: DateTime(2026, 9, 30),
      ).toJson();
      expect(json['attendance_clock_out_date'], '2026-10-01');
    });

    test('equal times are treated as same-day, not overnight', () {
      final json = correction(clockIn: '09:00', clockOut: '09:00').toJson();
      expect(json['attendance_clock_out_date'], '2026-09-22');
    });
  });
}
