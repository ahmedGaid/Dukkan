import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Shown next to an order's status chip when a status change is queued
/// offline (O2 slice 1) — one shared widget instead of three copies across
/// the owner desk, courier deliveries list, and order-detail page.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sync_outlined, size: 14, color: AppColors.warning),
        const SizedBox(width: AppSpacing.xs),
        Text(
          l10n.offlineSyncPendingBadge,
          style: text.bodySmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
