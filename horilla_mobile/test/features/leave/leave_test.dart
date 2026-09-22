/// Leave: day arithmetic, request shape, and the screens.
///
/// The day count is where being quietly wrong matters most -- it is the
/// number a person decides on before submitting, and a half-day off is a
/// real-world mistake, not a cosmetic one.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/leave/data/leave_models.dart';

LeaveApplication application({
  DateTime? start,
  DateTime? end,
  LeaveBreakdown startBreakdown = LeaveBreakdown.fullDay,
  LeaveBreakdown endBreakdown = LeaveBreakdown.fullDay,
}) =>
    LeaveApplication(
      leaveTypeId: 1,
      startDate: start ?? DateTime(2026, 9, 21),
      endDate: end ?? DateTime(2026, 9, 21),
      startBreakdown: startBreakdown,
      endBreakdown: endBreakdown,
      reason: 'Because',
    );

void main() {
  group('day estimate', () {
    test('a single full day is one day', () {
      expect(application().estimatedDays, 1);
    });

    test('a single half day is half a day', () {
      // Both ends are the same date, so only one half can be taken -- the
      // naive "subtract a half per end" would wrongly give zero here.
      expect(
        application(startBreakdown: LeaveBreakdown.firstHalf).estimatedDays,
        0.5,
      );
      expect(
        application(startBreakdown: LeaveBreakdown.secondHalf).estimatedDays,
        0.5,
      );
    });

    test('an inclusive range counts both ends', () {
      expect(
        application(
          start: DateTime(2026, 9, 21),
          end: DateTime(2026, 9, 23),
        ).estimatedDays,
        3,
      );
    });

    test('half days at either end each take off a half', () {
      expect(
        application(
          start: DateTime(2026, 9, 21),
          end: DateTime(2026, 9, 23),
          startBreakdown: LeaveBreakdown.secondHalf,
        ).estimatedDays,
        2.5,
      );
      expect(
        application(
          start: DateTime(2026, 9, 21),
          end: DateTime(2026, 9, 23),
          startBreakdown: LeaveBreakdown.secondHalf,
          endBreakdown: LeaveBreakdown.firstHalf,
        ).estimatedDays,
        2,
      );
    });

    test('an end before the start is zero, not negative', () {
      expect(
        application(
          start: DateTime(2026, 9, 23),
          end: DateTime(2026, 9, 21),
        ).estimatedDays,
        0,
      );
    });
  });

  group('request payload', () {
    test('dates are sent as plain ISO days, zero-padded', () {
      final json = application(
        start: DateTime(2026, 1, 5),
        end: DateTime(2026, 1, 5),
      ).toJson(42);

      expect(json['start_date'], '2026-01-05');
      expect(json['end_date'], '2026-01-05');
      expect(json['employee_id'], 42);
      expect(json['start_date_breakdown'], 'full_day');
    });

    test('breakdown goes over the wire as the server names it', () {
      final json = application(
        startBreakdown: LeaveBreakdown.firstHalf,
        endBreakdown: LeaveBreakdown.secondHalf,
      ).toJson(1);

      expect(json['start_date_breakdown'], 'first_half');
      expect(json['end_date_breakdown'], 'second_half');
    });
  });

  group('parsing', () {
    test('an unknown status does not break the screen', () {
      // A server that adds a status should degrade, not crash.
      expect(LeaveStatus.fromWire('something_new'), LeaveStatus.requested);
      expect(LeaveStatus.fromWire(null), LeaveStatus.requested);
      expect(LeaveStatus.fromWire('approved'), LeaveStatus.approved);
    });

    test('an unknown breakdown falls back to a full day', () {
      expect(LeaveBreakdown.fromWire('quarter_day'), LeaveBreakdown.fullDay);
    });

    test('a balance totals available plus carried forward', () {
      final balance = LeaveBalance.fromJson({
        'id': 1,
        'leave_type_id': {'id': 2, 'name': 'Casual'},
        'available_days': 6.5,
        'carryforward_days': 2.0,
      });
      expect(balance!.totalDays, 8.5);
      expect(balance.type.name, 'Casual');
    });

    test('numeric strings are accepted, as DRF sometimes sends them', () {
      final balance = LeaveBalance.fromJson({
        'id': 1,
        'leave_type_id': {'id': 2, 'name': 'Sick'},
        'available_days': '4.0',
        'carryforward_days': '0',
      });
      expect(balance!.totalDays, 4);
    });

    test('a balance without a leave type is discarded', () {
      expect(LeaveBalance.fromJson({'id': 1, 'available_days': 3}), isNull);
    });

    test('a request without a start date is discarded', () {
      expect(LeaveRequestSummary.fromJson({'id': 1}), isNull);
    });

    test('a holiday needs both a name and a date', () {
      expect(Holiday.fromJson({'id': 1, 'name': 'Onam'}), isNull);
      expect(
        Holiday.fromJson({'id': 1, 'start_date': '2026-09-24'}),
        isNull,
      );
      expect(
        Holiday.fromJson({
          'id': 1,
          'name': 'Onam',
          'start_date': '2026-09-24',
        }),
        isNotNull,
      );
    });
  });
}
