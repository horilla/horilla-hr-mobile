/// Attendance: the hour-account arithmetic, and the screen's states.
///
/// The server sends durations as pre-formatted strings, so the parsing that
/// turns "160:30" into a progress bar is the part most likely to be quietly
/// wrong -- a bar at the wrong fill looks plausible and tells the user
/// something false about their month.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/features/attendance/data/attendance_api.dart';
import 'package:horilla_mobile/features/attendance/data/attendance_models.dart';
import 'package:horilla_mobile/features/attendance/ui/attendance_screen.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/shared/widgets/app_card.dart';

AttendanceOverview sample({
  HourAccount? account,
  List<AttendanceDay>? days,
}) =>
    AttendanceOverview(
      hourAccount: account ??
          const HourAccount(
            month: 'September',
            year: '2026',
            workedHours: '142:30',
            pendingHours: '17:30',
            overtime: '04:15',
          ),
      days: Paged<AttendanceDay>(
        results: days ??
            [
              AttendanceDay(
                id: 1,
                date: DateTime(2026, 9, 22),
                clockIn: '09:04',
                clockOut: '18:12',
                workedHour: '08:38',
              ),
              AttendanceDay(
                id: 2,
                date: DateTime(2026, 9, 21),
                clockIn: '09:11',
                workedHour: '03:12',
              ),
            ],
        count: 2,
      ),
    );

Future<void> pumpAttendance(
  WidgetTester tester, {
  required Future<AttendanceOverview> Function() load,
}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/time',
    routes: [
      GoRoute(path: '/time', builder: (_, _) => const AttendanceScreen()),
      GoRoute(path: '/requests', builder: (_, _) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        attendanceOverviewProvider.overrideWith((ref) => load()),
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
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('hour account arithmetic', () {
    test('progress is worked over worked-plus-pending', () {
      const account = HourAccount(
        month: 'September',
        year: '2026',
        workedHours: '80:00',
        pendingHours: '80:00',
        overtime: '00:00',
      );
      expect(account.progress, closeTo(0.5, 0.001));
      expect(account.expectedHours, '160h');
    });

    test('minutes are not dropped', () {
      // 90:30 of 90:30 + 9:30 = 100h exactly.
      const account = HourAccount(
        month: '',
        year: '',
        workedHours: '90:30',
        pendingHours: '09:30',
        overtime: '00:00',
      );
      expect(account.expectedHours, '100h');
      expect(account.progress, closeTo(0.905, 0.001));
    });

    test('progress is null rather than guessed when unparseable', () {
      // A bar drawn at a made-up value tells the user something false.
      const account = HourAccount(
        month: '',
        year: '',
        workedHours: 'not-a-duration',
        pendingHours: '10:00',
        overtime: '00:00',
      );
      expect(account.progress, isNull);
      expect(account.expectedHours, isNull);
    });

    test('progress is null when nothing is expected', () {
      expect(HourAccount.empty.progress, isNull);
    });

    test('progress never exceeds one', () {
      const account = HourAccount(
        month: '',
        year: '',
        workedHours: '200:00',
        pendingHours: '00:00',
        overtime: '40:00',
      );
      expect(account.progress, 1.0);
    });

    test('overtime is reported only when non-zero', () {
      expect(HourAccount.empty.hasOvertime, isFalse);
      expect(
        const HourAccount(
          month: '',
          year: '',
          workedHours: '0:00',
          pendingHours: '0:00',
          overtime: '04:15',
        ).hasOvertime,
        isTrue,
      );
    });
  });

  group('parsing', () {
    test('an attendance row without a date is discarded, not crashed on', () {
      expect(AttendanceDay.fromJson({'id': 1}), isNull);
      expect(AttendanceDay.fromJson('nonsense'), isNull);
    });

    test('an open row is one with a start and no end', () {
      final open = AttendanceDay.fromJson({
        'id': 1,
        'attendance_date': '2026-09-22',
        'attendance_clock_in': '09:04',
      });
      expect(open!.isOpen, isTrue);

      final closed = AttendanceDay.fromJson({
        'id': 2,
        'attendance_date': '2026-09-22',
        'attendance_clock_in': '09:04',
        'attendance_clock_out': '18:00',
      });
      expect(closed!.isOpen, isFalse);
    });

    test('empty strings are treated as absent, which DRF sends often', () {
      final day = AttendanceDay.fromJson({
        'id': 1,
        'attendance_date': '2026-09-22',
        'attendance_clock_in': '',
        'attendance_clock_out': '',
      });
      expect(day!.clockIn, isNull);
      expect(day.clockOut, isNull);
    });

    test('a page envelope reports whether more remain', () {
      final page = Paged.fromJson<AttendanceDay>(
        {'count': 40, 'next': 'http://x/?page=2', 'results': const []},
        AttendanceDay.fromJson,
      );
      expect(page.count, 40);
      expect(page.hasMore, isTrue);
    });
  });

  group('screen', () {
    testWidgets('renders the hour account and the log', (tester) async {
      await pumpAttendance(tester, load: () async => sample());

      expect(find.text('SEPTEMBER 2026'), findsOneWidget);
      expect(find.text('142:30'), findsOneWidget);
      expect(find.text('of 160h'), findsOneWidget);
      expect(find.text('+04:15 OT'), findsOneWidget);
      expect(find.text('09:04 – 18:12'), findsOneWidget);
    });

    testWidgets('an open day is marked rather than shown as finished',
        (tester) async {
      await pumpAttendance(tester, load: () async => sample());

      expect(find.text('09:11 – now'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('an empty log explains itself', (tester) async {
      await pumpAttendance(tester, load: () async => sample(days: []));

      expect(find.text('NOTHING YET'), findsOneWidget);
    });

    testWidgets('a first load shows skeletons', (tester) async {
      final pending = Completer<AttendanceOverview>();
      addTearDown(() => pending.complete(sample()));

      await pumpAttendance(tester, load: () => pending.future);

      expect(find.byType(AppCard), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failure is explained and retryable', (tester) async {
      await pumpAttendance(
        tester,
        load: () async => throw const ApiNetwork('No connection.'),
      );
      await tester.pump();

      expect(find.text('COULD NOT LOAD'), findsOneWidget);
      expect(find.text('Tap to try again'), findsOneWidget);
    });
  });
}
