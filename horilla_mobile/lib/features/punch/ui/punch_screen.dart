import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/hold_to_confirm_button.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/toast.dart';
import '../../home/data/home_models.dart';
import '../../home/ui/live_clock.dart';
import '../data/punch_controller.dart';

/// Screen 3 of the handoff: confirm a punch.
///
/// No map tiles. The handoff draws a striped placeholder "for the real map
/// SDK", but the only tiles free of an API key are OpenStreetMap's public
/// servers, whose usage policy forbids exactly this. The placeholder itself
/// carries what a person needs -- a live position and its distance from the
/// fence -- so it stays, drawn as the design draws it.
///
/// Check-out is hold-to-confirm; check-in is a plain tap. A punch is written
/// to the server the moment it fires and there is no endpoint to take one
/// back, so the accidental-touch guard sits in front of the one that ends a
/// working day rather than behind it as an Undo.
class PunchScreen extends ConsumerStatefulWidget {
  const PunchScreen({
    super.key,
    required this.isClockingIn,
    required this.geofence,
    this.today = TodayTotals.zero,
    this.clockInTime,
  });

  final bool isClockingIn;
  final GeofenceState geofence;
  final TodayTotals today;
  final String? clockInTime;

  @override
  ConsumerState<PunchScreen> createState() => _PunchScreenState();
}

