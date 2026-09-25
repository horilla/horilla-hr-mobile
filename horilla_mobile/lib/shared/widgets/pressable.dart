import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';

/// v2 press feedback: the tapped element scales to 0.97 over 150 ms.
///
/// One widget so every card, button and tile presses the same way. Semantics
/// are the caller's job -- a Pressable does not know whether it is a button,
/// a link or a row.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = kPressScale,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: kPressDuration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
