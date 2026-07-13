import '../repositories/admin_products_repository.dart';

/// Runs a bulk-dialog change over a selection — [changes] is one field map
/// per product id (already computed by the caller, e.g. each product's own
/// round-half-up new price). Reports a single `product.bulkUpdate` audit
/// entry, never one per product.
class BulkUpdateProducts {
  const BulkUpdateProducts(this._repository);

  final AdminProductsRepository _repository;

  Future<int> call({
    required Map<String, Map<String, dynamic>> changes,
    required String changeDescription,
  }) =>
      _repository.bulkUpdate(changes: changes, changeDescription: changeDescription);
}