class _PunchScreenState extends ConsumerState<PunchScreen> {
  PunchPreparation? _preparation;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() {
      _preparation = null;
      _error = null;
    });

    final preparation = await ref
        .read(punchControllerProvider)
        .prepare(isClockingIn: widget.isClockingIn, geofence: widget.geofence);
    if (mounted) setState(() => _preparation = preparation);
  }

  Future<void> _submit() async {
    final preparation = _preparation;
    if (preparation == null || !preparation.canSubmit || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(punchControllerProvider).submit(preparation);
      final at = DateFormat('HH:mm').format(DateTime.now());
      ref
          .read(toastProvider.notifier)
          .show(
            widget.isClockingIn ? 'Checked in at $at' : 'Checked out at $at',
          );
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      // Stays on screen, in words, until acted on: the punch did not
      // register, and a toast that scrolls away is how people go home
      // believing it did.
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preparation = _preparation;
    final verb = widget.isClockingIn ? 'Check in' : 'Check out';
    final ready = (preparation?.canSubmit ?? false) && !_submitting;
    final worked = widget.today.workedSeconds;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          AppTopBar(title: verb, onDark: true, onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpace.x20,
                AppSpace.x10,
                AppSpace.x20,
                MediaQuery.paddingOf(context).bottom + AppSpace.x20,
              ),
              children: [
                _LocationPanel(preparation: preparation),

                if (preparation?.blockedReason != null) ...[
                  const SizedBox(height: AppSpace.x12),
                  _Banner(
                    text: preparation!.blockedReason!,
                    background: AppColors.warningBg,
                    ink: AppColors.warningInk,
                  ),
                ],

                const SizedBox(height: AppSpace.x14),
                _Summary(
                  rows: [
                    if (!widget.isClockingIn)
                      ('Checked in', widget.clockInTime ?? '—'),
                    if (!widget.isClockingIn)
                      ('Worked so far', formatHm(worked)),
                    (
                      'Break',
                      formatShort(
                        TodayTotals.secondsOf(widget.today.breakTime) ?? 0,
                      ),
                    ),
                    ('Location check', _fenceLabel(preparation)),
                  ],
                ),

                const SizedBox(height: AppSpace.x16),
                Text(
                  widget.isClockingIn
                      ? 'Your punch is recorded by the server, which checks '
                            'your location again when it arrives.'
                      : 'Punching out records ${formatHm(worked)} against your '
                            'hour account. Biometric device records reconcile '
                            'with it later.',
                  style: AppText.body.copyWith(
                    fontSize: 12.5,
                    color: AppColors.onDark2,
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppSpace.x14),
                  _Banner(
                    text: "Your punch did not register. ${_error!}",
                    background: AppColors.dangerBg,
                    ink: AppColors.danger,
                  ),
                ],

                const SizedBox(height: AppSpace.x20),
                if (widget.isClockingIn)
                  AppButton(
                    label: _submitting ? 'Recording…' : 'Check in',
                    tone: AppButtonTone.onDark,
                    onPressed: ready ? _submit : null,
                  )
                else ...[
                  HoldToConfirmButton(
                    label: _submitting ? 'Recording…' : 'Hold to check out',
                    holdingLabel: 'Keep holding…',
                    enabled: ready,
                    onConfirmed: _submit,
                  ),
                  const SizedBox(height: AppSpace.x12),
                  Text(
                    'Press and hold for a second — prevents accidental '
                    'punches',
                    textAlign: TextAlign.center,
                    style: AppText.meta.copyWith(color: AppColors.onDark2),
                  ),
                ],
                const SizedBox(height: AppSpace.x4),
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Not now',
                    excludeSemantics: true,
                    child: Pressable(
                      onTap: () => context.pop(),
                      child: SizedBox(
                        height: kMinHitTarget,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.x16,
                            ),
                            child: Text(
                              'Not now',
                              style: AppText.body.copyWith(
                                fontSize: 14,
                                color: AppColors.onDark2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fenceLabel(PunchPreparation? preparation) {
    if (preparation == null) return 'Checking…';
    if (!widget.geofence.enabled) return 'Not required';
    final fence = preparation.fence;
    if (fence == null) return 'Location needed';
    return fence.isInside ? 'Inside the fence' : 'Outside the fence';
  }
}

/// The handoff's striped map placeholder, carrying the live fix.
class _LocationPanel extends StatelessWidget {
  const _LocationPanel({required this.preparation});

  final PunchPreparation? preparation;

  @override
  Widget build(BuildContext context) {
    final p = preparation;
    final fence = p?.fence;
    final ok = p?.canSubmit ?? false;

    final String headline;
    if (p == null) {
      headline = 'Checking your location…';
    } else if (fence != null) {
      headline = fence.description;
    } else if (p.blockedReason == null) {
      headline = 'No location check required here';
    } else {
      headline = 'Location needed';
    }

    return Semantics(
      label: headline,
      excludeSemantics: true,
      child: Container(
        // A minimum, not a fixed height: at 2x text the coordinates and the
        // distance line need more than the handoff's 168pt.
        constraints: const BoxConstraints(minHeight: 168),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.onDarkLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: const _StripePainter(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.x16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulseDot(
                    color: p == null
                        ? AppColors.onDark2
                        : ok
                        ? AppColors.successDot
                        : AppColors.warning,
                  ),
                  if (p?.coordinates != null) ...[
                    const SizedBox(height: AppSpace.x10),
                    Text(
                      '${_deg(p!.coordinates!.latitude, 'N', 'S')}, '
                      '${_deg(p.coordinates!.longitude, 'E', 'W')}',
                      style: AppText.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.onDark2,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.x6),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _deg(double value, String positive, String negative) =>
      '${value.abs().toStringAsFixed(4)}° ${value >= 0 ? positive : negative}';
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF232323),
    );
    final stripe = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 7;
    for (var x = -size.height; x < size.width; x += 18) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honour "reduce motion": the dot still says where you are, it just
    // stops breathing.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    return SizedBox(
      width: 30,
      height: 30,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 + 16 * _c.value,
              height: 14 + 16 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.onDarkLine),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: AppText.body.copyWith(color: AppColors.onDark2),
                    ),
                  ),
                  const SizedBox(width: AppSpace.x12),
                  Flexible(
                    // Align, or the value sits at the start of its half of the row:
                    // an Expanded label and a Flexible value split the width evenly.
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        rows[i].$2,
                        textAlign: TextAlign.end,
                        style: AppText.mono.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.background,
    required this.ink,
  });

  final String text;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.x12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.tile),
        ),
        child: Text(text, style: AppText.body.copyWith(color: ink)),
      ),
    );
  }
}

/// What the punch screen needs from wherever it was opened.
///
/// Carried as route `extra` rather than re-fetched: home already knows all of
/// it, and a second fetch would let the two screens disagree about which way
/// the punch goes -- offering "Check in" to someone already clocked in.
class PunchArgs {
  const PunchArgs({
    required this.isClockingIn,
    required this.geofence,
    this.today = TodayTotals.zero,
    this.clockInTime,
  });

  final bool isClockingIn;
  final GeofenceState geofence;
  final TodayTotals today;
  final String? clockInTime;
}
