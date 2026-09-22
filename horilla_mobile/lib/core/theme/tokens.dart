/// Design tokens, transcribed from the Horilla Mobile design handoff.
///
/// Plain `static const` rather than a ThemeExtension: there is one brand and
/// no dark mode, so the only thing an extension would buy -- swapping token
/// *values* at runtime -- buys nothing, while costing
/// `Theme.of(context).extension<..>()!` at every call site. If dark mode is
/// ever specified this becomes a find-and-replace, which is a fair trade for
/// not threading `context` through every widget that needs a colour.
library;

import 'package:flutter/widgets.dart';

/// Horilla brand palette.
///
/// Contrast note from the handoff, worth keeping next to the values: `brand`
/// (#E54F38) is about 3.8:1 on white, so it is for large or graphic elements
/// only. Small text and button fills use [brandStrong].
abstract final class AppColors {
  static const brand = Color(0xFFE54F38); // Cinnabar; logo, large accents
  static const brandStrong = Color(0xFFC43D28); // fills, accent text (4.5:1+)
  static const brandPressed = Color(0xFFA83320);
  static const brandTint = Color(0xFFFDECE8);
  static const brandTintBorder = Color(0xFFF6CFC7);
  static const brandTintInk = Color(0xFF7A2415);

  static const ink = Color(0xFF1C1C1C); // primary text; dark hero surfaces
  static const ink2 = Color(0xFF444442); // secondary body
  static const ink3 = Color(0xFF5E5E5C); // labels, meta
  static const ink4 = Color(0xFF9B9B99); // muted meta, mono captions
  static const onDark2 = Color(0xFFB5B5B3); // secondary text on ink surfaces

  static const surface = Color(0xFFFFFFFF); // cards, app bars, tab bar
  static const bg = Color(0xFFF7F7F6); // screen background
  static const bg2 = Color(0xFFF2F2F1); // inset fields, quiet blocks

  static const line = Color(0xFFE4E4E2); // card borders
  static const line2 = Color(0xFFEFEFEE); // row dividers inside cards
  static const line3 = Color(0xFFD2D2D0); // dashed / attachment borders

  static const success = Color(0xFF1E7A54);
  static const successDot = Color(0xFF4CAF7D);
  static const warning = Color(0xFF9A6B12);
  static const warningBg = Color(0xFFFAF0DC);
  static const warningBorder = Color(0xFFEFDCB4);
  static const warningInk = Color(0xFF7A5410);
  static const danger = Color(0xFF8E2E22);
  static const dangerPressed = Color(0xFF73241B);
  static const dangerBg = Color(0xFFF7E4E0);
  static const dangerBorder = Color(0xFFE8BDB4);
  static const info = Color(0xFF2A5E8C);
  static const infoBg = Color(0xFFE6EEF5);
  static const infoBorder = Color(0xFFC9DBEA);
  static const infoInk = Color(0xFF1F4C74);

  /// Read status dot on the notifications screen.
  static const readDot = Color(0xFFDEDEDC);
}

/// The handoff's spacing scale. Values outside it are a design question, not
/// an implementation one -- reach for the nearest step instead of inventing.
abstract final class AppSpace {
  static const x4 = 4.0;
  static const x6 = 6.0;
  static const x8 = 8.0;
  static const x10 = 10.0;
  static const x12 = 12.0;
  static const x14 = 14.0;
  static const x16 = 16.0;
  static const x18 = 18.0;
  static const x20 = 20.0;
  static const x28 = 28.0;

  /// Horizontal screen padding.
  static const screen = x16;

  /// Scroll bodies end with this much breathing room.
  static const scrollBottom = x28;
}

abstract final class AppRadii {
  static const chip = 20.0;
  static const pill = 9999.0;
  static const button = 14.0; // handoff range 13-16
  static const card = 18.0; // handoff range 16-18
  static const hero = 22.0; // handoff range 20-22
  static const cardAndroid = 24.0; // handoff range 20-28
  static const iconTile = 10.0; // handoff range 8-12
  static const avatar = 14.0; // squircle; handoff range 11-22
}

/// Type styles.
///
/// `PlusJakartaSans` for UI, `JetBrainsMono` for anything numeric, timestamped,
/// referenced or set in all-caps. Both are bundled -- see pubspec.
///
/// 10px is the floor in this product and is used only for mono eyebrow labels
/// and status chips.
abstract final class AppText {
  static const _ui = 'PlusJakartaSans';
  static const _mono = 'JetBrainsMono';

  /// 44/700 mono, tight. The punch clock, and nothing else.
  static const punchClock = TextStyle(
    fontFamily: _mono,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1,
  );

  /// Screen hero number, e.g. net pay.
  static const heroNumber = TextStyle(
    fontFamily: _mono,
    fontSize: 33,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  );

  static const statValue = TextStyle(
    fontFamily: _mono,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );

  static const appBarTitle = TextStyle(
    fontFamily: _ui,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const cardTitle = TextStyle(
    fontFamily: _ui,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  static const body = TextStyle(
    fontFamily: _ui,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const meta = TextStyle(
    fontFamily: _ui,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.ink3,
  );

  /// Uppercase mono section label.
  static const eyebrow = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: AppColors.ink4,
  );

  static const statusChip = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  static const tabLabel = TextStyle(
    fontFamily: _ui,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  /// General-purpose mono, for timestamps and references inline.
  static const mono = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

/// Flat by design: borders, not shadows. The Android punch button is the one
/// documented exception in the handoff.
abstract final class AppElevation {
  static const punchButtonAndroid = [
    BoxShadow(
      color: Color(0x40C43D28), // rgba(196,61,40,0.25)
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];
}

/// Minimum tappable size, in logical pixels. The handoff requires every
/// tappable row or button to clear this.
const double kMinHitTarget = 44;
