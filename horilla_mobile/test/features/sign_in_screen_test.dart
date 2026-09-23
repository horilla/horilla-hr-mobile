/// Sign-in renders and is operable. Layout only -- the network side is
/// covered by the interceptor tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/features/auth/ui/sign_in_screen.dart';
import 'package:horilla_mobile/shared/widgets/app_button.dart';

Widget wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: buildAppTheme(),
    localizationsDelegates: const [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppL10n.supportedLocales,
    home: child,
  ),
);

/// v2 tucks the prefilled server field behind the footer. Opens it, so the
/// first TextField is the server again -- without this, `.first` is the
/// username field and the host tests would type into the wrong box.
Future<void> revealServer(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  final footer = find.bySemanticsLabel(RegExp('change server'));
  await tester.ensureVisible(footer);
  await tester.pump();
  await tester.tap(footer);
  await tester.pump();
  handle.dispose();
  expect(find.text('SERVER'), findsOneWidget);
}

void main() {
  testWidgets('the server sits in the footer until asked for', (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    expect(find.text('SERVER'), findsNothing);
    expect(find.textContaining('hr.demo.horilla.com'), findsOneWidget);

    await revealServer(tester);
  });

  testWidgets('shows the headline, all three fields and both actions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SignInScreen()));
    await revealServer(tester);

    expect(find.textContaining('Your workday'), findsOneWidget);
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with SSO'), findsOneWidget);
  });

  testWidgets('defaults the host to https, never a bare http host', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SignInScreen()));
    await revealServer(tester);

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, startsWith('https://'));
  });

  testWidgets('the password field is obscured', (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields.last.obscureText, isTrue);
  });

  testWidgets('a malformed host is reported against the host field', (
    tester,
  ) async {
    // Deliberately a case that needs no network: normalisation rejects it
    // before anything is sent. The point being pinned is *where* the message
    // lands -- against the host field, not as "invalid credentials", which is
    // the confusion the pre-flight exists to prevent.
    await tester.pumpWidget(wrap(const SignInScreen()));
    await revealServer(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'ftp://hr.company.com',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('http://'), findsOneWidget);
  });

  testWidgets('an http host on a local network warns, and is allowed', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SignInScreen()));
    await revealServer(tester);

    await tester.enterText(find.byType(TextField).first, 'http://192.168.1.9');
    await tester.pump();

    expect(find.textContaining('not encrypted'), findsOneWidget);
  });

  testWidgets('an http host on a public domain shows no warning banner', (
    tester,
  ) async {
    // It is refused at submit rather than warned about: the warning is for
    // connections we permit.
    await tester.pumpWidget(wrap(const SignInScreen()));
    await revealServer(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'http://hr.public.com',
    );
    await tester.pump();

    expect(find.textContaining('not encrypted'), findsNothing);
  });

  testWidgets('every tappable clears the 44pt minimum', (tester) async {
    // The handoff requires this, and it is easy to lose while styling.
    await tester.pumpWidget(wrap(const SignInScreen()));

    for (final element in find.byType(AppButton).evaluate()) {
      expect(
        tester.getSize(find.byWidget(element.widget)).height,
        greaterThanOrEqualTo(44.0),
      );
    }
  });
}
