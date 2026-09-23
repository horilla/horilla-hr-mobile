import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../home/data/home_models.dart';
import '../data/punch_controller.dart';

/// Screen 3 of the handoff: confirm a punch.
///
/// No map. The handoff draws one as a striped placeholder, but the only map
/// tiles free of an API key are OpenStreetMap's public servers, whose usage
/// policy forbids exactly this -- and the thing a person actually needs to
/// know ("you are inside the fence, 40m from its edge") is a line of text.
/// A keyed provider can be added later if panning a map turns out to matter.
class PunchScreen extends ConsumerStatefulWidget {
  const PunchScreen({
    super.key,
    required this.isClockingIn,
    required this.geofence,
  });

  final bool isClockingIn;
  final GeofenceState geofence;

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

    final preparation = await ref.read(punchControllerProvider).prepare(
          isClockingIn: widget.isClockingIn,
          geofence: widget.geofence,
        );
    if (mounted) setState(() => _preparation = preparation);
  }

  Future<void> _submit() async {
    final preparation = _preparation;
    if (preparation == null || !preparation.canSubmit) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(punchControllerProvider).submit(preparation);
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preparation = _preparation;
    final verb = widget.isClockingIn ? 'Check in' : 'Check out';

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: kMinHitTarget,
                      height: kMinHitTarget,
                      child: Icon(
                        Icons.close,
                        color: AppColors.surface,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x20),
              Text(
                verb,
                style: AppText.cardTitle.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppColors.surface,
                ),
              ),

              const SizedBox(height: AppSpace.x20),
              if (preparation == null)
                const _CheckingLocation()
              else
                _LocationStatus(preparation: preparation),

              if (_error != null) ...[
                const SizedBox(height: AppSpace.x14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.x12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                  child: Text(
                    _error!,
                    style: AppText.body.copyWith(color: AppColors.danger),
                  ),
                ),
              ],

              const Spacer(),

              Text(
                'Your punch is recorded by the server, which checks your '
                'location again when it arrives. Times may be adjusted later '
                'to match your workplace records.',
                style: AppText.meta.copyWith(color: AppColors.onDark2),
              ),
              const SizedBox(height: AppSpace.x16),

              AppButton(
                label: _submitting ? 'Recording…' : verb,
                tone: AppButtonTone.onDark,
                onPressed: (preparation?.canSubmit ?? false) && !_submitting
                    ? _submit
                    : null,
              ),
              const SizedBox(height: AppSpace.x10),
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.x10),
                    child: Text(
                      'Not now',
                      style: AppText.body.copyWith(color: AppColors.onDark2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckingLocation extends StatelessWidget {
  const _CheckingLocation();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.onDark2),
          ),
        ),
        const SizedBox(width: AppSpace.x10),
        Text(
          'Checking your location…',
          style: AppText.body.copyWith(color: AppColors.onDark2),
        ),
      ],
    );
  }
}

class _LocationStatus extends StatelessWidget {
  const _LocationStatus({required this.preparation});

  final PunchPreparation preparation;

  @override
  Widget build(BuildContext context) {
    final fence = preparation.fence;
    final blocked = preparation.blockedReason;
    final ok = preparation.canSubmit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: ok ? AppColors.successDot : AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.x8),
            Expanded(
              child: Text(
                fence?.description ??
                    (blocked == null
                        ? 'No location check required here'
                        : 'Location needed'),
                style: AppText.cardTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
        if (preparation.coordinates != null) ...[
          const SizedBox(height: AppSpace.x8),
          Text(
            '${preparation.coordinates!.latitude.toStringAsFixed(5)}, '
            '${preparation.coordinates!.longitude.toStringAsFixed(5)}',
            style: AppText.mono.copyWith(
              fontSize: 11,
              color: AppColors.ink4,
            ),
          ),
        ],
        if (blocked != null) ...[
          const SizedBox(height: AppSpace.x14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.x12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            child: Text(
              blocked,
              style: AppText.body.copyWith(color: AppColors.warningInk),
            ),
          ),
        ],
      ],
    );
  }
}

/// What the punch screen needs from wherever it was opened.
///
/// Carried as route `extra` rather than re-fetched: home already knows both,
/// and a second fetch would let the two screens disagree about which way the
/// punch goes -- offering "Check in" to someone already clocked in.
class PunchArgs {
  const PunchArgs({required this.isClockingIn, required this.geofence});

  final bool isClockingIn;
  final GeofenceState geofence;
}
