import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'pressable.dart';

/// Filled, outlined and text buttons in the design's language.
///
/// Not Material's ElevatedButton/OutlinedButton: those carry M3 tonal
/// elevation and ripples, and this design has its own press state -- the
/// shared 0.97 scale -- and its own brand shadow on the primary.
enum AppButtonTone { primary, onDark, outlinedOnDark, danger, quiet }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tone = AppButtonTone.primary,
    this.expand = true,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final bool expand;
  final IconData? icon;

  /// Secondary sizing, for buttons that sit inside a card.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (background, foreground, border) = _colors();
    final radius = compact ? AppRadii.field - 2 : AppRadii.button;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      // Otherwise the child Text is announced as well and the button reads
      // twice.
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        child: Container(
          width: expand ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: kMinHitTarget),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpace.x14 : AppSpace.x20,
            vertical: compact ? AppSpace.x12 : AppSpace.x16,
          ),
          decoration: BoxDecoration(
            color: enabled ? background : background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border),
            boxShadow: enabled && tone == AppButtonTone.primary
                ? AppShadows.brandButton
                : null,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: AppSpace.x10),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppText.cardTitle.copyWith(
                    color: enabled
                        ? foreground
                        : foreground.withValues(alpha: 0.6),
                    fontSize: compact ? 13.5 : 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _colors() {
    switch (tone) {
      case AppButtonTone.primary:
        // brandStrong rather than the lighter brand red the prototype uses on
        // sign-in: white on #E54F38 is ~3.8:1, under the 4.5:1 that button
        // text needs. The handoff's own contrast note says the same.
        return (AppColors.brandStrong, AppColors.surface, null);
      case AppButtonTone.onDark:
        // White fill on an ink surface; the punch screen's primary.
        return (AppColors.surface, AppColors.ink, null);
      case AppButtonTone.outlinedOnDark:
        return (
          const Color(0x00FFFFFF),
          AppColors.surface,
          const Color(0x47FFFFFF), // rgba(255,255,255,0.28)
        );
      case AppButtonTone.danger:
        return (AppColors.danger, AppColors.surface, null);
      case AppButtonTone.quiet:
        return (AppColors.surface, AppColors.ink, AppColors.line);
    }
  }
}
