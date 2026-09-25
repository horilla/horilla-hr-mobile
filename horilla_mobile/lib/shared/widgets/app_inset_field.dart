import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// The design's inset field: an eyebrow label above the value, inside a
/// tinted box. Used on the sign-in screen over the ink surface, and on light
/// surfaces elsewhere.
class AppInsetField extends StatefulWidget {
  const AppInsetField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.onDark = false,
    this.errorText,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool onDark;
  final String? errorText;
  final Iterable<String>? autofillHints;

  @override
  State<AppInsetField> createState() => _AppInsetFieldState();
}

class _AppInsetFieldState extends State<AppInsetField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onDark = widget.onDark;
    final errorText = widget.errorText;
    // v2: a borderless inset that picks up a brand border and label while
    // focused, so it is obvious which field the keyboard is typing into.
    final fill = onDark ? const Color(0x1AFFFFFF) : AppColors.bg;
    final border = _focused
        ? AppColors.brandStrong
        : onDark
        ? const Color(0x47FFFFFF)
        : AppColors.bg;
    final valueColor = onDark ? AppColors.surface : AppColors.ink;
    final labelColor = _focused
        ? AppColors.brandStrong
        : onDark
        ? AppColors.onDark2
        : AppColors.ink4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x16,
              vertical: AppSpace.x12,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadii.field + 2),
              border: Border.all(
                color: errorText == null ? border : AppColors.danger,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: AppText.eyebrow.copyWith(color: labelColor),
                ),
                const SizedBox(height: AppSpace.x4),
                const SizedBox(height: 2),
                TextField(
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  autofillHints: widget.autofillHints,
                  style: AppText.cardTitle.copyWith(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: onDark
                      ? AppColors.surface
                      : AppColors.brandStrong,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: AppText.cardTitle.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpace.x6),
          Text(
            errorText,
            style: AppText.meta.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}
