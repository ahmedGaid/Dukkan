import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/admin/entities/products_page.dart';
import '../../product/models/product_model.dart';

/// Firestore-direct reads/writes of `/products` for the console (FC8).
/// Ordered by document id — never a data field — so pagination never depends
/// on a field that might be absent or mixed-type on legacy docs (same
/// reasoning as `AdminUsersRemoteDataSource`).
class AdminProductsRemoteDataSource {
  AdminProductsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const pageSize = 25;

  /// The Firestore batched-write limit — bulk ops chunk into groups this size.
  static const _batchLimit = 400;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  Query<Map<String, dynamic>> _filtered({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    required bool deletedOnly,
  }) {
    Query<Map<String, dynamic>> q = _products;
    if (shopId != null) q = q.where('shopId', isEqualTo: shopId);
    if (category != null) q = q.where('category', isEqualTo: category);
    if (subcategoryId != null) {
      q = q.where('subcategoryId', isEqualTo: subcategoryId);
    }
    if (stockStatus != null) q = q.where('stockStatus', isEqualTo: stockStatus);
    if (isPromo != null) q = q.where('isPromo', isEqualTo: isPromo);
    return q.where('deleted', isEqualTo: deletedOnly);
  }

  Future<ProductsPage> getProducts({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    required bool deletedOnly,
    String? cursor,
  }) async {
    try {
      var q = _filtered(
        shopId: shopId,
        category: category,
        subcategoryId: subcategoryId,
        stockStatus: stockStatus,
        isPromo: isPromo,
        deletedOnly: deletedOnly,
      ).orderBy(FieldPath.documentId);
      if (cursor != null) q = q.startAfter([cursor]);
      q = q.limit(pageSize);

      final snap = await q.get();
      final products = snap.docs
          .map((d) => ProductModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
      return ProductsPage(products: products, hasMore: products.length == pageSize);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<List<ProductModel>> getAllMatching({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    required bool deletedOnly,
  }) async {
    try {
      final snap = await _filtered(
        shopId: shopId,
        category: category,
        subcategoryId: subcategoryId,
        stockStatus: stockStatus,
        isPromo: isPromo,
        deletedOnly: deletedOnly,
      ).get();
      return snap.docs
          .map((d) => ProductModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> patchFields(String productId, Map<String, dynamic> fields) async {
    try {
      await _products.doc(productId).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> softDelete(String productId, String actorUid) async {
    try {
      await _products.doc(productId).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': actorUid,
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> restore(String productId) async {
    try {
      await _products.doc(productId).update({
        'deleted': false,
        'deletedAt': null,
        'deletedBy': null,
      });
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  /// Reads [productId], writes an independent copy with " (نسخة)" appended to
  /// both names and `isPromo`/`isFeatured` cleared. Returns the new doc id.
  Future<String> duplicate(String productId) async {
    try {
      final doc = await _products.doc(productId).get();
      final data = doc.data();
      if (data == null) throw ServerFailure('Product $productId not found');
      final source = ProductModel.fromFirestore(doc.id, data);
      final copy = ProductModel(
        id: '',
        shopId: source.shopId,
        name: '${source.name} (نسخة)',
        nameAr: '${source.nameAr} (نسخة)',
        priceMinor: source.priceMinor,
        category: source.category,
        stockStatus: source.stockStatus,
        isPromo: false,
        imageUrl: source.imageUrl,
        subcategoryId: source.subcategoryId,
        collectionIds: source.collectionIds,
        isFeatured: false,
      );
      final created = await _products.add(copy.toFirestore());
      return created.id;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> hardDelete(String productId) async {
    try {
      await _products.doc(productId).delete();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  /// Chunks [changes] (productId → field map) into `WriteBatch`es of at most
  /// [_batchLimit] writes and commits them sequentially. Returns the number
  /// of products touched.
  Future<int> bulkWrite(Map<String, Map<String, dynamic>> changes) async {
    final entries = changes.entries.toList(growable: false);
    try {
      for (var i = 0; i < entries.length; i += _batchLimit) {
        final chunk = entries.skip(i).take(_batchLimit);
        final batch = _firestore.batch();
        for (final entry in chunk) {
          batch.update(_products.doc(entry.key), entry.value);
        }
        await batch.commit();
      }
      return entries.length;
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
