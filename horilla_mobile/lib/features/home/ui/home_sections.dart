/// The home screen's repeated blocks.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/home_models.dart';

/// The conditional band under the punch hero.
///
/// One band, never two: the design shows a single call to action per person,
/// and the role resolved server-side is already collapsed to one value.
class RoleBand extends StatelessWidget {
  const RoleBand({
    super.key,
    required this.role,
    required this.count,
    this.subtitle,
    this.onTap,
  });

  final String role;
  final int count;

  /// A breakdown under the headline, e.g. "3 leave · 1 shift change".
  final String? subtitle;
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
      shadow: false,
      radius: 18,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppText.cardTitle.copyWith(color: ink, fontSize: 13.5),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: AppText.meta.copyWith(color: ink)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: ink),
        ],
      ),
    );
  }
}

/// One tinted quick-action tile.
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = QuickActionTone.brand,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final QuickActionTone tone;
}

/// The four tints the handoff cycles through for these tiles.
enum QuickActionTone { brand, warning, info, success }

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Four across, dropping to two below 344pt of content width -- the
        // handoff's 360pt breakpoint less the screen padding.
        final columns = constraints.maxWidth < 344 ? 2 : 4;
        final gap = AppSpace.x8;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: AppSpace.x14,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: _QuickActionTile(action: action),
              ),
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
    final (background, ink) = switch (action.tone) {
      QuickActionTone.brand => (AppColors.brandTint, AppColors.brandStrong),
      QuickActionTone.warning => (AppColors.warningBg, AppColors.warning),
      QuickActionTone.info => (AppColors.infoBg, AppColors.info),
      QuickActionTone.success => (AppColors.successBg, AppColors.success),
    };

    return Semantics(
      button: true,
      label: action.label.replaceAll('\n', ' '),
      excludeSemantics: true,
      child: Pressable(
        onTap: action.onTap,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadii.iconTile),
              ),
              child: Icon(action.icon, size: 24, color: ink),
            ),
            const SizedBox(height: AppSpace.x8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(
                fontSize: 11.5,
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
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
    final n = colleagues.length;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'On leave today',
                  style: AppText.cardTitle.copyWith(fontSize: 13),
                ),
              ),
              Text(
                '$n ${n == 1 ? 'person' : 'people'} →',
                style: AppText.meta.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          Wrap(
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              for (final colleague in colleagues.take(6))
                AppAvatar.toned(name: colleague.name, size: 34),
              if (n > 6)
                SizedBox(
                  height: 34,
                  child: Center(
                    child: Text(
                      '+${n - 6}',
                      style: AppText.meta.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
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
          const SizedBox(height: AppSpace.x6),
          Text(
            announcement.title,
            style: AppText.cardTitle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
