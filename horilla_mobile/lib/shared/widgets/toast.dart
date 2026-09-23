import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import 'pressable.dart';

/// One transient confirmation, with an optional Undo.
class ToastMessage {
  const ToastMessage(this.text, {this.onUndo});

  final String text;
  final VoidCallback? onUndo;
}

/// App-wide toast state. One at a time: a new toast replaces the old one,
/// which is what the prototype does and what stops them stacking up.
class ToastController extends Notifier<ToastMessage?> {
  static const visibleFor = Duration(milliseconds: 4500);
  Timer? _timer;

  @override
  ToastMessage? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(String text, {VoidCallback? onUndo}) {
    _timer?.cancel();
    state = ToastMessage(text, onUndo: onUndo);
    _timer = Timer(visibleFor, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    state = null;
  }
}

final toastProvider = NotifierProvider<ToastController, ToastMessage?>(
  ToastController.new,
);

/// Draws the current toast above everything else.
///
/// Mounted once, at the app root, so any screen can raise a toast and it
/// survives the navigation that usually follows (check out -> back to home).
class ToastHost extends ConsumerWidget {
  const ToastHost({super.key, required this.child});

  final Widget child;

  /// Clears the floating tab bar, which is ~90pt tall with its padding.
  static const _bottom = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider);
    final visible = toast != null;

    return Stack(
      children: [
        child,
        Positioned(
          left: 16,
          right: 16,
          bottom: _bottom + MediaQuery.paddingOf(context).bottom,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 320),
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 320),
                child: toast == null
                    ? const SizedBox.shrink()
                    : _ToastPill(
                        message: toast,
                        onUndo: toast.onUndo == null
                            ? null
                            : () {
                                ref.read(toastProvider.notifier).dismiss();
                                toast.onUndo!();
                              },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastPill extends StatelessWidget {
  const _ToastPill({required this.message, this.onUndo});

  final ToastMessage message;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Announced as it appears; a sighted user sees it, and nobody else
      // would know it happened.
      liveRegion: true,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.toast,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 15, color: Colors.white),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Text(
                  message.text,
                  style: AppText.body.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              if (onUndo != null)
                Semantics(
                  button: true,
                  label: 'Undo',
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: onUndo,
                    child: const SizedBox(
                      height: kMinHitTarget,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Center(
                          child: Text(
                            'Undo',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.toastAction,
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
      ),
    );
  }
}
