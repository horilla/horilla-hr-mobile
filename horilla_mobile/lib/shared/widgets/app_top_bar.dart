import 'package:flutter/material.dart';

import '../../core/theme/platform_chrome.dart';
import '../../core/theme/tokens.dart';
import 'pressable.dart';

/// The v2 app bar: no surface, no divider -- it blends into the screen
/// background and the heavy title does the separating.
///
/// Every screen used to build this row by hand; one widget means the next
/// design pass is one edit, not fourteen.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.subtitle,
    this.onDark = false,
  });

  final String title;

  /// Shows the circular back button when set.
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Mono sub-line under the title, for context such as a reference number.
  final String? subtitle;

  /// For full-bleed ink screens (the punch confirmation).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? AppColors.surface : AppColors.ink;

    return Padding(
      padding: PlatformChrome.appBarPaddingOf(context),
      child: Row(
        children: [
          if (onBack != null) ...[
            CircleBackButton(onTap: onBack!),
            const SizedBox(width: AppSpace.x10),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.appBarTitle.copyWith(color: titleColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.mono.copyWith(
                        fontSize: 11,
                        color: onDark ? AppColors.onDark2 : AppColors.ink3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.x10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// 40pt white circle with a soft shadow, inside a 44pt hit target.
///
/// The drawn circle is the handoff's 40; the tappable area is not allowed to
/// be smaller than [kMinHitTarget], so the extra two points each side are
/// transparent.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: kMinHitTarget,
          height: kMinHitTarget,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadows.floating,
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 19,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A brand-coloured text action for the app bar's trailing slot
/// ("Edit", "Mark read").
class TopBarAction extends StatelessWidget {
  const TopBarAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinHitTarget),
          child: Center(
            child: Text(
              label,
              style: AppText.cardTitle.copyWith(
                color: AppColors.brandStrong,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
