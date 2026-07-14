import 'dart:async';

import '../../../domain/admin/repositories/admin_taxonomy_repository.dart';
import '../../../domain/taxonomy/entities/category.dart';
import '../datasources/admin_api_datasource.dart';
import '../datasources/admin_taxonomy_remote_datasource.dart';

/// No cache — the console must always reflect the latest tree (mirrors
/// `AdminShopsRepositoryImpl`). Every mutation is Firestore-direct + a
/// best-effort [AdminApiDataSource.reportAudit].
class AdminTaxonomyRepositoryImpl implements AdminTaxonomyRepository {
  AdminTaxonomyRepositoryImpl(this._remote, this._api);

  final AdminTaxonomyRemoteDataSource _remote;
  final AdminApiDataSource _api;

  @override
  Future<List<Category>> getAllCategories() => _remote.getAllCategories();

  @override
  Future<void> createCategory({
    required String nameAr,
    required String nameEn,
    String? iconName,
  }) async {
    final existing = await _remote.getAllCategories();
    final nextSort = existing.isEmpty
        ? 0
        : existing.map((c) => c.sort).reduce((a, b) => a > b ? a : b) + 1;
    await _remote.createCategory({
      'nameAr': nameAr,
      'nameEn': nameEn,
      'sort': nextSort,
      'subcategories': const [],
      'isVisible': true,
      'iconName': iconName,
    });
    unawaited(_api.reportAudit(
      action: 'taxonomy.create',
      targetType: 'taxonomy',
      targetId: nameAr,
      after: {'nameAr': nameAr, 'nameEn': nameEn},
    ));
  }

  @override
  Future<void> updateCategory({
    required String categoryId,
    required String nameAr,
    required String nameEn,
    String? iconName,
  }) async {
    final fields = {'nameAr': nameAr, 'nameEn': nameEn, 'iconName': iconName};
    await _remote.patchFields(categoryId, fields);
    unawaited(_api.reportAudit(
      action: 'taxonomy.update',
      targetType: 'taxonomy',
      targetId: categoryId,
      after: fields,
    ));
  }

  @override
  Future<void> setCategoryVisible({
    required String categoryId,
    required bool value,
  }) async {
    await _remote.patchFields(categoryId, {'isVisible': value});
    unawaited(_api.reportAudit(
      action: 'taxonomy.update',
      targetType: 'taxonomy',
      targetId: categoryId,
      after: {'isVisible': value},
    ));
  }

  @override
  Future<void> swapSort({
    required String aId,
    required int aSort,
    required String bId,
    required int bSort,
  }) async {
    await _remote.swapSort(aId: aId, aSort: aSort, bId: bId, bSort: bSort);
    unawaited(_api.reportAudit(
      action: 'taxonomy.update',
      targetType: 'taxonomy',
      targetId: aId,
      after: {'reorderedWith': bId},
    ));
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _remote.deleteCategory(categoryId);
    unawaited(_api.reportAudit(
      action: 'taxonomy.delete',
      targetType: 'taxonomy',
      targetId: categoryId,
    ));
  }

  @override
  Future<int> countProductsInCategory(String categoryId) =>
      _remote.countProductsInCategory(categoryId);
}
