import 'package:flutter/material.dart';

import '../../core/theme/platform_chrome.dart';
import '../../core/theme/tokens.dart';
import 'pressable.dart';

/// The v2 floating tab bar: a dark pill hovering above the content.
///
/// The active tab grows (1.9x the others), fills red and shows its label;
/// the rest are icon-only. Hand-built rather than Material's NavigationBar,
/// which has neither a floating form nor variable-width items.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<AppNavItem> items;

  static const _gap = 4.0;
  static const _activeFlex = 1.9;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        PlatformChrome.tabBarBottomOf(context),
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(25),
          boxShadow: AppShadows.tabBar,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Widths are computed rather than Expanded(flex:) because flex is
            // an int and cannot animate; the handoff eases the width change
            // over 280 ms.
            final n = items.length;
            final active = currentIndex >= 0 && currentIndex < n;
            final unit = active
                ? (constraints.maxWidth - _gap * (n - 1)) /
                      (n - 1 + _activeFlex)
                : (constraints.maxWidth - _gap * (n - 1)) / n;
            return Row(
              children: [
                for (var i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: const Cubic(0.2, 0.8, 0.2, 1),
                    width: i == currentIndex ? unit * _activeFlex : unit,
                    child: _NavButton(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => onSelected(i),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class AppNavItem {
  const AppNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.surface : AppColors.ink4;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      // The label is authoritative. Inactive tabs show no text at all, so
      // without this a screen reader would find four unlabelled icons.
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: const Cubic(0.2, 0.8, 0.2, 1),
          height: 50,
          decoration: BoxDecoration(
            // brandStrong, not the prototype's lighter brand red: the label
            // is 12.5pt white text, which needs 4.5:1 and #E54F38 gives 3.8.
            color: selected ? AppColors.brandStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 20, color: fg),
              if (selected) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // Capped: at 2x text the label would otherwise push the
                    // icon out of a pill whose width is fixed by the row.
                    textScaler: MediaQuery.textScalerOf(
                      context,
                    ).clamp(maxScaleFactor: 1.3),
                    style: AppText.tabLabel.copyWith(
                      color: AppColors.surface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
