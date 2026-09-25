import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'pressable.dart';

/// The design's card: a white surface with a light border and a soft shadow.
///
/// Not Material's [Card]. M3 gives Card a tonal elevation tint that fights
/// this palette, and a Container with the handoff's exact shadow is less work
/// than overriding it.
///
/// Cards that navigate scale on press -- v2's press language, shared with
/// every other tappable element through [Pressable].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpace.x16),
    this.background = AppColors.surface,
    this.borderColor = AppColors.cardBorder,
    this.radius = AppRadii.card,
    this.shadow = true,
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
    this.radius = AppRadii.card,
  }) : child = const _SkeletonBody(),
       onTap = null,
       background = AppColors.surface,
       borderColor = AppColors.cardBorder,
       shadow = true,
       _skeletonHeight = height;

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color background;
  final Color borderColor;
  final double radius;

  /// Off for cards on a non-white surface (an ink hero, a tinted band), where
  /// the soft shadow reads as dirt rather than lift.
  final bool shadow;
  final double? _skeletonHeight;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: _skeletonHeight ?? 0),
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor),
          boxShadow: shadow ? AppShadows.card : null,
        ),
        child: child,
      ),
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
