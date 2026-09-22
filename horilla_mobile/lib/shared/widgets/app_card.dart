import 'package:flutter/material.dart';

import '../../core/theme/platform_chrome.dart';
import '../../core/theme/tokens.dart';

/// The design's card: a bordered surface, never an elevated one.
///
/// Not Material's [Card]. M3 gives Card a tonal elevation tint, and this
/// design is explicitly flat with borders -- overriding that is more work
/// than a Container.
///
/// Cards that navigate lift their border to brandStrong on press, which is
/// the handoff's press language.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.x16),
    this.background = AppColors.surface,
    this.borderColor = AppColors.line,
    this.radius,
  }) : _skeletonHeight = null;

  /// Skeleton variant, sharing this card's geometry.
  ///
  /// [height] is a *minimum*, not a fixed size. A skeleton exists to stand in
  /// for a card while it loads; one that overflows its own box because the
  /// caller asked for fewer pixels than its contents need is worse than no
  /// skeleton at all.
  ///
  /// Deliberately a constructor on the card rather than a separate widget:
  /// skeletons kept in their own file drift out of sync with the real card
  /// within a couple of sprints, and a skeleton whose shape is wrong is worse
  /// than none.
  const AppCard.skeleton({
    super.key,
    double height = 96,
    this.padding = const EdgeInsets.all(AppSpace.x16),
    this.radius,
  })  : child = const _SkeletonBody(),
        onTap = null,
        background = AppColors.surface,
        borderColor = AppColors.line,
        _skeletonHeight = height;

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color background;
  final Color borderColor;
  final double? radius;
  final double? _skeletonHeight;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.onTap != null;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      constraints: BoxConstraints(minHeight: widget._skeletonHeight ?? 0),
      width: double.infinity,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius:
            BorderRadius.circular(widget.radius ?? PlatformChrome.cardRadius),
        border: Border.all(
          color: _pressed && tappable ? AppColors.brandStrong : widget.borderColor,
        ),
      ),
      child: widget.child,
    );

    if (!tappable) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBar(width: 90, height: 10),
        SizedBox(height: AppSpace.x12),
        SkeletonBar(width: double.infinity, height: 14),
        SizedBox(height: AppSpace.x8),
        SkeletonBar(width: 160, height: 14),
      ],
    );
  }
}

/// A single pulsing placeholder bar.
///
/// A plain opacity pulse rather than a shimmer package -- it is a few lines,
/// and the design asks for skeletons matching each card's geometry, not for a
/// particular animation.
class SkeletonBar extends StatefulWidget {
  const SkeletonBar({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<SkeletonBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
