import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Press and hold to confirm; releasing early cancels.
///
/// For actions a stray tap must not trigger -- the check-out punch, which is
/// written to the server the moment it fires and cannot be taken back. A
/// brand fill sweeps across the button while it is held.
///
/// Screen readers get a plain activate action instead. Holding is awkward to
/// impossible with TalkBack or VoiceOver, and the hold exists to stop
/// *accidental* touches; a deliberate double-tap through the accessibility
/// layer is not one.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.holdingLabel,
    required this.onConfirmed,
    this.holdFor = const Duration(milliseconds: 1100),
    this.enabled = true,
  });

  final String label;
  final String holdingLabel;
  final VoidCallback onConfirmed;
  final Duration holdFor;
  final bool enabled;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: widget.holdFor)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _progress.value = 0;
            widget.onConfirmed();
          }
        });

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.enabled) _progress.forward(from: 0);
  }

  void _cancel() {
    // Snap back rather than drain: an early release means "no", and a slow
    // reverse sweep reads as the action still being in progress.
    if (_progress.isAnimating) _progress.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.enabled ? widget.onConfirmed : null,
      child: GestureDetector(
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final t = _progress.value;
            final holding = t > 0;
            return Opacity(
              opacity: widget.enabled ? 1 : 0.5,
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.button + 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: t,
                      heightFactor: 1,
                      child: const ColoredBox(color: AppColors.brandStrong),
                    ),
                    Center(
                      child: Text(
                        holding ? widget.holdingLabel : widget.label,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          // Flip once the fill has passed the middle, where
                          // the text sits.
                          color: t > 0.5 ? AppColors.surface : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
