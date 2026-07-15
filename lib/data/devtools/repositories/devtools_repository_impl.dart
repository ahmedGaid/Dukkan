import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../dev/migrations/registry.dart' as migration_registry;
import '../../../dev/seed.dart' as seed;
import '../../../domain/config/repositories/flags_repository.dart';
import '../../../domain/config/repositories/platform_config_repository.dart';
import '../../../domain/devtools/entities/health_check_result.dart';
import '../../../domain/devtools/entities/migration_status.dart';
import '../../../domain/devtools/repositories/devtools_repository.dart';
import '../../admin/datasources/admin_api_datasource.dart';
import '../../areas/datasources/areas_local_datasource.dart';
import '../../product/datasources/product_local_datasource.dart';
import '../../shop/datasources/shop_local_datasource.dart';
import '../../taxonomy/datasources/taxonomy_local_datasource.dart';

/// Mixes Worker-routed ops (fake data) with Firestore-direct ones (seed,
/// caches, migrations) — see `DevToolsRepository`'s doc for why each side
/// takes the path it does. No separate remote datasource: everything here
/// is a thin pass-through to either `AdminApiDataSource.post` or a raw
/// Firestore call, none of it warrants its own parsing layer.
class DevToolsRepositoryImpl implements DevToolsRepository {
  DevToolsRepositoryImpl({
    required FirebaseFirestore firestore,
    required AdminApiDataSource api,
    required TaxonomyLocalDataSource taxonomyLocal,
    required AreasLocalDataSource areasLocal,
    required ShopLocalDataSource shopLocal,
    required ProductLocalDataSource productLocal,
    required PlatformConfigRepository platformConfigRepository,
    required FlagsRepository flagsRepository,
  })  : _firestore = firestore,
        _api = api,
        _taxonomyLocal = taxonomyLocal,
        _areasLocal = areasLocal,
        _shopLocal = shopLocal,
        _productLocal = productLocal,
        _platformConfigRepository = platformConfigRepository,
        _flagsRepository = flagsRepository;

  final FirebaseFirestore _firestore;
  final AdminApiDataSource _api;
  final TaxonomyLocalDataSource _taxonomyLocal;
  final AreasLocalDataSource _areasLocal;
  final ShopLocalDataSource _shopLocal;
  final ProductLocalDataSource _productLocal;
  final PlatformConfigRepository _platformConfigRepository;
  final FlagsRepository _flagsRepository;

  @override
  Future<List<HealthCheckResult>> runHealthChecks() async {
    return [
      await _timed('workerPing', () => _api.post('ping', const {})),
      await _timed(
        'firestoreRead',
        () => _firestore.collection('config').doc('platform').get(),
      ),
      await _timed('configSanity', () async {
        final doc = await _firestore.collection('config').doc('platform').get();
        final data = doc.data();
        if (data == null) throw StateError('missing /config/platform');
        for (final key in ['commissionBps', 'deliveryFeeMinor', 'driverDeliveryShareMinor']) {
          if (data[key] == null) throw StateError('missing field $key');
        }
        final driverShare = (data['driverDeliveryShareMinor'] as num).toInt();
        final deliveryFee = (data['deliveryFeeMinor'] as num).toInt();
        if (driverShare > deliveryFee) {
          throw StateError('driverDeliveryShareMinor > deliveryFeeMinor');
        }
      }),
      await _timed('taxonomyNonEmpty', () async {
        final snap = await _firestore.collection('categories').limit(1).get();
        if (snap.docs.isEmpty) throw StateError('no categories');
      }),
      await _timed('areasNonEmpty', () async {
        final snap = await _firestore.collection('areas').limit(1).get();
        if (snap.docs.isEmpty) throw StateError('no areas');
      }),
      await _timed('activeDriverExists', () async {
        final snap = await _firestore
            .collection('drivers')
            .where('isOnline', isEqualTo: true)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) throw StateError('no online driver');
      }),
    ];
  }

  Future<HealthCheckResult> _timed(String id, Future<void> Function() action) async {
    final stopwatch = Stopwatch()..start();
    try {
      await action();
      return HealthCheckResult(id: id, ok: true, latencyMs: stopwatch.elapsedMilliseconds);
    } catch (e) {
      return HealthCheckResult(
        id: id,
        ok: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<void> runDemoSeed({
    required bool rbac,
    required bool catalog,
    required bool customers,
  }) async {
    final log = StringBuffer();
    await seed.runSeed(
      _firestore,
      rbac: rbac,
      catalog: catalog,
      customers: customers,
      log: log,
    );
    await _api.reportAudit(
      action: 'devtools.seed',
      targetType: 'devtools',
      targetId: 'seed',
      after: {'rbac': rbac, 'catalog': catalog, 'customers': customers},
    );
  }

  @override
  Future<List<String>> generateFakeCustomers(int count) async {
    final result = await _api.post('devtools/fake-customers', {'count': count});
    return List<String>.from(result['uids'] as List? ?? const []);
  }

  @override
  Future<int> generateFakeOrders({
    required String shopId,
    required List<Map<String, dynamic>> products,
    required List<String> customerUids,
    required int count,
  }) async {
    final result = await _api.post('devtools/fake-orders', {
      'shopId': shopId,
      'count': count,
      'products': products,
      'customerUids': customerUids,
    });
    return (result['ids'] as List? ?? const []).length;
  }

  @override
  Future<int> cleanupFakeData() async {
    final result = await _api.post('devtools/fake-cleanup', const {});
    return (result['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> clearCaches() async {
    await Future.wait([
      _taxonomyLocal.clear(),
      _areasLocal.clear(),
      _shopLocal.clear(),
      _productLocal.clear(),
      _platformConfigRepository.refresh(),
      _flagsRepository.refresh(),
    ]);
    await _api.reportAudit(
      action: 'devtools.clearCaches',
      targetType: 'devtools',
      targetId: 'caches',
    );
  }

  @override
  Future<List<MigrationStatus>> getMigrations() async {
    final doc = await _firestore.collection('config').doc('migrations').get();
    final applied = Set<String>.from((doc.data()?['applied'] as List?) ?? const []);
    return migration_registry.migrations
        .map((m) => MigrationStatus(
              id: m.id,
              description: m.description,
              applied: applied.contains(m.id),
            ))
        .toList(growable: false);
  }

  @override
  Future<void> runMigration(String id) async {
    final migration = migration_registry.migrations.firstWhere(
      (m) => m.id == id,
      orElse: () => throw StateError('unknown migration $id'),
    );
    await migration.run(_firestore);
    await _firestore.collection('config').doc('migrations').update({
      'applied': FieldValue.arrayUnion([id]),
    });
    await _api.reportAudit(
      action: 'devtools.migration',
      targetType: 'devtools',
      targetId: id,
    );
  }
}
