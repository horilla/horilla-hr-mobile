/// Normalising four different status conventions into one.
///
/// This is the part of the Requests tab that can be quietly wrong: each
/// source expresses "where has this got to" differently, and showing a
/// cancelled request as live -- or an approved one as pending -- is a
/// mistake someone acts on.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/requests/data/request_models.dart';

void main() {
  group('shift and work-type requests use two booleans', () {
    test('neither flag set is pending', () {
      final request = WorkRequest.fromShiftLike({
        'id': 1,
        'shift_name': 'Night',
        'approved': false,
        'canceled': false,
      }, RequestKind.shift)!;

      expect(request.state, RequestState.pending);
      expect(request.title, 'Night');
      expect(request.kind, RequestKind.shift);
    });

    test('approved is approved', () {
      final request = WorkRequest.fromShiftLike({
        'id': 1,
        'approved': true,
        'canceled': false,
      }, RequestKind.shift)!;
      expect(request.state, RequestState.approved);
    });

    test('cancelled wins over approved', () {
      // A request approved and then cancelled is cancelled. Reading
      // `approved` first would show it as live, which is the mistake this
      // ordering exists to prevent.
      final request = WorkRequest.fromShiftLike({
        'id': 1,
        'approved': true,
        'canceled': true,
      }, RequestKind.shift)!;
      expect(request.state, RequestState.cancelled);
    });

    test('a missing shift name falls back to the kind, not to blank', () {
      final request =
          WorkRequest.fromShiftLike({'id': 1}, RequestKind.workType)!;
      expect(request.title, 'Work type');
    });

    test('the previous shift becomes the meta line', () {
      final request = WorkRequest.fromShiftLike({
        'id': 1,
        'shift_name': 'Night',
        'previous_shift_name': 'Day',
      }, RequestKind.shift)!;
      expect(request.detail, 'from Day');
    });
  });

  group('reimbursements use a status string', () {
    test('each status maps across', () {
      for (final (wire, expected) in [
        ('requested', RequestState.pending),
        ('approved', RequestState.approved),
        ('rejected', RequestState.rejected),
      ]) {
        final request = WorkRequest.fromReimbursement({
          'id': 1,
          'title': 'Taxi',
          'status': wire,
        })!;
        expect(request.state, expected, reason: wire);
      }
    });

    test('an unknown status reads as pending rather than throwing', () {
      final request = WorkRequest.fromReimbursement({
        'id': 1,
        'title': 'Taxi',
        'status': 'escalated',
      })!;
      expect(request.state, RequestState.pending);
    });
  });

  group('asset requests use their own field, Title-cased', () {
    test('case does not matter', () {
      // This is the one endpoint that capitalises its status.
      final request = WorkRequest.fromAssetRequest({
        'id': 1,
        'description': 'Laptop',
        'asset_request_status': 'Approved',
      })!;
      expect(request.state, RequestState.approved);
      expect(request.title, 'Laptop');
    });

    test('both spellings of cancelled are handled', () {
      for (final spelling in ['cancelled', 'canceled', 'Canceled']) {
        final request = WorkRequest.fromAssetRequest({
          'id': 1,
          'asset_request_status': spelling,
        })!;
        expect(request.state, RequestState.cancelled, reason: spelling);
      }
    });
  });

  group('the inbox', () {
    WorkRequest request(RequestState state) => WorkRequest(
          id: 1,
          kind: RequestKind.shift,
          title: 'x',
          state: state,
        );

    test('open means pending, and nothing else', () {
      final inbox = RequestInbox(requests: [
        request(RequestState.pending),
        request(RequestState.approved),
        request(RequestState.rejected),
        request(RequestState.cancelled),
      ]);

      expect(inbox.open.length, 1);
      expect(inbox.closed.length, 3);
    });

    test('rubbish rows are discarded, not rendered empty', () {
      expect(WorkRequest.fromReimbursement('nonsense'), isNull);
      expect(WorkRequest.fromAssetRequest(null), isNull);
      expect(WorkRequest.fromShiftLike(42, RequestKind.shift), isNull);
    });
  });

  // The three create endpoints only auto-fill the requesting employee for
  // callers who lack add-permission on that request type -- a manager or HR
  // user submitting for themselves does not get that auto-fill, and would
  // create an orphaned (employee_id: null) request if the client omitted it.
  // Confirmed live against hr.demo.horilla.com: without it, employee_id came
  // back null; with it, correctly attributed. These pin the three payload
  // shapes so that fix can't silently regress.
  group('create payloads always name the requesting employee', () {
    test('shift request sends employee_id and shift_id, not work_type_id', () {
      final json = ShiftOrWorkTypeRequest(
        forShift: true,
        requestedId: 5,
        previousId: 2,
        requestedDate: DateTime(2026, 10, 1),
        reason: 'Need the day slot',
      ).toJson(1);

      expect(json['employee_id'], 1);
      expect(json['shift_id'], 5);
      expect(json['previous_shift_id'], 2);
      expect(json.containsKey('work_type_id'), isFalse);
      expect(json.containsKey('requested_till'), isFalse);
    });

    test('work-type request sends work_type_id, not shift_id', () {
      final json = ShiftOrWorkTypeRequest(
        forShift: false,
        requestedId: 3,
        previousId: null,
        requestedDate: DateTime(2026, 10, 1),
        requestedTill: DateTime(2026, 10, 15),
        reason: 'Trial hybrid',
      ).toJson(7);

      expect(json['employee_id'], 7);
      expect(json['work_type_id'], 3);
      expect(json.containsKey('previous_work_type_id'), isFalse);
      expect(json['requested_till'], '2026-10-15');
    });

    test('asset request sends requested_employee_id, not employee_id', () {
      // The one endpoint here that names its subject field differently.
      final json = const AssetRequestDraft(
        categoryId: 1,
        reason: 'Laptop died',
      ).toJson(9);

      expect(json['requested_employee_id'], 9);
      expect(json.containsKey('employee_id'), isFalse);
      expect(json['asset_category_id'], 1);
    });

    test('reimbursement sends employee_id plus the fields validation needs', () {
      final json = ReimbursementDraft(
        title: 'Client taxi',
        amount: 450,
        incurredOn: DateTime(2026, 9, 20),
      ).toJson(3);

      expect(json['employee_id'], 3);
      expect(json['type'], 'reimbursement');
      // badge_id/employee_full_name are required by the server's validation
      // despite being derived from employee_id -- any non-blank value
      // passes and is discarded server-side. This only pins "non-blank",
      // not their content.
      expect(json['badge_id'], isNotEmpty);
      expect(json['employee_full_name'], isNotEmpty);
    });
  });

  group('the create screens\' lookup options', () {
    test('a shift option reads employee_shift, not work_type', () {
      final option =
          RequestOption.fromShift({'id': 4, 'employee_shift': 'Night'});
      expect(option?.id, 4);
      expect(option?.name, 'Night');
    });

    test('a work-type option reads work_type, not employee_shift', () {
      final option =
          RequestOption.fromWorkType({'id': 2, 'work_type': 'Hybrid'});
      expect(option?.id, 2);
      expect(option?.name, 'Hybrid');
    });

    test('a malformed option row is discarded, not rendered blank', () {
      expect(RequestOption.fromShift({'id': 1}), isNull);
      expect(RequestOption.fromShift(null), isNull);
    });

    test('an asset category carries how many are available', () {
      final option = AssetCategoryOption.fromJson({
        'id': 1,
        'asset_category_name': 'Laptops',
        'asset_count': 0,
      });
      expect(option?.available, 0);
      expect(option?.name, 'Laptops');
    });
  });
}
