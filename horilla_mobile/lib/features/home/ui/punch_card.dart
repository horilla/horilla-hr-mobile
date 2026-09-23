import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/home_models.dart';
import 'live_clock.dart';

/// The home screen's centre of gravity: the ink hero carrying the punch.
///
/// Live worked-time counter on the left, a 112pt ring button on the right
/// whose arc is the share of today's shift worked, and the day's three
/// numbers underneath.
class PunchCard extends StatelessWidget {
  const PunchCard({
    super.key,
    required this.punch,
    required this.geofence,
    required this.today,
    required this.dateLabel,
    this.onPunch,
  });

  final PunchState punch;
  final GeofenceState geofence;
  final TodayTotals today;
  final String dateLabel;
  final VoidCallback? onPunch;

  /// ponytail: 8h fallback when the server does not send today's shift
  /// requirement. The ring's caption says "of 8h" rather than "of shift" in
  /// that case, so it never claims to know a shift it was not told about.
  /// Upgrade: have the home aggregate return Attendance.minimum_hour.
  static const _fallbackShift = 8 * 3600;

  @override
  Widget build(BuildContext context) {
    final shift = today.shiftSeconds ?? _fallbackShift;
    final shiftKnown = today.shiftSeconds != null;
    final clockedIn = punch.isClockedIn;
    final checkedInToday = punch.clockInTime != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.x20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.hero),
        boxShadow: AppShadows.hero,
      ),
      child: WorkedTicker(
        workedAtFetch: today.workedSeconds,
        running: clockedIn,
        builder: (context, worked) {
          final pct = (worked / shift).clamp(0.0, 1.0);
          final left = shift - worked;

          final String stateLabel;
          final String sub;
          if (clockedIn) {
            stateLabel = 'Worked today';
            sub = left > 0
                ? '${formatHm(left)} left in your '
                      '${shiftKnown ? 'shift' : '8h day'}'
                : '+${formatHm(-left)} overtime';
          } else if (checkedInToday) {
            stateLabel = 'Checked out';
            sub = 'Tap check in to resume';
          } else {
            stateLabel = 'Not checked in yet';
            sub = 'Check in when you start work';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrap rather than Row: at large text the date and the pill
              // together exceed the card, and the pill drops to its own line.
              SizedBox(
                // Full width, or spaceBetween has no space to put between.
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.x8,
                  runSpacing: AppSpace.x8,
                  children: [
                    Text(
                      dateLabel.toUpperCase(),
                      style: AppText.mono.copyWith(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.onDark2,
                      ),
                    ),
                    if (geofence.enabled) const _GeofencePill(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.x18),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      container: true,
                      label: '$stateLabel ${formatHm(worked)}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stateLabel,
                            style: AppText.meta.copyWith(
                              fontSize: 12,
                              color: AppColors.onDark2,
                            ),
                          ),
                          const SizedBox(height: AppSpace.x6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatHms(worked),
                              maxLines: 1,
                              style: AppText.punchClock.copyWith(
                                fontSize: 34,
                                letterSpacing: -1.5,
                                height: 1.1,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.x6),
                          Text(
                            sub,
                            style: AppText.meta.copyWith(
                              fontSize: 12,
                              color: AppColors.onDark2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x14),
                  _RingButton(
                    progress: pct,
                    clockedIn: clockedIn,
                    caption:
                        '${(pct * 100).round()}% of ${shiftKnown ? 'shift' : '8h'}',
                    onTap: onPunch,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x18),
              Row(
                children: [
                  Expanded(
                    child: _HeroTile(
                      label: 'First in',
                      value: punch.clockInTime ?? '—',
                    ),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: _HeroTile(
                      label: 'Break',
                      value: formatShort(
                        TodayTotals.secondsOf(today.breakTime) ?? 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x8),
                  Expanded(
                    child: _HeroTile(
                      label: 'Overtime',
                      value: formatShort(
                        TodayTotals.secondsOf(today.overtime) ?? 0,
                      ),
                      valueColor: AppColors.successDot,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 112pt circle: a conic progress ring around a 96pt button.
///
/// White "Check out" while clocked in, brand-filled "Check in" otherwise --
/// the fill change is the state, so it reads at a glance.
class _RingButton extends StatelessWidget {
  const _RingButton({
    required this.progress,
    required this.clockedIn,
    required this.caption,
    this.onTap,
  });

  final double progress;
  final bool clockedIn;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = clockedIn ? 'Check out' : 'Check in';
    final fill = clockedIn ? AppColors.surface : AppColors.brandStrong;
    final ink = clockedIn ? AppColors.ink : AppColors.surface;

    return Semantics(
      button: true,
      label: '$label, $caption',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 112,
          height: 112,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress,
              color: clockedIn ? AppColors.brand : AppColors.successDot,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.power_settings_new, size: 20, color: ink),
                    const SizedBox(height: 3),
                    // Pinned: the ring is a fixed 96pt, and scaled text
                    // inside it would spill. The same words are in the
                    // semantics label above at the user's size.
                    MediaQuery.withNoTextScaling(
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: AppText.cardTitle.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: ink,
                            ),
                          ),
                          Text(
                            caption,
                            style: AppText.mono.copyWith(
                              fontSize: 9.5,
                              color: ink.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The prototype draws a conic gradient under a 96pt disc, leaving an
    // 8pt band. A stroked arc of the same width is the same picture.
    const band = 8.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(band / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = band
      ..color = AppColors.onDarkLine;
    canvas.drawArc(arc, 0, math.pi * 2, false, track);
    if (progress <= 0) return;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = band
      ..color = color;
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * progress, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

class _HeroTile extends StatelessWidget {
  const _HeroTile({
    required this.label,
    required this.value,
    this.valueColor = AppColors.surface,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: AppColors.onDarkTile,
          borderRadius: BorderRadius.circular(AppRadii.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.eyebrow.copyWith(
                letterSpacing: 0.8,
                color: AppColors.onDark2,
              ),
            ),
            const SizedBox(height: AppSpace.x4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppText.mono.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Geo-fence status. Shown only when the company actually uses the feature
/// -- a pill saying nothing is worse than no pill.
class _GeofencePill extends StatelessWidget {
  const _GeofencePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF), // rgba(255,255,255,0.1)
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
          // Flexible: at 2x text the label is wider than the card and must
          // be allowed to wrap rather than run off it.
          Flexible(
            child: Text(
              // Not "inside": that is decided at punch time, from a live fix.
              'Geo-fenced site',
              style: AppText.meta.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
