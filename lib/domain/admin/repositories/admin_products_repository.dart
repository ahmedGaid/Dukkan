import '../../product/entities/product.dart';
import '../entities/products_page.dart';

/// Founder Console product management (FC8). Reads are Firestore-direct and
/// unfiltered — `/products` read is public (`allow read: if true`) — the
/// customer-facing `deleted` filter lives only in `ProductRepositoryImpl`.
/// Every mutation is Firestore-direct, gated by the `products.*` rules
/// branches (see `firestore.rules`); there is no Worker-routed op here
/// (unlike `AdminShopsRepository.transferOwnership`) since no field on a
/// product is ever forbidden to a client the way `ownerUid` is on a shop.
abstract class AdminProductsRepository {
  /// One cursor-paginated page (25/doc-id order), narrowed by whichever
  /// filters are non-null. `deletedOnly` selects the soft-deleted set
  /// instead of the live one — never both at once.
  Future<ProductsPage> getProducts({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    bool deletedOnly = false,
    String? cursor,
  });

  /// Every product matching the given filters, unpaginated — backs the
  /// board's Arabic-folded name search (bounded by whichever filters are
  /// active, never the whole catalog at once by default).
  Future<List<Product>> getAllMatching({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    bool deletedOnly = false,
  });

  /// Everything else editable from the board without opening the full form:
  /// row-level soft delete/restore and the bulk dialogs' per-field patches.
  Future<void> patchFields(String productId, Map<String, dynamic> fields);

  /// [actorUid] is self-reported by the client (this write isn't Worker-
  /// verified) — acceptable for FC8, matching the trust level of every other
  /// Firestore-direct console mutation (see `AdminShopsRepository`).
  Future<void> softDelete({required String productId, required String actorUid});

  Future<void> restore(String productId);

  /// Copies [productId] into a new doc: name gets " (نسخة)" appended,
  /// `isPromo`/`isFeatured` cleared, never soft-deleted. Returns the new id.
  Future<String> duplicate(String productId);

  /// A real Firestore delete — irreversible. Console UI restricts this to an
  /// already soft-deleted product and the founder wildcard permission; the
  /// rules-side gate is the same `products.delete` branch as everything else
  /// here (see `firestore.rules`).
  Future<void> hardDelete(String productId);

  /// Applies a different field map to each product id in [changes] via
  /// chunked `WriteBatch`es (≤400 writes each — the Firestore batch limit),
  /// then reports ONE audit entry summarizing the whole operation. Returns
  /// the number of products touched.
  Future<int> bulkUpdate({
    required Map<String, Map<String, dynamic>> changes,
    required String changeDescription,
  });
}
