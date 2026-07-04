import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

/// The base surface for every raised block (shop card, promo banner, tile).
/// One soft shadow, rounded corners from the scale, no border by default —
/// build once, never fork (design direction: `Docs/plan/c2-browse-design.md`).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.radius,
    this.clip = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  /// Corner radius from [AppRadius]; defaults to `lg` (matches the card theme).
  final BorderRadius? radius;

  /// Clip the content to the card radius — set when a child paints to the edge
  /// (e.g. a shop logo header image). The shadow stays outside the clip.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = radius ?? AppRadius.lgAll;

    return Container(
      // Shadow + fill live here, outside the clip, so lift reads correctly.
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: r,
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
