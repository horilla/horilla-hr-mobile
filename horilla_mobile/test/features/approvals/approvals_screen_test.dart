/// The approvals screen: cards, filters, one-tap decisions, the empty state.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horilla_mobile/core/auth/session.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/features/approvals/data/approval_models.dart';
import 'package:horilla_mobile/features/approvals/data/approvals_api.dart';
import 'package:horilla_mobile/features/approvals/ui/approvals_screen.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/shared/widgets/toast.dart';

const leaveItem = ApprovalItem(
  kind: ApprovalKind.leave,
  id: 1,
  employeeId: 13,
  name: 'Arun Menon',
  ask: 'Casual Leave · 2 Oct · 1 day',
  warning: 'Overlaps 1 approved leave in the team.',
);

const fixItem = ApprovalItem(
  kind: ApprovalKind.attendance,
  id: 2,
  employeeId: 14,
  name: 'Priya Nair',
  ask: 'Correction for 23 Sep · 08:51–18:51',
  canReject: false,
);

class FakeApprovalsApi extends ApprovalsApi {
  FakeApprovalsApi(this.items) : super(Dio());

  final List<ApprovalItem> items;
  final sent = <String>[];

  @override
  Future<ApprovalInbox> fetchInbox({
    required int selfId,
    String? currencySymbol,
  }) async => ApprovalInbox(items);

  @override
  Future<void> decide(ApprovalItem item, {required bool approve}) async =>
      sent.add(item.key);
}

class _Manager extends SessionController {
  @override
  Session? build() => const Session(
    host: 'https://hr.example.test',
    user: SignedInUser(id: 1, fullName: 'Nisha Prakash'),
    capabilities: Capabilities(role: 'manager', permissions: {}, features: {}),
    isCleartext: false,
    geoFencingEnabled: false,
    faceDetectionEnabled: false,
  );
}

Future<FakeApprovalsApi> pump(WidgetTester tester, List<ApprovalItem> items) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final api = FakeApprovalsApi(items);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(_Manager.new),
        approvalsApiProvider.overrideWithValue(api),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: '/team/approvals',
          routes: [
            GoRoute(path: '/team', builder: (_, _) => const SizedBox()),
            GoRoute(
              path: '/team/approvals',
              builder: (_, _) => const ApprovalsScreen(),
            ),
          ],
        ),
        builder: (context, child) => ToastHost(child: child!),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return api;
}

void main() {
  testWidgets('shows each request with its ask, warning and counts', (
    tester,
  ) async {
    await pump(tester, [leaveItem, fixItem]);

    expect(find.text('2 PENDING'), findsOneWidget); // StatusChip uppercases
    expect(find.text('All · 2'), findsOneWidget);
    expect(find.text('Leave · 1'), findsOneWidget);
    expect(find.text('Arun Menon'), findsOneWidget);
    expect(find.text('Casual Leave · 2 Oct · 1 day'), findsOneWidget);
    expect(find.text('Overlaps 1 approved leave in the team.'), findsOneWidget);
  });

  testWidgets('an approve-only kind says where Reject went', (tester) async {
    await pump(tester, [fixItem]);

    expect(find.text('Reject'), findsNothing);
    expect(
      find.text('To reject this one, use the Horilla web app.'),
      findsOneWidget,
    );
  });

  testWidgets('a filter narrows the list', (tester) async {
    await pump(tester, [leaveItem, fixItem]);

    await tester.tap(find.text('Attendance · 1'));
    await tester.pump();
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('Arun Menon'), findsNothing);
  });

  testWidgets('Approve removes the card at once, offers Undo, then sends', (
    tester,
  ) async {
    final api = await pump(tester, [leaveItem]);

    await tester.tap(find.text('Approve'));
    await tester.pump();
    expect(find.text('Arun Menon'), findsNothing);
    expect(find.text('All caught up'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(api.sent, isEmpty);

    await tester.pump(ToastController.visibleFor);
    await tester.pump();
    expect(api.sent, ['leave-1']);
  });

  testWidgets('Undo puts the card back and sends nothing', (tester) async {
    final api = await pump(tester, [leaveItem]);

    await tester.tap(find.text('Reject'));
    await tester.pump();
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.text('Arun Menon'), findsOneWidget);

    await tester.pump(ToastController.visibleFor);
    expect(api.sent, isEmpty);
  });

  testWidgets('nothing pending is said plainly', (tester) async {
    await pump(tester, const []);
    expect(find.text('All caught up'), findsOneWidget);
    expect(
      find.textContaining(RegExp('pending', caseSensitive: false)),
      findsNothing,
    );
  });
}
