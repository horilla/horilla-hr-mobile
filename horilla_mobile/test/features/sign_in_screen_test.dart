/// Sign-in renders and is operable. Layout only -- the network side is
/// covered by the interceptor tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/features/auth/ui/sign_in_screen.dart';
import 'package:horilla_mobile/shared/widgets/app_button.dart';

Widget wrap(Widget child) => MaterialApp(theme: buildAppTheme(), home: child);

void main() {
  testWidgets('shows the headline, all three fields and both actions',
      (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    expect(find.textContaining('Your workday'), findsOneWidget);
    expect(find.text('SERVER'), findsOneWidget);
    expect(find.text('USERNAME'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Continue with SSO'), findsOneWidget);
  });

  testWidgets('defaults the host to https, never a bare http host',
      (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, startsWith('https://'));
  });

  testWidgets('the password field is obscured', (tester) async {
    await tester.pumpWidget(wrap(const SignInScreen()));

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.last.obscureText, isTrue);
  });

  testWidgets('sign in is wired to its callback', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(SignInScreen(onSignedIn: () => tapped++)));

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
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
