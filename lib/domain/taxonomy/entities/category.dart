import 'package:equatable/equatable.dart';

import 'subcategory.dart';

/// A top-level catalog category. Seed-managed at first (M3); console-editable
/// from FC9 (`/categories`, gated by `taxonomy.edit`). [id] is the same
/// Arabic string already used as `Shop.categories`/`Product.category` (C1/S2)
/// for the original seeded set, so existing home-chip filtering keeps
/// matching without a translation table; a console-created category gets an
/// auto id instead, since it has no legacy references to match.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.sort,
    required this.subcategories,
    this.isVisible = true,
    this.iconName,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int sort;
  final List<Subcategory> subcategories;

  /// FC9: hides a retired category from customer/owner category pickers
  /// without deleting it — existing products keep the stale id and still
  /// render (no FK, `Product.category` is a plain string).
  final bool isVisible;

  /// FC9: a key into `console/taxonomy/category_icons.dart`'s curated icon
  /// map. Null falls back to the keyword-matched `categoryIcon()` used
  /// before this session.
  final String? iconName;

  @override
  List<Object?> get props =>
      [id, nameAr, nameEn, sort, subcategories, isVisible, iconName];
}
