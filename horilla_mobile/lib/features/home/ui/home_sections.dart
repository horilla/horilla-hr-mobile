/// The home screen's repeated blocks.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../data/home_models.dart';

/// Worked / Break / Overtime.
class TodayStats extends StatelessWidget {
  const TodayStats({super.key, required this.today});

  final TodayTotals today;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      StatTile(label: 'Worked', value: today.worked),
      StatTile(label: 'Break', value: today.breakTime),
      StatTile(
        label: 'Overtime',
        value: today.overtime,
        valueColor: today.hasOvertime ? AppColors.success : AppColors.ink,
      ),
    ];

    // Three mono durations side by side stop fitting well before the text
    // scale reaches the ~3x the platforms allow. Past 1.5x they stack, which
    // is a worse use of space but is legible -- and legible is the point of
    // someone turning the text up.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    return AppCard(
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpace.x14),
                  tiles[i],
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gaps matter more than they look here. The values are mono
                // durations that fill their column almost exactly, so with
                // three equal columns and no spacing they end up touching --
                // "03:12:4000:30:00" reads as one number, which is how it
                // looked on the first device build.
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpace.x12),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
    );
  }
}

/// The conditional band under the stats.
///
/// One band, never two: the design shows a single call to action per person,
/// and the role resolved server-side is already collapsed to one value.
class RoleBand extends StatelessWidget {
  const RoleBand({
    super.key,
    required this.role,
    required this.count,
    this.onTap,
  });

  final String role;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (background, border, ink, text) = switch (role) {
      'hrexec' => (
          AppColors.ink,
          AppColors.ink,
          AppColors.surface,
          'HR desk · $count ${count == 1 ? 'item' : 'items'}',
        ),
      'manager' => (
          AppColors.warningBg,
          AppColors.warningBorder,
          AppColors.warningInk,
          '$count ${count == 1 ? 'request needs' : 'requests need'} you',
        ),
      _ => (
          AppColors.infoBg,
          AppColors.infoBorder,
          AppColors.infoInk,
          'Your onboarding is in progress',
        ),
    };

    return AppCard(
      onTap: onTap,
      background: background,
      borderColor: border,
      padding: const EdgeInsets.all(AppSpace.x14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: AppText.cardTitle.copyWith(color: ink, fontSize: 13.5),
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: ink),
        ],
      ),
    );
  }
}

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The handoff keeps four across, dropping to 2x2 below 360pt.
        final columns = constraints.maxWidth < 344 ? 2 : 4;

        // Height is derived from the text scale rather than a fixed aspect
        // ratio. A ratio is a constant, and the label inside these tiles is
        // not: at 1.3x it needs more room than the tile had, which is the
        // overflow this replaces.
        final scaled = MediaQuery.textScalerOf(context).scale(1);
        final extent = 88 + (scaled - 1) * 46;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.x10,
          crossAxisSpacing: AppSpace.x10,
          mainAxisExtent: extent,
          children: [
            for (final action in actions) _QuickActionTile(action: action),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: action.onTap,
      padding: const EdgeInsets.all(AppSpace.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(AppRadii.iconTile),
            ),
            child: Icon(action.icon, size: 15, color: AppColors.brandStrong),
          ),
          Flexible(
            child: Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(
                color: AppColors.ink2,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnLeaveToday extends StatelessWidget {
  const OnLeaveToday({super.key, required this.colleagues, this.onTap});

  final List<ColleagueOnLeave> colleagues;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('On leave today'),
          const SizedBox(height: AppSpace.x12),
          Row(
            children: [
              for (final colleague in colleagues.take(5))
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.x8),
                  child: AppAvatar(name: colleague.name, size: 34),
                ),
              if (colleagues.length > 5)
                Text(
                  '+${colleagues.length - 5}',
                  style: AppText.meta.copyWith(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement, this.onTap});

  final AnnouncementSummary announcement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Announcement'),
          const SizedBox(height: AppSpace.x8),
          Text(
            announcement.title,
            style: AppText.cardTitle.copyWith(fontSize: 15.5),
          ),
        ],
      ),
    );
  }
}
