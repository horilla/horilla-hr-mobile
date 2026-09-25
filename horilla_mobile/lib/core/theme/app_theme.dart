/// Minimal ThemeData.
///
/// The app draws its own surfaces, so this exists only so the stock widgets
/// that *do* appear -- text fields, dialogs, selection handles, ripples --
/// do not look off-brand.
///
/// Material 3 is deliberately left on but routed around: M3 applies tonal
/// elevation tints to Card, Dialog, BottomSheet and NavigationBar, and this
/// design is flat-with-borders. The app never uses Material's `Card` or
/// `NavigationBar`; `AppCard` is a Container with a border, and the tab bar is
/// hand-built. Fighting M3's tinting through theming is more work than not
/// using the two widgets that apply it.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandStrong,
    primary: AppColors.brandStrong,
    surface: AppColors.surface,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'PlusJakartaSans',
    scaffoldBackgroundColor: AppColors.bg,
    // The design has no ink-splash language; presses are expressed as border
    // and fill changes on the components themselves.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.brandStrong,
      selectionHandleColor: AppColors.brandStrong,
    ),
  );
}
