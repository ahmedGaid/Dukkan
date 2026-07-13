import 'dart:async';

import '../../../domain/admin/entities/products_page.dart';
import '../../../domain/admin/repositories/admin_products_repository.dart';
import '../../../domain/product/entities/product.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_products_remote_datasource.dart';

/// No cache — the console must always reflect the latest catalog state (same
/// contract as `AdminShopsRepositoryImpl`). Every mutation is Firestore-direct
/// plus a best-effort [AdminApiDataSource.reportAudit].
class AdminProductsRepositoryImpl implements AdminProductsRepository {
  AdminProductsRepositoryImpl(this._remote, this._api);

  final AdminProductsRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<ProductsPage> getProducts({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    bool deletedOnly = false,
    String? cursor,
  }) =>
      _remote.getProducts(
        shopId: shopId,
        category: category,
        subcategoryId: subcategoryId,
        stockStatus: stockStatus,
        isPromo: isPromo,
        deletedOnly: deletedOnly,
        cursor: cursor,
      );

  @override
  Future<List<Product>> getAllMatching({
    String? shopId,
    String? category,
    String? subcategoryId,
    String? stockStatus,
    bool? isPromo,
    bool deletedOnly = false,
  }) =>
      _remote.getAllMatching(
        shopId: shopId,
        category: category,
        subcategoryId: subcategoryId,
        stockStatus: stockStatus,
        isPromo: isPromo,
        deletedOnly: deletedOnly,
      );

  @override
  Future<void> patchFields(String productId, Map<String, dynamic> fields) async {
    await _remote.patchFields(productId, fields);
    unawaited(_api.reportAudit(
      action: 'product.update',
      targetType: 'product',
      targetId: productId,
      after: fields,
    ));
  }

  @override
  Future<void> softDelete({required String productId, required String actorUid}) async {
    await _remote.softDelete(productId, actorUid);
    unawaited(_api.reportAudit(
      action: 'product.softDelete',
      targetType: 'product',
      targetId: productId,
      after: {'deleted': true},
    ));
  }

  @override
  Future<void> restore(String productId) async {
    await _remote.restore(productId);
    unawaited(_api.reportAudit(
      action: 'product.restore',
      targetType: 'product',
      targetId: productId,
      after: {'deleted': false},
    ));
  }

  @override
  Future<String> duplicate(String productId) async {
    final newId = await _remote.duplicate(productId);
    unawaited(_api.reportAudit(
      action: 'product.duplicate',
      targetType: 'product',
      targetId: newId,
      after: {'duplicatedFrom': productId},
    ));
    return newId;
  }

  @override
  Future<void> hardDelete(String productId) async {
    await _remote.hardDelete(productId);
    unawaited(_api.reportAudit(
      action: 'product.hardDelete',
      targetType: 'product',
      targetId: productId,
    ));
  }

  @override
  Future<int> bulkUpdate({
    required Map<String, Map<String, dynamic>> changes,
    required String changeDescription,
  }) async {
    final count = await _remote.bulkWrite(changes);
    unawaited(_api.reportAudit(
      action: 'product.bulkUpdate',
      targetType: 'product',
      targetId: 'bulk',
      after: {'count': count, 'change': changeDescription},
    ));
    return count;
  }
}
