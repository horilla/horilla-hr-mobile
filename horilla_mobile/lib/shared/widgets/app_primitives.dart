/// The small repeated pieces the design leans on everywhere.
///
/// Kept in one file because each is a handful of lines and they are always
/// reached for together; splitting them across six files would be more
/// navigation than code.
library;

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Semantic meaning of a status, mapped to the handoff's colour pairs.
enum StatusTone { neutral, success, warning, danger, info, brand }

/// Uppercase mono pill. Leave status, ticket state, due chips.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = StatusTone.neutral});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (tone) {
      StatusTone.neutral => (AppColors.bg2, AppColors.ink3, AppColors.line),
      StatusTone.success => (
          const Color(0xFFE7F3ED),
          AppColors.success,
          const Color(0xFFC6E2D5)
        ),
      StatusTone.warning => (
          AppColors.warningBg,
          AppColors.warningInk,
          AppColors.warningBorder
        ),
      StatusTone.danger => (
          AppColors.dangerBg,
          AppColors.danger,
          AppColors.dangerBorder
        ),
      StatusTone.info => (AppColors.infoBg, AppColors.infoInk, AppColors.infoBorder),
      StatusTone.brand => (
          AppColors.brandTint,
          AppColors.brandTintInk,
          AppColors.brandTintBorder
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x8,
        vertical: AppSpace.x4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppText.statusChip.copyWith(color: foreground),
      ),
    );
  }
}

/// Uppercase mono section label.
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: color == null
            ? AppText.eyebrow
            : AppText.eyebrow.copyWith(color: color),
      );
}

/// One cell of the home screen's 3-up Worked / Break / OT grid.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        EyebrowLabel(label),
        const SizedBox(height: AppSpace.x6),
        Text(value, style: AppText.statValue.copyWith(color: valueColor)),
      ],
    );
  }
}

/// A section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // Both children have to be bounded. Unconstrained, a Row lays each Text
    // out at its natural width and overflows -- which at large text sizes is
    // exactly what happened, on every screen at once, because this is shared.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle.copyWith(fontSize: 15.5, height: 1.2),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpace.x10),
          Flexible(
            child: GestureDetector(
              onTap: onAction,
              child: ConstrainedBox(
                // Never more than a third of the row: the action is
                // secondary to the heading it sits beside.
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  actionLabel!,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta.copyWith(
                    color: AppColors.brandStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Initials tile. The design uses initials rather than photos in v1.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.background = AppColors.brandTint,
    this.foreground = AppColors.brandTintInk,
  });

  final String name;
  final double size;
  final Color background;
  final Color foreground;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * (14 / 40)),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: AppText.cardTitle.copyWith(
          color: foreground,
          fontSize: size * (15 / 40),
        ),
      ),
    );
  }
}
