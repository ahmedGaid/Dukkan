import '../entities/category.dart';

/// Taxonomy boundary — one-shot read of the fixed, seed-managed category tree.
/// Not a stream: `/categories` never changes at runtime (only via re-seed),
/// so there's nothing to watch (matches `getShopByOwner`'s one-shot contract).
abstract class TaxonomyRepository {
  /// All categories in `sort` order, each with its subcategories embedded.
  /// Online → remote read (cached after); offline → last cached read.
  Future<List<Category>> getTaxonomy();
}
