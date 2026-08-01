import '../entities/category.dart';

/// Taxonomy boundary. Console-editable at runtime since FC9 (add/hide/reorder),
/// so both a one-shot read and a live watch exist — `getTaxonomy` for callers
/// that just need the list once (product form, console filters), `watchTaxonomy`
/// for customer Home's category grid, which must follow a console edit without
/// an app restart.
abstract class TaxonomyRepository {
  /// All categories in `sort` order, each with its subcategories embedded.
  /// Online → remote read (cached after); offline → last cached read.
  Future<List<Category>> getTaxonomy();

  /// Same shape as [getTaxonomy], live. Online → realtime Firestore stream
  /// (each emission cached); offline → one cached snapshot, then silent.
  Stream<List<Category>> watchTaxonomy();
}
