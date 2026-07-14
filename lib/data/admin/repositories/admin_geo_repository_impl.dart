import 'dart:async';

import '../../../domain/admin/repositories/admin_geo_repository.dart';
import '../../../domain/areas/entities/area.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_geo_remote_datasource.dart';

/// No cache — the console must always reflect the latest list (mirrors
/// `AdminTaxonomyRepositoryImpl`). Every mutation is Firestore-direct + a
/// best-effort [AdminApiDataSource.reportAudit].
class AdminGeoRepositoryImpl implements AdminGeoRepository {
  AdminGeoRepositoryImpl(this._remote, this._api);

  final AdminGeoRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<List<Area>> getAllAreas() => _remote.getAllAreas();

  @override
  Future<void> createArea({
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String city,
    int? deliveryFeeMinorOverride,
  }) async {
    final existing = await _remote.getAllAreas();
    final nextSort = existing.isEmpty
        ? 0
        : existing.map((a) => a.sort).reduce((a, b) => a > b ? a : b) + 1;
    await _remote.createArea({
      'nameAr': nameAr,
      'nameEn': nameEn,
      'sort': nextSort,
      'governorate': governorate,
      'city': city,
      'isActive': true,
      'deliveryFeeMinorOverride': deliveryFeeMinorOverride,
    });
    unawaited(_api.reportAudit(
      action: 'area.create',
      targetType: 'area',
      targetId: nameAr,
      after: {'nameAr': nameAr, 'nameEn': nameEn, 'governorate': governorate, 'city': city},
    ));
  }

  @override
  Future<void> updateArea({
    required String areaId,
    required String nameAr,
    required String nameEn,
    required String governorate,
    required String city,
    int? deliveryFeeMinorOverride,
  }) async {
    final fields = {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'governorate': governorate,
      'city': city,
      'deliveryFeeMinorOverride': deliveryFeeMinorOverride,
    };
    await _remote.patchFields(areaId, fields);
    unawaited(_api.reportAudit(
      action: 'area.update',
      targetType: 'area',
      targetId: areaId,
      after: fields,
    ));
  }

  @override
  Future<void> setAreaActive({required String areaId, required bool value}) async {
    await _remote.patchFields(areaId, {'isActive': value});
    unawaited(_api.reportAudit(
      action: 'area.update',
      targetType: 'area',
      targetId: areaId,
      after: {'isActive': value},
    ));
  }

  @override
  Future<void> deleteArea(String areaId) async {
    await _remote.deleteArea(areaId);
    unawaited(_api.reportAudit(
      action: 'area.delete',
      targetType: 'area',
      targetId: areaId,
    ));
  }

  @override
  Future<int> countOrdersInArea(String areaId) => _remote.countOrdersInArea(areaId);
}
