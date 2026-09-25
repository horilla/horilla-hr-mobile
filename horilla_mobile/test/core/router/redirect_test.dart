/// Route guarding.
///
/// Two rules: nothing but sign-in is reachable without a session, and a
/// signed-in user is never left sitting on the sign-in screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/router/app_router.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/shared/widgets/app_bottom_nav.dart';

Future<GoRouterHarness> pump(
  WidgetTester tester, {
  required bool signedIn,
  required String at,
}) async {
  final notifier = ValueNotifier<int>(0);
  var isSignedIn = signedIn;

  final router = buildRouter(
    initialLocation: at,
    isSignedIn: () => isSignedIn,
    refreshOn: notifier,
  );

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
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  return GoRouterHarness(
    router: router,
    setSignedIn: (value) {
      isSignedIn = value;
      notifier.value++;
    },
  );
}

class GoRouterHarness {
  GoRouterHarness({required this.router, required this.setSignedIn});
  final dynamic router;
  final void Function(bool) setSignedIn;
}

void main() {
  testWidgets('a protected route redirects to sign-in when signed out', (
    tester,
  ) async {
    await pump(tester, signedIn: false, at: '/home');

    expect(find.textContaining('Your workday'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('a signed-in user is moved off sign-in', (tester) async {
    await pump(tester, signedIn: true, at: '/signin');

    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('a signed-in user reaches a protected route', (tester) async {
    await pump(tester, signedIn: true, at: '/home');

    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('losing the session mid-use bounces to sign-in', (tester) async {
    // A refresh token that no longer works signs the user out from wherever
    // they are; they must not be left on a screen that can no longer load.
    final harness = await pump(tester, signedIn: true, at: '/home');
    expect(find.byType(AppBottomNav), findsOneWidget);

    harness.setSignedIn(false);
    // Long enough for the page transition to complete. pumpAndSettle is not
    // usable here: skeleton placeholders animate forever, so it would time
    // out rather than settle.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.textContaining('Your workday'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
  });
}
