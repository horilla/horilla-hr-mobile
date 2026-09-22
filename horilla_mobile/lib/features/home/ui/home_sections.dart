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
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: StatTile(label: 'Worked', value: today.worked)),
          Expanded(child: StatTile(label: 'Break', value: today.breakTime)),
          Expanded(
            child: StatTile(
              label: 'Overtime',
              value: today.overtime,
              valueColor:
                  today.hasOvertime ? AppColors.success : AppColors.ink,
            ),
          ),
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
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.x10,
          crossAxisSpacing: AppSpace.x10,
          childAspectRatio: 0.95,
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
          Text(
            action.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.meta.copyWith(
              color: AppColors.ink2,
              fontWeight: FontWeight.w600,
              height: 1.25,
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
