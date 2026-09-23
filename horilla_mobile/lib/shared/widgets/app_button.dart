import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Filled, outlined and text buttons in the design's language.
///
/// Not Material's ElevatedButton/OutlinedButton: those carry M3 tonal
/// elevation and ripples, and this design is flat with explicit press states.
enum AppButtonTone { primary, onDark, outlinedOnDark, danger, quiet }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tone = AppButtonTone.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (background, foreground, border) = _colors();

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      // Same reason as the tab bar: otherwise the child Text is announced as
      // well and the button reads twice.
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: widget.expand ? double.infinity : null,
          constraints: const BoxConstraints(minHeight: kMinHitTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x20,
            vertical: AppSpace.x16,
          ),
          decoration: BoxDecoration(
            color: enabled ? background : background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: border == null ? null : Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: AppText.cardTitle.copyWith(
              color: enabled ? foreground : foreground.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _colors() {
    switch (widget.tone) {
      case AppButtonTone.primary:
        return (
          _pressed ? AppColors.brandPressed : AppColors.brandStrong,
          AppColors.surface,
          null,
        );
      case AppButtonTone.onDark:
        // White fill on an ink surface; the sign-in and punch primaries.
        return (
          _pressed ? AppColors.onDark2 : AppColors.surface,
          AppColors.ink,
          null,
        );
      case AppButtonTone.outlinedOnDark:
        return (
          _pressed
              ? const Color(0x1FFFFFFF)
              : const Color(0x00FFFFFF),
          AppColors.surface,
          const Color(0x47FFFFFF), // rgba(255,255,255,0.28)
        );
      case AppButtonTone.danger:
        return (
          _pressed ? AppColors.dangerPressed : AppColors.danger,
          AppColors.surface,
          null,
        );
      case AppButtonTone.quiet:
        return (
          _pressed ? AppColors.bg2 : AppColors.surface,
          AppColors.ink,
          AppColors.line,
        );
    }
  }
}
