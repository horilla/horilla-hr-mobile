/// Every screen, at the text sizes people actually use.
///
/// The handoff's layouts are drawn at the default scale and lean on fixed
/// heights; a phone set to large text is where that shows. Flutter reports a
/// layout overflow as a framework exception during a test, so this pumps each
/// screen at increasing scales and fails on the first one that does not fit.
///
/// 1.3 is common. 2.0 is what someone who needs large text actually runs, and
/// is below the ~3.0 that iOS and Android both allow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/features/attendance/data/attendance_api.dart';
import 'package:horilla_mobile/features/attendance/ui/attendance_screen.dart';
import 'package:horilla_mobile/features/auth/ui/sign_in_screen.dart';
import 'package:horilla_mobile/features/employee/data/employee_api.dart';
import 'package:horilla_mobile/features/employee/data/employee_models.dart';
import 'package:horilla_mobile/features/employee/ui/directory_screen.dart';
import 'package:horilla_mobile/features/home/data/home_api.dart';
import 'package:horilla_mobile/features/home/data/home_models.dart';
import 'package:horilla_mobile/features/home/ui/home_screen.dart';
import 'package:horilla_mobile/features/leave/data/leave_api.dart';
import 'package:horilla_mobile/features/leave/ui/leave_screen.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';

import '../features/attendance/attendance_test.dart' as attendance;
import '../features/home/home_screen_test.dart' as home;
import '../features/leave/leave_screen_test.dart' as leave;
import 'package:horilla_mobile/features/punch/ui/punch_screen.dart';
import 'package:horilla_mobile/features/leave/ui/leave_apply_screen.dart';

const _scales = [1.0, 1.3, 2.0];

/// Takes a scope builder rather than a list of overrides: Riverpod's
/// `Override` type is not exported from either barrel, so it cannot be named
/// in a signature here.
Future<void> pumpScaled(
  WidgetTester tester, {
  required Widget screen,
  required double scale,
  ProviderScope Function(Widget child)? scope,
  String route = '/x',
}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final app = MaterialApp.router(
    theme: buildAppTheme(),
    localizationsDelegates: const [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    routerConfig: GoRouter(
      initialLocation: route,
      routes: [
        GoRoute(path: route, builder: (_, _) => screen),
        GoRoute(path: '/fallback', builder: (_, _) => const SizedBox()),
      ],
    ),
  );

  await tester.pumpWidget(scope?.call(app) ?? ProviderScope(child: app));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
}

void expectNoOverflow(WidgetTester tester, String label, double scale) {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: '$label overflowed at ${scale}x text scale: $exception',
  );
}

void main() {
  for (final scale in _scales) {
    group('at ${scale}x text scale', () {
      testWidgets('sign in fits', (tester) async {
        await pumpScaled(tester, screen: const SignInScreen(), scale: scale);
        expectNoOverflow(tester, 'Sign in', scale);
      });

      testWidgets('home fits', (tester) async {
        await pumpScaled(
          tester,
          screen: const HomeScreen(),
          scale: scale,
          route: '/home',
          scope: (child) => ProviderScope(
            overrides: [
              homeProvider.overrideWith((ref) async => home.sample()),
            ],
            child: child,
          ),
        );
        expectNoOverflow(tester, 'Home', scale);
      });

      testWidgets('home fits with a manager band and colleagues on leave', (
        tester,
      ) async {
        // The busiest home can be: every optional section present.
        await pumpScaled(
          tester,
          screen: const HomeScreen(),
          scale: scale,
          route: '/home',
          scope: (child) => ProviderScope(
            overrides: [
              homeProvider.overrideWith(
                (ref) async => home.sample(
                  role: 'manager',
                  unread: 12,
                  onLeave: const [
                    ColleagueOnLeave(id: 2, name: 'Arun Menon'),
                    ColleagueOnLeave(id: 3, name: 'Priya Nair'),
                  ],
                  announcement: const AnnouncementSummary(
                    id: 1,
                    title: 'Q3 review cycle opens on Monday',
                  ),
                ),
              ),
            ],
            child: child,
          ),
        );
        expectNoOverflow(tester, 'Home (full)', scale);
      });

      testWidgets('attendance fits', (tester) async {
        await pumpScaled(
          tester,
          screen: const AttendanceScreen(),
          scale: scale,
          route: '/time',
          scope: (child) => ProviderScope(
            overrides: [
              attendanceOverviewProvider.overrideWith(
                (ref) async => attendance.sample(),
              ),
            ],
            child: child,
          ),
        );
        expectNoOverflow(tester, 'Attendance', scale);
      });

      testWidgets('leave fits', (tester) async {
        await pumpScaled(
          tester,
          screen: const LeaveScreen(),
          scale: scale,
          route: '/time/leave',
          scope: (child) => ProviderScope(
            overrides: [
              leaveOverviewProvider.overrideWith((ref) async => leave.sample()),
            ],
            child: child,
          ),
        );
        expectNoOverflow(tester, 'Leave', scale);
      });

      testWidgets('applying for leave fits', (tester) async {
        // The calendar is a fixed seven columns; its cells cap their own
        // text scale, and everything around them must still reflow.
        await pumpScaled(
          tester,
          screen: const LeaveApplyScreen(),
          scale: scale,
          route: '/time/leave/apply',
          scope: (child) => ProviderScope(
            overrides: [
              leaveOverviewProvider.overrideWith((ref) async => leave.sample()),
            ],
            child: child,
          ),
        );
        expectNoOverflow(tester, 'Leave apply', scale);
      });

      for (final clockingIn in [false, true]) {
        testWidgets(
          '${clockingIn ? 'check-in' : 'check-out'} confirmation fits',
          (tester) async {
            await pumpScaled(
              tester,
              screen: PunchScreen(
                isClockingIn: clockingIn,
                // No fence, so no location service is needed to render.
                geofence: const GeofenceState(enabled: false),
                today: const TodayTotals(
                  worked: '06:42:02',
                  breakTime: '00:32:00',
                  overtime: '00:00:00',
                ),
                clockInTime: '09:02',
              ),
              scale: scale,
              route: '/punch',
            );
            expectNoOverflow(tester, 'Punch', scale);
          },
        );
      }

      testWidgets('the directory fits', (tester) async {
        await pumpScaled(
          tester,
          screen: const DirectoryScreen(),
          scale: scale,
          route: '/team',
          scope: (child) => ProviderScope(
            overrides: [
              directoryProvider.overrideWith(
                (ref) async => const [
                  DirectoryEntry(
                    id: 1,
                    firstName: 'Nisha',
                    lastName: 'Prakash',
                    jobPosition: 'Engineering manager',
                  ),
                  DirectoryEntry(
                    id: 2,
                    firstName: 'Arun',
                    lastName: 'Menon',
                    jobPosition: 'Senior engineer',
                  ),
                ],
              ),
            ],
            child: child,
          ),
        );
        expectNoOverflow(tester, 'Directory', scale);
      });
    });
  }
}
