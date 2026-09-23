import 'package:flutter/material.dart';

import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/home_models.dart';
import 'live_clock.dart';

/// The home screen's centre of gravity: an ink hero carrying the punch state.
class PunchCard extends StatelessWidget {
  const PunchCard({
    super.key,
    required this.punch,
    required this.geofence,
    required this.dateLabel,
    this.onPunch,
    this.onOpenAttendance,
  });

  final PunchState punch;
  final GeofenceState geofence;
  final String dateLabel;
  final VoidCallback? onPunch;
  final VoidCallback? onOpenAttendance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.x20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap rather than Row: at large text the date and the geo-fence
          // pill together exceed the card, and a Row has nowhere to put the
          // difference. The pill drops to its own line instead.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpace.x8,
            runSpacing: AppSpace.x8,
            children: [
              Text(
                dateLabel.toUpperCase(),
                style: AppText.eyebrow.copyWith(color: AppColors.onDark2),
              ),
              if (geofence.enabled) const _GeofencePill(),
            ],
          ),
          const SizedBox(height: AppSpace.x14),
          const LiveClock(),
          const SizedBox(height: AppSpace.x8),
          Text(
            punch.isClockedIn && punch.clockInTime != null
                ? 'Checked in at ${punch.clockInTime}'
                : 'Not checked in yet',
            style: AppText.body.copyWith(color: AppColors.onDark2),
          ),
          const SizedBox(height: AppSpace.x20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: punch.isClockedIn ? 'Check out' : 'Check in',
                  tone: AppButtonTone.onDark,
                  onPressed: onPunch,
                ),
              ),
              const SizedBox(width: AppSpace.x12),
              _SquareAction(onTap: onOpenAttendance),
            ],
          ),
        ],
      ),
    );
  }
}

/// Geo-fence status. Shown only when the company actually uses the feature --
/// a pill saying nothing is worse than no pill.
class _GeofencePill extends StatelessWidget {
  const _GeofencePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x10,
        vertical: AppSpace.x6,
      ),
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF), // rgba(255,255,255,0.14)
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.successDot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpace.x6),
          Text(
            'GEO-FENCED',
            style: AppText.statusChip.copyWith(color: AppColors.surface),
          ),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Attendance',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(color: const Color(0x47FFFFFF)),
            boxShadow: PlatformChrome.punchButtonShadow,
          ),
          child: const Icon(
            Icons.bar_chart_outlined,
            color: AppColors.surface,
            size: 22,
          ),
        ),
      ),
    );
  }
}
