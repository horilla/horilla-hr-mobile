import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';

/// The logo mark: a squircle with a brand "H".
///
/// Placeholder by design intent -- the handoff bundles no logo file and says
/// to use the official asset in production. Kept as one widget so swapping it
/// is a single edit.
class HorillaMark extends StatelessWidget {
  const HorillaMark({super.key, this.size = 54, this.onDark = true});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? AppColors.surface : AppColors.brand,
        borderRadius: BorderRadius.circular(size * (16 / 54)),
      ),
      alignment: Alignment.center,
      child: Text(
        'H',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: size * (28 / 54),
          fontWeight: FontWeight.w800,
          color: onDark ? AppColors.brand : AppColors.surface,
          height: 1,
        ),
      ),
    );
  }
}
