/// Where the design still differs by platform.
///
/// v1 differed in six values (tab bar treatment, card radii, the Android
/// punch-button shadow). v2 unified the chrome -- one floating tab bar, one
/// card style -- so what is left here is the one thing that is genuinely a
/// platform fact rather than a design choice: where the system bars sit.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract final class PlatformChrome {
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// App bar padding, including room for the status bar.
  ///
  /// Takes a context because on Android the status bar is in flow and the
  /// app has to add the inset itself. Without it the title is drawn under the
  /// clock and signal icons -- which is what happened on a real device, and
  /// what no browser preview of the handoff would ever show.
  static EdgeInsets appBarPaddingOf(BuildContext context) {
    final statusBar = MediaQuery.paddingOf(context).top;
    return EdgeInsets.fromLTRB(20, statusBar + 12, 20, 10);
  }

  /// Space under the floating tab bar: the home indicator on iOS, the
  /// gesture bar on Android, and never less than a finger's clearance.
  static double tabBarBottomOf(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return inset > 0 ? inset + 6 : 16;
  }
}
