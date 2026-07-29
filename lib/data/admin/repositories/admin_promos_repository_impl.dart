import 'dart:async';

import '../../../domain/admin/repositories/admin_promos_repository.dart';
import '../../../domain/promos/entities/coupon.dart';
import '../../../domain/promos/entities/promo_banner.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_promos_remote_datasource.dart';
import '../../promos/models/coupon_model.dart';
import '../../promos/models/promo_banner_model.dart';

/// No cache — the console must always reflect the latest state (mirrors
/// `AdminTaxonomyRepositoryImpl`). Every mutation is Firestore-direct + a
/// best-effort `reportAudit`.
class AdminPromosRepositoryImpl implements AdminPromosRepository {
  AdminPromosRepositoryImpl(this._remote, this._api);

  final AdminPromosRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<List<Coupon>> getAllCoupons() => _remote.getAllCoupons();

  @override
  Future<void> createCoupon(Coupon coupon) async {
    final model = CouponModel(
      code: coupon.code,
      type: coupon.type,
      valueBps: coupon.valueBps,
      valueMinor: coupon.valueMinor,
      minOrderMinor: coupon.minOrderMinor,
      expiresAt: coupon.expiresAt,
      maxUses: coupon.maxUses,
      isActive: coupon.isActive,
    );
    await _remote.createCoupon(coupon.code, model.toFirestore());
    unawaited(_api.reportAudit(
      action: 'coupon.create',
      targetType: 'coupon',
      targetId: coupon.code,
      after: model.toFirestore(),
    ));
  }

  @override
  Future<void> updateCoupon(Coupon coupon) async {
    final model = CouponModel(
      code: coupon.code,
      type: coupon.type,
      valueBps: coupon.valueBps,
      valueMinor: coupon.valueMinor,
      minOrderMinor: coupon.minOrderMinor,
      expiresAt: coupon.expiresAt,
      maxUses: coupon.maxUses,
      usedCount: coupon.usedCount,
      isActive: coupon.isActive,
    );
    final fields = model.toFirestore()..remove('usedCount');
    await _remote.setCouponFields(coupon.code, fields);
    unawaited(_api.reportAudit(
      action: 'coupon.update',
      targetType: 'coupon',
      targetId: coupon.code,
      after: fields,
    ));
  }

  @override
  Future<void> setCouponActive({required String code, required bool value}) async {
    await _remote.setCouponFields(code, {'isActive': value});
    unawaited(_api.reportAudit(
      action: 'coupon.update',
      targetType: 'coupon',
      targetId: code,
      after: {'isActive': value},
    ));
  }

  @override
  Future<void> deleteCoupon(String code) async {
    await _remote.deleteCoupon(code);
    unawaited(_api.reportAudit(
      action: 'coupon.delete',
      targetType: 'coupon',
      targetId: code,
    ));
  }

  @override
  Future<List<PromoBanner>> getAllBanners() => _remote.getAllBanners();

  @override
  Future<void> createBanner({
    required String imageUrl,
    required BannerTargetType targetType,
    String? targetId,
    String? targetShopId,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final existing = await _remote.getAllBanners();
    final nextSort = existing.isEmpty
        ? 0
        : existing.map((b) => b.sort).reduce((a, b) => a > b ? a : b) + 1;
    final model = PromoBannerModel(
      id: '',
      imageUrl: imageUrl,
      targetType: targetType,
      targetId: targetId,
      targetShopId: targetShopId,
      sort: nextSort,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    await _remote.createBanner(model.toFirestore());
    unawaited(_api.reportAudit(
      action: 'banner.create',
      targetType: 'banner',
      targetId: imageUrl,
      after: model.toFirestore(),
    ));
  }

  @override
  Future<void> updateBanner(PromoBanner banner) async {
    final model = PromoBannerModel(
      id: banner.id,
      imageUrl: banner.imageUrl,
      targetType: banner.targetType,
      targetId: banner.targetId,
      targetShopId: banner.targetShopId,
      sort: banner.sort,
      isActive: banner.isActive,
      startsAt: banner.startsAt,
      endsAt: banner.endsAt,
    );
    final fields = model.toFirestore()..remove('sort');
    await _remote.setBannerFields(banner.id, fields);
    unawaited(_api.reportAudit(
      action: 'banner.update',
      targetType: 'banner',
      targetId: banner.id,
      after: fields,
    ));
  }

  @override
  Future<void> setBannerActive({required String id, required bool value}) async {
    await _remote.setBannerFields(id, {'isActive': value});
    unawaited(_api.reportAudit(
      action: 'banner.update',
      targetType: 'banner',
      targetId: id,
      after: {'isActive': value},
    ));
  }

  @override
  Future<void> swapBannerSort({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  }) async {
    await _remote.swapBannerSort(aId: aId, aSort: aSort, bId: bId, bSort: bSort);
    unawaited(_api.reportAudit(
      action: 'banner.update',
      targetType: 'banner',
      targetId: aId,
      after: {'reorderedWith': bId},
    ));
  }

  @override
  Future<void> deleteBanner(String id) async {
    await _remote.deleteBanner(id);
    unawaited(_api.reportAudit(
      action: 'banner.delete',
      targetType: 'banner',
      targetId: id,
    ));
  }
}
