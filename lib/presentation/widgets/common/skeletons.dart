import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import 'shimmer.dart';

/// A grid of shimmer tiles — the loading skeleton for any grid (category grid,
/// product grid in C2b). Non-scrolling; the caller places it in its own scroll
/// view. A skeleton, never a spinner page (designed loading states).
class GridShimmer extends StatelessWidget {
  const GridShimmer({
    super.key,
    this.count = 6,
    this.columns = 3,
    this.aspectRatio = 1,
    this.spacing = AppSpacing.md,
  });

  final int count;
  final int columns;
  final double aspectRatio;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (_, _) => const ShimmerBox(),
    );
  }
}

/// A stack of card-height shimmer rows — the loading skeleton for any vertical
/// list (nearby shops here, orders in C4).
class ListShimmer extends StatelessWidget {
  const ListShimmer({
    super.key,
    this.count = 4,
    this.itemHeight = 96,
    this.spacing = AppSpacing.md,
  });

  final int count;
  final double itemHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          ShimmerBox(height: itemHeight, radius: AppRadius.lgAll),
          if (i != count - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}
