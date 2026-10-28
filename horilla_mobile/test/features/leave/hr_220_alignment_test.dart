/// HR 2.2.0 added the "cancel_requested" leave status and the two endpoints
/// that decide it. These tests pin the behaviour that was wrong before:
/// an approved leave awaiting cancellation was labelled "Pending", and the
/// cancellation never reached a manager using the app.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/api/error_interceptor.dart';
import 'package:horilla_mobile/features/approvals/data/approval_models.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';
import 'package:horilla_mobile/features/leave/data/leave_models.dart';

void main() {
  group('LeaveStatus', () {
    test('cancel_requested is its own status, not "Pending"', () {
      final status = LeaveStatus.fromWire('cancel_requested');
      expect(status, LeaveStatus.cancelRequested);
      expect(status.label, 'Cancellation requested');
      // The bug: it used to land here, telling the employee their approved
      // leave was unconfirmed when it is still in force.
      expect(status, isNot(LeaveStatus.requested));
    });

    test('an unknown status still falls back rather than throwing', () {
      expect(LeaveStatus.fromWire('something_new'), LeaveStatus.requested);
      expect(LeaveStatus.fromWire(null), LeaveStatus.requested);
    });
  });

  group('ApprovalItem.fromLeaveCancellation', () {
    Map<String, dynamic> row({String status = 'cancel_requested'}) => {
      'id': 7,
      'status': status,
      'employee_id': {'id': 42, 'full_name': 'Abigail Roberts'},
      'start_date': '2026-11-02',
      'end_date': '2026-11-04',
      'requested_days': 3,
      'leave_type_id': {'name': 'Casual Leave'},
    };

    test('a cancellation request reaches the manager', () {
      final item = ApprovalItem.fromLeaveCancellation(row(), selfId: 1);
      expect(item, isNotNull);
      expect(item!.kind, ApprovalKind.leaveCancellation);
      expect(item.id, 7);
      expect(item.employeeId, 42);
      expect(item.ask, contains('Cancel'));
      expect(item.ask, contains('Casual Leave'));
      // A manager must not think approving is a formality.
      expect(item.warning, contains('stays approved'));
    });

    test('an ordinary pending leave is not mistaken for a cancellation', () {
      expect(
        ApprovalItem.fromLeaveCancellation(row(status: 'requested'), selfId: 1),
        isNull,
      );
      expect(
        ApprovalItem.fromLeaveCancellation(row(status: 'approved'), selfId: 1),
        isNull,
      );
    });

    test('nobody decides their own cancellation', () {
      expect(ApprovalItem.fromLeaveCancellation(row(), selfId: 42), isNull);
    });
  });

  group('object-level validation errors', () {
    test('the past-date refusal is shown, not swallowed', () {
      // HR 2.2.0 raises this from leave_Validations(), so DRF renders it
      // under non_field_errors -- a list, naming no field.
      final failure = ErrorInterceptor().fromBadRequest({
        'non_field_errors': ['Requests cannot be made for past dates.'],
      });
      expect(
        failure.message,
        contains('Requests cannot be made for past dates.'),
      );
      // It must not become a form field called "non_field_errors".
      if (failure is ApiValidation) {
        expect(failure.fieldErrors.keys, isNot(contains('non_field_errors')));
      }
    });

    test('real field errors still reach their fields', () {
      final failure = ErrorInterceptor().fromBadRequest({
        'start_date': ['This field is required.'],
      });
      expect(failure, isA<ApiValidation>());
      expect((failure as ApiValidation).fieldErrors['start_date'], [
        'This field is required.',
      ]);
    });
  });

  group('Capabilities', () {
    test('the server version is read when sent', () {
      final caps = Capabilities.fromJson({
        'version': '2.2.0',
        'role': 'manager',
        'permissions': {'approve_leave': true},
        'features': {'leave': true},
      });
      expect(caps.serverVersion, '2.2.0');
      expect(caps.isManager, isTrue);
    });

    test('an older server that sends no version is still usable', () {
      final caps = Capabilities.fromJson({
        'role': 'employee',
        'permissions': {},
        'features': {},
      });
      expect(caps.serverVersion, isNull);
    });
  });
}
