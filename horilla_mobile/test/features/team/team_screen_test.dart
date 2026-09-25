/// The Team tab: a manager's team, or the directory for everyone else.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horilla_mobile/core/auth/session.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/features/approvals/data/approval_models.dart';
import 'package:horilla_mobile/features/approvals/data/approvals_controller.dart';
import 'package:horilla_mobile/features/auth/data/auth_models.dart';
import 'package:horilla_mobile/features/employee/data/employee_api.dart';
import 'package:horilla_mobile/features/team/data/team_api.dart';
import 'package:horilla_mobile/features/team/data/team_models.dart';
import 'package:horilla_mobile/features/team/ui/team_screen.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';

class _Session extends SessionController {
  _Session(this.role);

  final String role;

  @override
  Session? build() => Session(
    host: 'https://hr.example.test',
    user: const SignedInUser(id: 1, fullName: 'Nisha Prakash'),
    capabilities: Capabilities(
      role: role,
      permissions: const {},
      features: const {},
    ),
    isCleartext: false,
    geoFencingEnabled: false,
    faceDetectionEnabled: false,
  );
}

class _NoApprovals extends ApprovalsController {
  @override
  Future<ApprovalInbox> build() async => ApprovalInbox.empty;
}

final sampleTeam = TeamToday.build(
  reports: {10: 'Designer', 11: 'Engineer', 12: null},
  names: {10: 'Priya Nair', 11: 'Arun Menon', 12: 'David Cole'},
  clockIns: {10: '09:04'},
  leaves: [
    TeamLeave(
      employeeId: 11,
      name: 'Arun Menon',
      start: DateTime.now(),
      end: DateTime.now(),
      type: 'Casual Leave',
    ),
  ],
  today: DateTime.now(),
);

Future<void> pumpTeam(WidgetTester tester, {required String role}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _Session(role)),
        teamTodayProvider.overrideWith((ref) async => sampleTeam),
        approvalsProvider.overrideWith(_NoApprovals.new),
        directoryProvider.overrideWith((ref) async => const []),
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
          initialLocation: '/team',
          routes: [GoRoute(path: '/team', builder: (_, _) => const TeamTab())],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('a manager sees their team today', (tester) async {
    await pumpTeam(tester, role: 'manager');

    expect(find.text('My team'), findsOneWidget);
    expect(find.text('Priya Nair'), findsOneWidget);
    expect(find.text('09:04'), findsOneWidget);
    expect(find.text('Casual Leave'), findsOneWidget);
    expect(find.textContaining('Leave clash'), findsOneWidget);
  });

  testWidgets('an employee gets the directory, not a team', (tester) async {
    await pumpTeam(tester, role: 'employee');

    expect(find.text('My team'), findsNothing);
    expect(find.text('Priya Nair'), findsNothing);
  });
}
