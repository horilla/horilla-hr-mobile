/// The undo window: a decision leaves the queue at once, but is only sent
/// when its window closes -- so Undo can honestly take it back.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/auth/session.dart';
import 'package:horilla_mobile/features/approvals/data/approval_models.dart';
import 'package:horilla_mobile/features/approvals/data/approvals_api.dart';
import 'package:horilla_mobile/features/approvals/data/approvals_controller.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';
import 'package:horilla_mobile/shared/widgets/toast.dart';

const window = Duration(milliseconds: 40);

const item = ApprovalItem(
  kind: ApprovalKind.leave,
  id: 7,
  employeeId: 13,
  name: 'Arun Menon',
  ask: 'Casual Leave · 2 Oct · 1 day',
);

Session session(String role) => Session(
  host: 'https://hr.example.test',
  user: const SignedInUser(id: 1, fullName: 'Nisha Prakash'),
  capabilities: Capabilities(role: role, permissions: const {}, features: const {}),
  isCleartext: false,
  geoFencingEnabled: false,
  faceDetectionEnabled: false,
);

class FakeApi extends ApprovalsApi {
  FakeApi({this.failWith}) : super(Dio());

  final ApiFailure? failWith;
  int fetches = 0;
  final decisions = <(String, bool)>[];

  @override
  Future<ApprovalInbox> fetchInbox({
    required int selfId,
    String? currencySymbol,
  }) async {
    fetches++;
    return const ApprovalInbox([item]);
  }

  @override
  Future<void> decide(ApprovalItem item, {required bool approve}) async {
    decisions.add((item.key, approve));
    if (failWith != null) throw failWith!;
  }
}

class _Session extends SessionController {
  _Session(this.value);

  final Session value;

  @override
  Session? build() => value;
}

class _ShortWindow extends ApprovalsController {
  @override
  Duration get undoWindow => window;
}

ProviderContainer container(FakeApi api, {String role = 'manager'}) {
  final c = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(() => _Session(session(role))),
      approvalsApiProvider.overrideWithValue(api),
      approvalsProvider.overrideWith(_ShortWindow.new),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> pastWindow() => Future.delayed(window * 3);

void main() {
  test('a decision leaves the queue at once but is sent only after the '
      'window', () async {
    final api = FakeApi();
    final c = container(api);
    await c.read(approvalsProvider.future);

    c.read(approvalsProvider.notifier).decide(item, approve: true);
    expect(c.read(approvalsProvider).value!.items, isEmpty);
    expect(api.decisions, isEmpty, reason: 'still inside the undo window');
    expect(c.read(toastProvider)?.text, "Approved · Arun's leave");

    await pastWindow();
    expect(api.decisions, [('leave-7', true)]);
    expect(c.read(approvalsProvider).value!.items, isEmpty);
  });

  test('Undo inside the window brings it back and sends nothing', () async {
    final api = FakeApi();
    final c = container(api);
    await c.read(approvalsProvider.future);

    c.read(approvalsProvider.notifier).decide(item, approve: false);
    c.read(toastProvider)!.onUndo!();
    expect(c.read(approvalsProvider).value!.items, [item]);

    await pastWindow();
    expect(api.decisions, isEmpty);
  });

  test('a failed send puts the card back and says why', () async {
    final api = FakeApi(failWith: const ApiForbidden('Not your report.'));
    final c = container(api);
    await c.read(approvalsProvider.future);

    c.read(approvalsProvider.notifier).decide(item, approve: true);
    await pastWindow();

    expect(c.read(approvalsProvider).value!.items, [item]);
    expect(
      c.read(toastProvider)?.text,
      "Couldn't approve Arun's leave: Not your report.",
    );
  });

  test('deciding the same card twice sends it once', () async {
    final api = FakeApi();
    final c = container(api);
    await c.read(approvalsProvider.future);

    final controller = c.read(approvalsProvider.notifier);
    controller.decide(item, approve: true);
    controller.decide(item, approve: false);
    await pastWindow();

    expect(api.decisions, [('leave-7', true)]);
  });

  test('an employee has no queue and triggers no fetch', () async {
    final api = FakeApi();
    final c = container(api, role: 'employee');

    final inbox = await c.read(approvalsProvider.future);
    expect(inbox.items, isEmpty);
    expect(api.fetches, 0);
  });
}
