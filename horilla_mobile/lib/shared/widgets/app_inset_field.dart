import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// The design's inset field: an eyebrow label above the value, inside a
/// tinted box. Used on the sign-in screen over the ink surface, and on light
/// surfaces elsewhere.
class AppInsetField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final fill = onDark ? const Color(0x1AFFFFFF) : AppColors.bg2;
    final border = onDark ? const Color(0x47FFFFFF) : AppColors.line;
    final valueColor = onDark ? AppColors.surface : AppColors.ink;
    final labelColor = onDark ? AppColors.onDark2 : AppColors.ink4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x14,
            vertical: AppSpace.x10,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(
              color: errorText == null ? border : AppColors.danger,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppText.eyebrow.copyWith(color: labelColor)),
              const SizedBox(height: AppSpace.x4),
              TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                autofillHints: autofillHints,
                style: AppText.cardTitle.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
                cursorColor: onDark ? AppColors.surface : AppColors.brandStrong,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: AppText.cardTitle.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpace.x6),
          Text(
            errorText!,
            style: AppText.meta.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}
