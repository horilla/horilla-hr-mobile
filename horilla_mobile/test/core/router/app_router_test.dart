/// Navigation structure.
///
/// The rule worth pinning is the handoff's: tabs are active-*group* based,
/// not screen based. A pushed detail screen must keep its tab lit and must
/// keep the tab bar visible, while the three tab-bar-hidden screens must not
/// show it at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/router/app_router.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/core/scope.dart';
import 'package:horilla_mobile/features/shell/ui/app_shell.dart';
import 'package:horilla_mobile/shared/widgets/app_bottom_nav.dart';

/// Note: pump() rather than pumpAndSettle().
///
/// Skeleton placeholders animate on a repeating controller, which by
/// definition never settles -- pumpAndSettle would hang until it timed out.
/// Pumping a fixed number of frames is enough to let routing resolve.
Future<void> pumpAt(WidgetTester tester, String location) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: buildAppTheme(),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        routerConfig: buildRouter(initialLocation: location),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('sign-in has no tab bar', (tester) async {
    await pumpAt(tester, '/signin');
    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('punch has no tab bar', (tester) async {
    // Outside the shell by design, so there is nothing to hide.
    await pumpAt(tester, '/punch');
    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('the tab bar shows exactly the enabled modules', (tester) async {
    // Scope is narrowed to attendance, leave and employee management, so the
    // bar must not advertise modules this build cannot open. Driven from
    // Modules rather than hardcoded, so flipping a flag updates the test with
    // the app instead of against it.
    await pumpAt(tester, '/home');

    expect(find.byType(AppBottomNav), findsOneWidget);

    for (final branch in AppShell.branches) {
      final label = find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text(branch.label),
      );
      expect(
        label,
        branch.enabled ? findsOneWidget : findsNothing,
        reason: '${branch.label} enabled=${branch.enabled}',
      );
    }
  });

  testWidgets('a switched-off module is not reachable by tab', (tester) async {
    await pumpAt(tester, '/home');

    expect(Modules.requests, isFalse, reason: 'guards the assertion below');
    expect(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Requests'),
      ),
      findsNothing,
    );
  });

  testWidgets('deep-linking into a switched-off module explains itself',
      (tester) async {
    // A push notification from a server whose modules do not match the app is
    // exactly how someone lands here; it must not be a blank screen.
    await pumpAt(tester, '/requests');

    expect(find.text('NOT AVAILABLE YET'), findsOneWidget);
  });

  testWidgets('a detail screen inside a branch keeps its tab bar',
      (tester) async {
    // /time/leave is a child of the Time branch. The handoff's rule is that
    // this keeps Time selected rather than looking like a separate screen.
    await pumpAt(tester, '/time/leave');

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Leave'), findsWidgets);
  });

  testWidgets('tapping a tab switches branch', (tester) async {
    await pumpAt(tester, '/home');

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Time'),
      ),
    );
    await settleRoute(tester);

    expect(find.text('Attendance'), findsWidgets);
  });
}
