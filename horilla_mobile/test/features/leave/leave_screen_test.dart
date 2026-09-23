/// Leave screen rendering.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/features/leave/data/leave_api.dart';
import 'package:horilla_mobile/features/leave/data/leave_models.dart';
import 'package:horilla_mobile/features/leave/ui/leave_screen.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/shared/widgets/app_card.dart';

LeaveOverview sample({
  List<LeaveBalance>? balances,
  List<LeaveRequestSummary>? requests,
  List<Holiday>? holidays,
}) => LeaveOverview(
  balances:
      balances ??
      const [
        LeaveBalance(
          id: 1,
          type: LeaveType(id: 1, name: 'Casual'),
          availableDays: 6.5,
          carryforwardDays: 2,
        ),
        LeaveBalance(
          id: 2,
          type: LeaveType(id: 2, name: 'Sick'),
          availableDays: 4,
          carryforwardDays: 0,
        ),
      ],
  requests:
      requests ??
      [
        LeaveRequestSummary(
          id: 1,
          type: const LeaveType(id: 1, name: 'Casual'),
          startDate: DateTime(2026, 10, 2),
          endDate: DateTime(2026, 10, 3),
          status: LeaveStatus.requested,
          requestedDays: 2,
        ),
        LeaveRequestSummary(
          id: 2,
          type: const LeaveType(id: 2, name: 'Sick'),
          startDate: DateTime(2026, 9, 10),
          status: LeaveStatus.approved,
          requestedDays: 1,
        ),
      ],
  holidays:
      holidays ??
      [Holiday(id: 1, name: 'Onam', startDate: DateTime(2026, 9, 24))],
);

Future<void> pumpLeave(
  WidgetTester tester, {
  required Future<LeaveOverview> Function() load,
}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/time/leave',
    routes: [
      GoRoute(path: '/time', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/time/leave', builder: (_, _) => const LeaveScreen()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [leaveOverviewProvider.overrideWith((ref) => load())],
      child: MaterialApp.router(
        theme: buildAppTheme(),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('shows balances, requests and holidays', (tester) async {
    await pumpLeave(tester, load: () async => sample());

    expect(find.text('8.5'), findsOneWidget); // 6.5 available + 2 carried
    expect(find.text('Casual'), findsWidgets);
    expect(find.text('4'), findsOneWidget); // whole numbers lose the .0
    expect(find.text('Onam'), findsOneWidget);
  });

  testWidgets('a status is shown per request, in its own tone', (tester) async {
    await pumpLeave(tester, load: () async => sample());

    expect(find.text('PENDING'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
  });

  testWidgets('a single-day request shows one date, not a range', (
    tester,
  ) async {
    await pumpLeave(tester, load: () async => sample());

    expect(find.text('2 Oct – 3 Oct · 2 days'), findsOneWidget);
    expect(find.text('10 Sep · 1 day'), findsOneWidget);
  });

  testWidgets('no balances is explained rather than left blank', (
    tester,
  ) async {
    await pumpLeave(tester, load: () async => sample(balances: []));

    expect(find.text('NO LEAVE ASSIGNED'), findsOneWidget);
  });

  testWidgets('no requests is explained', (tester) async {
    await pumpLeave(tester, load: () async => sample(requests: []));

    expect(find.text('You have not requested any leave.'), findsOneWidget);
  });

  testWidgets('the holidays section disappears when there are none', (
    tester,
  ) async {
    await pumpLeave(tester, load: () async => sample(holidays: []));

    expect(find.text('Upcoming holidays'), findsNothing);
  });

  testWidgets('a first load shows skeletons', (tester) async {
    final pending = Completer<LeaveOverview>();
    addTearDown(() => pending.complete(sample()));

    await pumpLeave(tester, load: () => pending.future);

    expect(find.byType(AppCard), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failure is explained and retryable', (tester) async {
    await pumpLeave(
      tester,
      load: () async => throw const ApiNetwork('No connection.'),
    );
    await tester.pump();

    expect(find.text('COULD NOT LOAD'), findsOneWidget);
    expect(find.text('Tap to try again'), findsOneWidget);
  });
}
