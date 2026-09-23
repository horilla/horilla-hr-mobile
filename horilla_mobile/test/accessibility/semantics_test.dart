/// What a screen reader hears, and what a finger can hit.
///
/// Icon-only controls are the risk: they read as nothing at all to anyone not
/// looking at the screen, and this app has several (back chevrons, the
/// notification bell, the punch shortcut, tab items).
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/theme/app_theme.dart';
import 'package:horilla_mobile/core/theme/tokens.dart';
import 'package:horilla_mobile/l10n/app_localizations.dart';
import 'package:horilla_mobile/shared/widgets/app_bottom_nav.dart';
import 'package:horilla_mobile/shared/widgets/app_button.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the tab bar announces each tab and which is selected', (
    tester,
  ) async {
    await pump(
      tester,
      AppBottomNav(
        currentIndex: 1,
        onSelected: (_) {},
        items: const [
          AppNavItem(label: 'Home', icon: Icons.home_outlined),
          AppNavItem(label: 'Time', icon: Icons.schedule_outlined),
        ],
      ),
    );

    final handle = tester.ensureSemantics();

    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Time'), findsOneWidget);

    // Selection has to reach a screen reader too -- a coloured underline is
    // not information if you cannot see it.
    final selected = tester.getSemantics(find.bySemanticsLabel('Time'));
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);

    handle.dispose();
  });

  testWidgets('every tab clears the 44pt minimum', (tester) async {
    await pump(
      tester,
      AppBottomNav(
        currentIndex: 0,
        onSelected: (_) {},
        items: const [
          AppNavItem(label: 'Home', icon: Icons.home_outlined),
          AppNavItem(label: 'Time', icon: Icons.schedule_outlined),
          AppNavItem(label: 'Team', icon: Icons.group_outlined),
          AppNavItem(label: 'Me', icon: Icons.person_outline),
        ],
      ),
    );

    // Measured through the semantics node, which is the tappable area, and
    // in both dimensions: v2's inactive tabs are icon-only and narrower than
    // the active one, so width is now the constraint most likely to slip.
    final handle = tester.ensureSemantics();
    for (final label in ['Home', 'Time', 'Team', 'Me']) {
      final rect = tester.getRect(find.bySemanticsLabel(label));
      expect(
        rect.height,
        greaterThanOrEqualTo(kMinHitTarget),
        reason: '$label tab is only ${rect.height}pt tall',
      );
      expect(
        rect.width,
        greaterThanOrEqualTo(kMinHitTarget),
        reason: '$label tab is only ${rect.width}pt wide',
      );
    }
    handle.dispose();
  });

  testWidgets('a button announces its label and its disabled state', (
    tester,
  ) async {
    await pump(
      tester,
      const Column(
        children: [
          AppButton(label: 'Check out', onPressed: null),
          AppButton(label: 'Apply for leave'),
        ],
      ),
    );

    final handle = tester.ensureSemantics();

    final disabled = tester.getSemantics(find.bySemanticsLabel('Check out'));
    // Note: isButton is a plain bool while isSelected/isEnabled are Tristate.
    expect(disabled.flagsCollection.isButton, isTrue);
    expect(
      disabled.flagsCollection.isEnabled,
      isNot(Tristate.isTrue),
      reason: 'a greyed-out button must read as disabled, not just look it',
    );

    handle.dispose();
  });

  testWidgets('buttons clear the 44pt minimum even with short labels', (
    tester,
  ) async {
    await pump(tester, const AppButton(label: 'OK'));

    expect(
      tester.getSize(find.byType(AppButton)).height,
      greaterThanOrEqualTo(kMinHitTarget),
    );
  });
}
