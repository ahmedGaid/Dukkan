import 'package:equatable/equatable.dart';

import 'subcategory.dart';

/// A top-level catalog category. Seed-managed, fixed for v1 — no owner-created
/// categories, no admin console (`/categories`, read-only to clients).
/// [id] is the same Arabic string already used as `Shop.categories`/
/// `Product.category` (C1/S2), so existing home-chip filtering keeps matching
/// without a translation table between old wire values and new ids.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.sort,
    required this.subcategories,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int sort;
  final List<Subcategory> subcategories;

  @override
  List<Object?> get props => [id, nameAr, nameEn, sort, subcategories];
}
