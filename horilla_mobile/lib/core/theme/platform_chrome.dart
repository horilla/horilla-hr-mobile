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

  /// iOS carries the status bar in its own padding; on Android it is in flow.
  static EdgeInsets get appBarPadding => isIOS
      ? const EdgeInsets.fromLTRB(20, 56, 20, 14)
      : const EdgeInsets.fromLTRB(18, 12, 18, 12);

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
