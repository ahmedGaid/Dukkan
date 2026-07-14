import 'package:flutter/material.dart';

/// The console icon picker's options (FC9) — Material icons are const, no
/// dynamic `IconData` lookup exists in Flutter, so a category's `iconName`
/// is a key into this curated, grocery-relevant map rather than an arbitrary
/// codepoint. Order here is the grid's display order.
const categoryIconOptions = <String, IconData>{
  'produce': Icons.eco_outlined,
  'dairy': Icons.egg_outlined,
  'bakery': Icons.bakery_dining_outlined,
  'meat': Icons.set_meal_outlined,
  'seafood': Icons.set_meal,
  'beverages': Icons.local_drink_outlined,
  'canned': Icons.inventory_2_outlined,
  'cleaning': Icons.cleaning_services_outlined,
  'snacks': Icons.cookie_outlined,
  'frozen': Icons.ac_unit_outlined,
  'spices': Icons.grass_outlined,
  'grains': Icons.grain_outlined,
  'oils': Icons.opacity_outlined,
  'sweets': Icons.icecream_outlined,
  'breakfast': Icons.free_breakfast_outlined,
  'household': Icons.home_outlined,
  'personalCare': Icons.spa_outlined,
  'babyCare': Icons.child_care_outlined,
  'petCare': Icons.pets_outlined,
  'basket': Icons.shopping_basket_outlined,
};

/// Resolves a category's console icon: its own [iconName] if set, else the
/// same keyword-matched fallback the customer-facing `CategoryGrid` has
/// always used (`categoryIcon` in `home/widgets/category_grid.dart`), so
/// every category — including pre-FC9 seeded ones with no `iconName` — shows
/// something sensible.
IconData resolveCategoryIcon(String? iconName, IconData fallback) {
  if (iconName == null) return fallback;
  return categoryIconOptions[iconName] ?? fallback;
}
