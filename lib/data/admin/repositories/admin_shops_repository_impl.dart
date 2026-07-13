import 'dart:async';

import '../../../domain/admin/repositories/admin_shops_repository.dart';
import '../../../domain/shop/entities/shop.dart';
import '../../shop/models/shop_model.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_shops_remote_datasource.dart';

/// No cache — the console must always reflect the latest moderation state
/// (same contract as `AdminUsersRepositoryImpl`). Every mutation except
/// [transferOwnership] is Firestore-direct + a best-effort
/// [AdminApiDataSource.reportAudit]; transfer is Worker-routed (audited
/// server-side, see `worker/src/admin.js`).
class AdminShopsRepositoryImpl implements AdminShopsRepository {
  AdminShopsRepositoryImpl(this._remote, this._api);

  final AdminShopsRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<List<Shop>> getAllShops() => _remote.getAllShops();

  @override
  Future<Shop?> getShopById(String shopId) => _remote.getShopById(shopId);

  @override
  Future<void> setStatus({
    required String shopId,
    required String status,
    String? reason,
  }) async {
    await _remote.patchFields(shopId, {'status': status});
    unawaited(_api.reportAudit(
      action: 'shop.status',
      targetType: 'shop',
      targetId: shopId,
      after: {'status': status},
      reason: reason,
    ));
  }

  @override
  Future<void> setFeatured({required String shopId, required bool value}) async {
    await _remote.patchFields(shopId, {'isFeatured': value});
    unawaited(_api.reportAudit(
      action: 'shop.feature',
      targetType: 'shop',
      targetId: shopId,
      after: {'isFeatured': value},
    ));
  }

  @override
  Future<void> setVerified({required String shopId, required bool value}) async {
    await _remote.patchFields(shopId, {'isVerified': value});
    unawaited(_api.reportAudit(
      action: 'shop.verify',
      targetType: 'shop',
      targetId: shopId,
      after: {'isVerified': value},
    ));
  }

  @override
  Future<void> updateDetails({
    required String shopId,
    required String name,
    required String nameAr,
    required String address,
    required bool isOpen,
    String? logoUrl,
    String? hoursNote,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'nameAr': nameAr,
      'address': address,
      'isOpen': isOpen,
      'logoUrl': ?logoUrl,
      'hoursNote': hoursNote,
    };
    await _remote.patchFields(shopId, fields);
    unawaited(_api.reportAudit(
      action: 'shop.edit',
      targetType: 'shop',
      targetId: shopId,
      after: fields,
    ));
  }

  @override
  Future<void> softDelete({required String shopId, required String actorUid}) async {
    await _remote.softDelete(shopId, actorUid);
    unawaited(_api.reportAudit(
      action: 'shop.softDelete',
      targetType: 'shop',
      targetId: shopId,
      after: {'deleted': true},
    ));
  }

  @override
  Future<void> restore(String shopId) async {
    await _remote.restore(shopId);
    unawaited(_api.reportAudit(
      action: 'shop.restore',
      targetType: 'shop',
      targetId: shopId,
      after: {'deleted': false},
    ));
  }

  @override
  Future<Shop> createShop({
    required String ownerUid,
    required String name,
    required String nameAr,
    required String address,
    String? logoUrl,
    bool isOpen = true,
    List<String> categories = const [],
    String status = 'active',
  }) async {
    final created = await _remote.createShop(ShopModel(
      id: '',
      ownerUid: ownerUid,
      name: name,
      nameAr: nameAr,
      logoUrl: logoUrl,
      address: address,
      isOpen: isOpen,
      categories: categories,
      status: status,
    ));
    unawaited(_api.reportAudit(
      action: 'shop.edit',
      targetType: 'shop',
      targetId: created.id,
      after: {'created': true, 'ownerUid': ownerUid, 'status': status},
    ));
    return created;
  }

  @override
  Future<Map<String, dynamic>> transferOwnership({
    required String shopId,
    required String newOwnerUid,
  }) =>
      _api.post('shops/transfer', {'shopId': shopId, 'newOwnerUid': newOwnerUid});
}
