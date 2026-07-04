import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The ONE soft shadow for elevated surfaces (cards, sheets). Defined once so
/// every raised element in the app casts the same calm, low shadow — no per-widget
/// shadow tuning (design direction: `Docs/plan/c2-browse-design.md`).
abstract final class AppShadows {
  /// Deep-green tinted, low and soft — reads as lift, never as a hard border.
  /// Derived from the brand green so no raw hex lives outside [AppColors].
  static final soft = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08), // warm, not grey
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
