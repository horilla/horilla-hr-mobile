/// The six values where the design differs by platform.
///
/// Referenced by three widgets only -- AppScaffold, AppBottomNav and the punch
/// button. Nothing else in the app knows what it is running on. The design
/// differs in values, not in structure, so forking widget trees per platform
/// would be a lot of duplication to express a handful of numbers.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'tokens.dart';

abstract final class PlatformChrome {
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// App bar padding, including room for the status bar.
  ///
  /// The handoff's iOS figure (56 top) already includes the status bar. On
  /// Android it does not -- the bar is in flow and the app has to add the
  /// inset itself, which is why this takes a context. Without it the greeting
  /// and avatar are drawn underneath the clock and signal icons, which is
  /// exactly what happened on a real device and what no browser preview
  /// would ever show.
  static EdgeInsets appBarPaddingOf(BuildContext context) {
    final statusBar = MediaQuery.paddingOf(context).top;
    return isIOS
        ? EdgeInsets.fromLTRB(20, statusBar + 12, 20, 14)
        : EdgeInsets.fromLTRB(18, statusBar + 12, 18, 12);
  }

  /// iOS leaves room for the home indicator.
  static EdgeInsets get tabBarPadding => isIOS
      ? const EdgeInsets.fromLTRB(8, 9, 8, 30)
      : const EdgeInsets.fromLTRB(8, 9, 8, 9);

  static double get cardRadius =>
      isIOS ? AppRadii.card : AppRadii.cardAndroid;

  /// Android's punch button is the one place the design uses a shadow.
  static List<BoxShadow> get punchButtonShadow =>
      isIOS ? const [] : AppElevation.punchButtonAndroid;
}
