/// Normalising six sources into one approvals queue.
///
/// The parts that can quietly go wrong: a manager seeing their own request
/// (every source list includes self), an already-decided request showing as
/// pending, and a kind with no safe reject offering Reject anyway. Payloads
/// below are trimmed from real hr.demo.horilla.com responses.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/approvals/data/approval_models.dart';

const self = 1;

Map<String, dynamic> leave({
  int employee = 13,
  String status = 'requested',
  int clashes = 0,
}) => {
  'id': 122,
  'employee_id': {'id': employee, 'full_name': 'Alexander Smith'},
  'leave_type_id': {'id': 4, 'name': 'Maternity Leave'},
  'start_date': '2026-10-07',
  'end_date': '2026-10-09',
  'requested_days': 3.0,
  'leave_clashes_count': clashes,
  'status': status,
};

Map<String, dynamic> shift({
  int employee = 60,
  bool approved = false,
  bool canceled = false,
}) => {
  'id': 15,
  'employee_first_name': 'Joseph',
  'employee_last_name': 'Diaz',
  'shift_name': 'Morning Shift',
  'previous_shift_name': 'Night Shift',
  'created_at': '2026-09-13T14:30:00+05:30',
  'requested_date': '2026-04-19',
  'requested_till': '2026-05-10',
  'description': 'Requesting a temporary shift change.',
  'is_permanent_shift': false,
  'approved': approved,
  'canceled': canceled,
  'employee_id': employee,
};

void main() {
  group('leave', () {
    test('a pending request from a report is queued with its ask', () {
      final item = ApprovalItem.fromLeave(leave(), selfId: self)!;
      expect(item.kind, ApprovalKind.leave);
      expect(item.name, 'Alexander Smith');
      expect(item.ask, 'Maternity Leave · 7 Oct – 9 Oct · 3 days');
      expect(item.warning, isNull);
      expect(item.canReject, isTrue);
    });

    test("the manager's own request is not theirs to approve", () {
      expect(ApprovalItem.fromLeave(leave(employee: self), selfId: self),
          isNull);
    });

    test('an already-decided request is not pending', () {
      expect(ApprovalItem.fromLeave(leave(status: 'approved'), selfId: self),
          isNull);
    });

    test('clashes become an advisory warning', () {
      final item = ApprovalItem.fromLeave(leave(clashes: 2), selfId: self)!;
      expect(item.warning, 'Overlaps 2 approved leaves in the team.');
    });
  });

  group('shift and work type', () {
    test('an open request reads as from -> to', () {
      final item = ApprovalItem.fromShift(shift(), selfId: self)!;
      expect(item.ask, 'Night Shift → Morning Shift · 19 Apr – 10 May');
      expect(item.reason, 'Requesting a temporary shift change.');
      expect(item.submitted, isNotNull);
    });

    test('approved or cancelled is not pending', () {
      expect(ApprovalItem.fromShift(shift(approved: true), selfId: self),
          isNull);
      expect(ApprovalItem.fromShift(shift(canceled: true), selfId: self),
          isNull);
    });

    test('work type uses its own field names', () {
      final item = ApprovalItem.fromWorkType({
        'id': 10,
        'employee_first_name': 'Joseph',
        'employee_last_name': 'Diaz',
        'work_type_name': 'Remote',
        'previous_work_type_name': 'Work From Office',
        'requested_date': '2026-06-03',
        'is_permanent_work_type': true,
        'approved': false,
        'canceled': false,
        'employee_id': 60,
      }, selfId: self)!;
      expect(item.kind, ApprovalKind.workType);
      expect(item.ask, 'Work From Office → Remote · from 3 Jun, permanent');
    });
  });

  group('attendance corrections', () {
    test('are approve-only -- the server has no safe reject', () {
      final item = ApprovalItem.fromAttendanceRequest({
        'id': 3236,
        'employee_first_name': 'Angel',
        'employee_last_name': 'Sanor',
        'attendance_date': '2026-09-23',
        'attendance_clock_in': '08:51:00',
        'attendance_clock_out': '18:51:00',
        'employee_id': 119,
      }, selfId: self)!;
      expect(item.canReject, isFalse);
      expect(item.ask, 'Correction for 23 Sep · 08:51–18:51');
    });
  });

  group('reimbursements', () {
    Map<String, dynamic> claim({String type = 'reimbursement'}) => {
      'id': 1008,
      'employee_full_name': 'Harper Edwards',
      'title': 'Client taxi',
      'type': type,
      'amount': 1500.0,
      'status': 'requested',
      'employee_id': 24,
    };

    test('the amount carries the configured currency', () {
      final item = ApprovalItem.fromReimbursement(
        claim(),
        selfId: self,
        currencySymbol: '₹',
      )!;
      expect(item.ask, 'Client taxi · ₹1500');
      expect(item.encashAmount, isNull);
    });

    test('encashment claims keep the amount their approve call needs', () {
      final item = ApprovalItem.fromReimbursement(
        claim(type: 'leave_encashment'),
        selfId: self,
      )!;
      expect(item.encashAmount, 1500.0);
    });
  });

  group('the inbox', () {
    final inbox = ApprovalInbox([
      ApprovalItem.fromLeave(leave(), selfId: self)!,
      ApprovalItem.fromShift(shift(), selfId: self)!,
    ]);

    test('counts per filter', () {
      expect(inbox.countFor(ApprovalFilter.all), 2);
      expect(inbox.countFor(ApprovalFilter.leave), 1);
      expect(inbox.countFor(ApprovalFilter.workType), 1);
      expect(inbox.countFor(ApprovalFilter.expense), 0);
    });

    test('summarises for the Home band', () {
      expect(inbox.summary(), '1 leave · 1 shift change');
    });

    test('the summary keeps the three largest kinds and folds the rest', () {
      ApprovalItem of(ApprovalKind kind, int id) => ApprovalItem(
        kind: kind,
        id: id,
        employeeId: 9,
        name: 'X',
        ask: 'x',
      );
      final busy = ApprovalInbox([
        for (var i = 0; i < 4; i++) of(ApprovalKind.leave, i),
        for (var i = 0; i < 3; i++) of(ApprovalKind.shift, i),
        for (var i = 0; i < 2; i++) of(ApprovalKind.attendance, i),
        of(ApprovalKind.reimbursement, 1),
        of(ApprovalKind.workType, 1),
      ]);
      expect(
        busy.summary(),
        '4 leave · 3 shift change · 2 attendance fix · 2 more',
      );
    });

    test('keys are unique across kinds even when ids collide', () {
      final a = ApprovalItem.fromLeave(leave(), selfId: self)!;
      final b = ApprovalItem.fromShift({...shift(), 'id': a.id}, selfId: self)!;
      expect(a.key, isNot(b.key));
    });
  });
}
