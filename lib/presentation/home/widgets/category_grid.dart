import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Maps a shop category (Arabic, from the shop `categories` field) to a calm
/// glyph. Keyword match so new categories still land on a sensible icon rather
/// than a blank tile. Unknown → a generic basket.
IconData categoryIcon(String category) {
  bool has(String needle) => category.contains(needle);
  if (has('خضروات') || has('فواكه') || has('خضار')) return Icons.eco_outlined;
  if (has('ألبان') || has('البان') || has('جبن')) return Icons.egg_outlined;
  if (has('مشروبات') || has('عصائر')) return Icons.local_drink_outlined;
  if (has('معلبات')) return Icons.inventory_2_outlined;
  if (has('مخبوزات') || has('عيش') || has('مخبز')) {
    return Icons.bakery_dining_outlined;
  }
  if (has('لحوم') || has('دواجن') || has('لحمة')) return Icons.set_meal_outlined;
  if (has('منظفات') || has('نظافة')) return Icons.cleaning_services_outlined;
  return Icons.shopping_basket_outlined;
}

/// The 3-column category grid on Home. Tapping a tile filters the nearby-shops
/// list (handled by [ShopsBloc]); the active tile reads as selected.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final category = categories[i];
        return _CategoryTile(
          label: category,
          icon: categoryIcon(category),
          selected: category == selected,
          onTap: () => onSelect(category),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final tint = scheme.secondary;

    return Material(
      color: selected ? tint.withValues(alpha: 0.16) : scheme.surface,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? tint : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
