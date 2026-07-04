import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';

/// A single calm placeholder block with a slow sweep — the atom every loading
/// skeleton is built from (no `shimmer` package; no new deps). Honours
/// reduced-motion: the sweep stops and a static tint shows instead.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BorderRadius? radius;
  final BoxShape shape;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.04),
      base,
    );
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final radius = widget.shape == BoxShape.circle
        ? null
        : (widget.radius ?? AppRadius.mdAll);

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          shape: widget.shape,
          borderRadius: radius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: radius,
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [base, highlight, base],
              stops: _stops(_controller.value),
            ),
          ),
        );
      },
    );
  }

  /// Slides a soft highlight band left→right across the box.
  List<double> _stops(double t) {
    final centre = t * 2 - 0.5; // travels -0.5 → 1.5
    final start = (centre - 0.3).clamp(0.0, 1.0);
    final mid = centre.clamp(0.0, 1.0);
    final end = (centre + 0.3).clamp(0.0, 1.0);
    // Stops must be non-decreasing.
    final s = start;
    final m = mid < s ? s : mid;
    final e = end < m ? m : end;
    return [s, m, e];
  }
}
