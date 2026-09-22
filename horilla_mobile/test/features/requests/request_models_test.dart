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
}
