import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';

/// The official Horilla mark: the gorilla on a brand-red disc.
///
/// v1 of the handoff shipped no logo, so this was a lettered placeholder; v2
/// bundles the real asset (`Assets/horilla-logo.png`). Kept as one widget so
/// the next asset change is still one edit.
class HorillaMark extends StatelessWidget {
  const HorillaMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'Assets/horilla-logo.png',
      width: size,
      // The artwork is taller than wide (1090 x 1150); fixing only the width
      // keeps its proportions.
      fit: BoxFit.contain,
      semanticLabel: 'Horilla',
    );
  }
}

/// Mark plus the "horilla" wordmark, as on the sign-in screen.
class HorillaLockup extends StatelessWidget {
  const HorillaLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Horilla',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HorillaMark(size: 52),
          const SizedBox(width: AppSpace.x12),
          // Fixed size: the wordmark is artwork, not reading text, and at 2x
          // it ran 72pt off the screen. The name is in the label above.
          MediaQuery.withNoTextScaling(
            child: Text(
              'horilla',
              style: AppText.appBarTitle.copyWith(
                fontSize: 26,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 40pt white tile holding the mark, used at the top of Home.
class HorillaMarkTile extends StatelessWidget {
  const HorillaMarkTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.floating,
      ),
      alignment: Alignment.center,
      child: const HorillaMark(size: 28),
    );
  }
}
