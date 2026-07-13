import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/price_tag.dart';

/// One console stat tile — a labelled figure over a muted icon. Either a plain
/// count ([valueText]) or a money amount ([valueMinor], rendered via [PriceTag]
/// but recoloured to `onSurface` so a grid of these stays calm and monochrome,
/// the M13 finance style). Shared by the founder finance summary and the
/// console dashboard (extracted so the two never drift). Pass `valueText: '—'`
/// for a figure the viewer isn't permitted to see.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    this.valueText,
    this.valueMinor,
  }) : assert(
          (valueText == null) != (valueMinor == null),
          'exactly one of valueText/valueMinor must be set',
        );

  final IconData icon;
  final String label;
  final String? valueText;
  final int? valueMinor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final valueStyle = text.titleLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: scheme.onSurface.withValues(alpha: 0.6)),
          const Spacer(),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          valueMinor != null
              ? PriceTag(valueMinor!, style: valueStyle)
              : Text(valueText!, style: valueStyle),
        ],
      ),
    );
  }
}
