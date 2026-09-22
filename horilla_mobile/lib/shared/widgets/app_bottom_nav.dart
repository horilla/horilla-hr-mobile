import 'package:flutter/material.dart';

import '../../core/theme/platform_chrome.dart';
import '../../core/theme/tokens.dart';

/// The five-tab bar, hand-built.
///
/// Not Material's NavigationBar: M3 applies a tonal surface tint to it, and
/// the two platforms want different active treatments -- iOS a 16x2.5 bar
/// under the label, Android a filled tonal pill behind the icon. Bending
/// NavigationBar into both is more work than drawing a Row.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: PlatformChrome.tabBarPadding,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavButton(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
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
    final color = selected ? AppColors.brandStrong : AppColors.ink4;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinHitTarget),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Android fills a tonal pill behind the icon; iOS does not.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.x12,
                  vertical: AppSpace.x4,
                ),
                decoration: BoxDecoration(
                  color: !PlatformChrome.isIOS && selected
                      ? AppColors.brandTint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Icon(item.icon, size: 20, color: color),
              ),
              const SizedBox(height: AppSpace.x4),
              Text(
                item.label,
                style: AppText.tabLabel.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              // iOS marks the active tab with a bar under the label.
              const SizedBox(height: 3),
              SizedBox(
                height: 2.5,
                width: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: PlatformChrome.isIOS && selected
                        ? AppColors.brandStrong
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
