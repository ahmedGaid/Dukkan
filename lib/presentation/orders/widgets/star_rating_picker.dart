import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Five tappable stars. Tapping star N submits rating N directly — no
/// separate confirm step, matching the north star's "obvious with zero
/// explanation" bar. Disabled (dimmed, non-interactive) while a submit is
/// in flight, via [onRate] being null.
class StarRatingPicker extends StatelessWidget {
  const StarRatingPicker({super.key, required this.onRate, this.size = 32});

  final ValueChanged<int>? onRate;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onRate != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: IconButton(
              onPressed: enabled ? () => onRate!(i) : null,
              icon: Icon(Icons.star_rounded, color: AppColors.warning),
              iconSize: size,
              splashRadius: size * 0.7,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(width: size + 4, height: size + 4),
            ),
          ),
      ],
    );
  }
}

/// Read-only star row for an already-submitted rating — [filled] stars in
/// warning-amber, the rest outlined and muted.
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({super.key, required this.filled, this.size = 20});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= filled
                ? AppColors.warning
                : scheme.onSurface.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
