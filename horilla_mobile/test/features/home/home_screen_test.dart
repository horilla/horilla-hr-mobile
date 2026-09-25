/// Home screen behaviour.
///
/// States matter more than pixels here: a first load shows skeletons rather
/// than a spinner, optional sections disappear when empty rather than leaving
/// a hole, and a failure is recoverable rather than a dead end.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';
import 'package:horilla_mobile/features/home/data/home_api.dart';
import 'package:horilla_mobile/features/home/data/home_models.dart';
import 'package:horilla_mobile/features/home/ui/home_screen.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/shared/widgets/app_card.dart';

HomeData sample({
  String role = 'employee',
  bool clockedIn = true,
  int unread = 0,
  List<ColleagueOnLeave> onLeave = const [],
  AnnouncementSummary? announcement,
  bool geofence = true,
}) {
  return HomeData(
    user: const SignedInUser(id: 1, fullName: 'Nisha Prakash'),
    capabilities: Capabilities(
      role: role,
      permissions: const {'view_team': true},
      features: const {'leave': true},
    ),
    punch: PunchState(isClockedIn: clockedIn, clockInTime: '09:04'),
    geofence: GeofenceState(enabled: geofence),
    today: const TodayTotals(
      worked: '03:12:40',
      breakTime: '00:30:00',
      overtime: '00:45:00',
    ),
    onLeaveToday: onLeave,
    unreadNotifications: unread,
    announcement: announcement,
  );
}

/// Renders at the size the design was drawn for.
///
/// The default 800x600 test surface is not a phone, and laying a phone screen
/// out in a landscape desktop window produces overflow warnings that say
/// nothing about the real product.
Future<void> pumpHome(
  WidgetTester tester, {
  required Future<HomeData> Function() load,
}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/punch', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/time', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/team', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/requests', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/me', builder: (_, _) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [homeProvider.overrideWith((ref) => load())],
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
  testWidgets('a first load shows skeletons, not a spinner', (tester) async {
    // The handoff is explicit: skeletons matching each card's geometry, never
    // a spinner over the whole screen.
    //
    // A Completer rather than Future.delayed, so the pending load does not
    // leave a live timer behind when the test tree is torn down.
    final pending = Completer<HomeData>();
    addTearDown(() => pending.complete(sample()));

    await pumpHome(tester, load: () => pending.future);

    expect(find.byType(AppCard), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders the punch card, stats and name', (tester) async {
    await pumpHome(tester, load: () async => sample());

    expect(find.text('Nisha Prakash'), findsOneWidget);
    // The hero counts worked time, from the server's figure at fetch.
    expect(find.text('Worked today'), findsOneWidget);
    expect(find.text('03:12:40'), findsOneWidget);
    expect(find.text('FIRST IN'), findsOneWidget);
    expect(find.text('09:04'), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);
    // No shift length from the server, so the ring says so.
    expect(find.textContaining('of 8h'), findsOneWidget);
  });

  testWidgets('clocked in offers Check out', (tester) async {
    await pumpHome(tester, load: () async => sample());
    expect(find.text('Check out'), findsOneWidget);
  });

  testWidgets('clocked out offers Check in', (tester) async {
    await pumpHome(tester, load: () async => sample(clockedIn: false));
    expect(find.text('Check in'), findsOneWidget);
    // Checked in earlier today (the sample has a first-in), now out.
    expect(find.text('Checked out'), findsOneWidget);
  });

  testWidgets('the geo-fence pill shows when the feature is on', (
    tester,
  ) async {
    await pumpHome(tester, load: () async => sample());
    expect(find.text('Geo-fenced site'), findsOneWidget);
  });

  testWidgets('the geo-fence pill is absent when the feature is off', (
    tester,
  ) async {
    // A pill that says nothing is worse than no pill.
    await pumpHome(tester, load: () async => sample(geofence: false));
    expect(find.text('Geo-fenced site'), findsNothing);
  });

  testWidgets('a plain employee gets no role band', (tester) async {
    await pumpHome(tester, load: () async => sample());
    expect(find.textContaining('need you'), findsNothing);
    expect(find.textContaining('HR desk'), findsNothing);
  });

  testWidgets('no band claims a count the server has not sent', (tester) async {
    // The band used to render "0 requests need you" for every manager: the
    // count was hard-wired. It stays hidden until the home aggregate carries
    // a real pending-approvals number.
    for (final role in ['manager', 'hrexec']) {
      await pumpHome(tester, load: () async => sample(role: role));
      expect(find.textContaining('need you'), findsNothing, reason: role);
      expect(find.textContaining('HR desk'), findsNothing, reason: role);
    }
  });

  testWidgets('optional sections are omitted when empty', (tester) async {
    await pumpHome(tester, load: () async => sample());

    expect(find.text('On leave today'), findsNothing);
    expect(find.text('ANNOUNCEMENT'), findsNothing);
  });

  testWidgets('on-leave and announcement render when present', (tester) async {
    await pumpHome(
      tester,
      load: () async => sample(
        onLeave: const [ColleagueOnLeave(id: 2, name: 'Arun Menon')],
        announcement: const AnnouncementSummary(id: 1, title: 'Q3 opens'),
      ),
    );

    expect(find.text('On leave today'), findsOneWidget);
    expect(find.text('1 person →'), findsOneWidget);
    expect(find.text('Q3 opens'), findsOneWidget);
  });

  testWidgets('a failure is explained and retryable', (tester) async {
    await pumpHome(
      tester,
      load: () async => throw const ApiNetwork('No connection.'),
    );
    // The rejection resolves a microtask later than the first frame.
    await tester.pump();

    expect(find.text('COULD NOT LOAD'), findsOneWidget);
    expect(find.text('No connection.'), findsOneWidget);
    expect(find.text('Tap to try again'), findsOneWidget);
  });

  testWidgets('with no unread, the bell is announced plainly', (tester) async {
    await pumpHome(tester, load: () async => sample());
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
  });

  test('home employee block is read from name and avatar', () {
    final user = SignedInUser.fromJson({
      'id': 4,
      'name': 'Adam Admin',
      'avatar': '/media/adam.png',
    });
    expect(user.fullName, 'Adam Admin');
    expect(user.avatarUrl, '/media/adam.png');
  });

  test('login employee block still uses full_name', () {
    final user = SignedInUser.fromJson({
      'id': 4,
      'full_name': 'Adam Admin',
      'name': 'ignored when login sends both',
      'employee_profile': '/media/adam.png',
    });
    expect(user.fullName, 'Adam Admin');
    expect(user.avatarUrl, '/media/adam.png');
  });

  testWidgets('unread count is announced to screen readers', (tester) async {
    // The dot is the visual signal; the count has to reach anyone not
    // looking at it.
    await pumpHome(tester, load: () async => sample(unread: 7));
    expect(find.bySemanticsLabel('Notifications, 7 unread'), findsOneWidget);
  });
}
