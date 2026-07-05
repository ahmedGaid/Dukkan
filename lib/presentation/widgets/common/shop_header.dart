import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../../l10n/app_localizations.dart';
import 'shimmer_image.dart';
import 'status_chip.dart';

/// A دكان's identity block: logo, name, address, open/closed. Shared by the
/// customer [ShopPage] (C2b) and the owner's [CatalogManagerPage] (S2) — same
/// facts, read-only either way.
class ShopHeader extends StatelessWidget {
  const ShopHeader({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? shop.nameAr : shop.name;

    return Row(
      children: [
        ShimmerImage(
          url: shop.logoUrl,
          width: 72,
          height: 72,
          radius: AppRadius.lgAll,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      shop.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              StatusChip(
                label: shop.isOpen ? l10n.shopOpen : l10n.shopClosed,
                tone: shop.isOpen ? StatusTone.positive : StatusTone.caution,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
