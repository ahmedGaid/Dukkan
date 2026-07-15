import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/get_all_shops.dart';
import '../../../../domain/admin/usecases/get_products.dart';
import '../../../../domain/admin/usecases/get_users.dart';
import '../../../../domain/devtools/entities/health_check_result.dart';
import '../../../../domain/devtools/entities/migration_status.dart';
import '../../../../domain/devtools/usecases/cleanup_fake_data.dart';
import '../../../../domain/devtools/usecases/clear_devtools_caches.dart';
import '../../../../domain/devtools/usecases/generate_fake_customers.dart';
import '../../../../domain/devtools/usecases/generate_fake_orders.dart';
import '../../../../domain/devtools/usecases/get_migrations.dart';
import '../../../../domain/devtools/usecases/run_demo_seed.dart';
import '../../../../domain/devtools/usecases/run_health_checks.dart';
import '../../../../domain/devtools/usecases/run_migration.dart';
import '../../../../domain/notifications_admin/usecases/send_direct_notification.dart';
import '../../../../domain/shop/entities/shop.dart';

part 'devtools_event.dart';
part 'devtools_state.dart';

/// Drives the console devtools page (`/console/devtools`, FC15,
/// `system.tools`, founder-only for seed/fakes). [actorUid] is the
/// signed-in founder's own uid — the target of the test-notification tool.
class DevToolsBloc extends Bloc<DevToolsEvent, DevToolsState> {
  DevToolsBloc({
    required this.actorUid,
    required GetAllShops getAllShops,
    required GetProducts getProducts,
    required GetUsers getUsers,
    required SendDirectNotification sendDirectNotification,
    required RunHealthChecks runHealthChecks,
    required RunDemoSeed runDemoSeed,
    required GenerateFakeCustomers generateFakeCustomers,
    required GenerateFakeOrders generateFakeOrders,
    required CleanupFakeData cleanupFakeData,
    required ClearDevToolsCaches clearDevToolsCaches,
    required GetMigrations getMigrations,
    required RunMigration runMigration,
  })  : _getAllShops = getAllShops,
        _getProducts = getProducts,
        _getUsers = getUsers,
        _sendDirectNotification = sendDirectNotification,
        _runHealthChecks = runHealthChecks,
        _runDemoSeed = runDemoSeed,
        _generateFakeCustomers = generateFakeCustomers,
        _generateFakeOrders = generateFakeOrders,
        _cleanupFakeData = cleanupFakeData,
        _clearDevToolsCaches = clearDevToolsCaches,
        _getMigrations = getMigrations,
        _runMigration = runMigration,
        super(const DevToolsState()) {
    on<DevToolsStarted>(_onStarted);
    on<DevToolsHealthCheckRequested>(_onHealthCheck);
    on<DevToolsSeedRequested>(_onSeed);
    on<DevToolsFakeCustomersRequested>(_onFakeCustomers);
    on<DevToolsShopSelected>(
      (event, emit) => emit(state.copyWith(selectedShopId: event.shopId)),
    );
    on<DevToolsFakeOrdersRequested>(_onFakeOrders);
    on<DevToolsFakeCleanupRequested>(_onFakeCleanup);
    on<DevToolsCachesClearRequested>(_onCachesClear);
    on<DevToolsTestNotificationRequested>(_onTestNotification);
    on<DevToolsMigrationRunRequested>(_onMigrationRun);

    add(const DevToolsStarted());
  }

  final String actorUid;
  final GetAllShops _getAllShops;
  final GetProducts _getProducts;
  final GetUsers _getUsers;
  final SendDirectNotification _sendDirectNotification;
  final RunHealthChecks _runHealthChecks;
  final RunDemoSeed _runDemoSeed;
  final GenerateFakeCustomers _generateFakeCustomers;
  final GenerateFakeOrders _generateFakeOrders;
  final CleanupFakeData _cleanupFakeData;
  final ClearDevToolsCaches _clearDevToolsCaches;
  final GetMigrations _getMigrations;
  final RunMigration _runMigration;

  Future<void> _onStarted(DevToolsStarted event, Emitter<DevToolsState> emit) async {
    emit(state.copyWith(status: DevToolsPageStatus.loading));
    try {
      final shopsFuture = _getAllShops();
      final migrationsFuture = _getMigrations();
      final shops = await shopsFuture;
      final migrations = await migrationsFuture;
      emit(state.copyWith(
        status: DevToolsPageStatus.loaded,
        shops: shops,
        selectedShopId: shops.isEmpty ? null : shops.first.id,
        migrations: migrations,
      ));
    } catch (_) {
      emit(state.copyWith(status: DevToolsPageStatus.error));
    }
  }

  Set<String> _busyPlus(String tool) => {...state.busyTools, tool};
  Set<String> _busyMinus(String tool) => {...state.busyTools}..remove(tool);

  Future<void> _onHealthCheck(
    DevToolsHealthCheckRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    if (state.isBusy('health')) return;
    emit(state.copyWith(busyTools: _busyPlus('health')));
    final results = await _runHealthChecks();
    emit(state.copyWith(healthResults: results, busyTools: _busyMinus('health')));
  }

  Future<void> _onSeed(DevToolsSeedRequested event, Emitter<DevToolsState> emit) async {
    if (state.isBusy('seed')) return;
    emit(state.copyWith(busyTools: _busyPlus('seed'), clearError: true));
    try {
      await _runDemoSeed(rbac: event.rbac, catalog: event.catalog, customers: event.customers);
      emit(state.copyWith(busyTools: _busyMinus('seed'), seedOk: true));
    } catch (e) {
      emit(state.copyWith(
        busyTools: _busyMinus('seed'),
        seedOk: false,
        errorTool: 'seed',
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFakeCustomers(
    DevToolsFakeCustomersRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    if (state.isBusy('fakeCustomers')) return;
    emit(state.copyWith(busyTools: _busyPlus('fakeCustomers'), clearError: true));
    try {
      final uids = await _generateFakeCustomers(event.count);
      emit(state.copyWith(
        busyTools: _busyMinus('fakeCustomers'),
        fakeCustomersCreated: uids.length,
      ));
    } catch (e) {
      emit(state.copyWith(
        busyTools: _busyMinus('fakeCustomers'),
        errorTool: 'fakeCustomers',
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFakeOrders(
    DevToolsFakeOrdersRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    final shopId = state.selectedShopId;
    if (shopId == null || state.isBusy('fakeOrders')) return;
    emit(state.copyWith(busyTools: _busyPlus('fakeOrders'), clearError: true));
    try {
      final productsFuture = _getProducts(shopId: shopId);
      final usersFuture = _getUsers(role: 'customer');
      final productsPage = await productsFuture;
      final usersPage = await usersFuture;
      final products = productsPage.products
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'nameAr': p.nameAr,
                'priceMinor': p.priceMinor,
              })
          .toList();
      final customerUids = usersPage.users.map((u) => u.uid).take(20).toList();
      if (products.isEmpty || customerUids.isEmpty) {
        throw StateError('no products or customers to build orders from');
      }
      final created = await _generateFakeOrders(
        shopId: shopId,
        products: products,
        customerUids: customerUids,
        count: event.count,
      );
      emit(state.copyWith(busyTools: _busyMinus('fakeOrders'), fakeOrdersCreated: created));
    } catch (e) {
      emit(state.copyWith(
        busyTools: _busyMinus('fakeOrders'),
        errorTool: 'fakeOrders',
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFakeCleanup(
    DevToolsFakeCleanupRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    if (state.isBusy('fakeCleanup')) return;
    emit(state.copyWith(busyTools: _busyPlus('fakeCleanup'), clearError: true));
    try {
      final count = await _cleanupFakeData();
      emit(state.copyWith(busyTools: _busyMinus('fakeCleanup'), fakeCleanupCount: count));
    } catch (e) {
      emit(state.copyWith(
        busyTools: _busyMinus('fakeCleanup'),
        errorTool: 'fakeCleanup',
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCachesClear(
    DevToolsCachesClearRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    if (state.isBusy('caches')) return;
    emit(state.copyWith(busyTools: _busyPlus('caches'), clearError: true));
    try {
      await _clearDevToolsCaches();
      emit(state.copyWith(busyTools: _busyMinus('caches'), cachesCleared: true));
    } catch (e) {
      emit(state.copyWith(
        busyTools: _busyMinus('caches'),
        errorTool: 'caches',
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onTestNotification(
    DevToolsTestNotificationRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    if (state.isBusy('notify')) return;
    emit(state.copyWith(busyTools: _busyPlus('notify'), clearError: true));
    try {
      await _sendDirectNotification(
        uid: actorUid,
        title: 'إشعار تجريبي',
        body: 'هذا إشعار تجريبي من أدوات المطوّر.',
      );
      emit(state.copyWith(busyTools: _busyMinus('notify'), notifySent: true));
    } catch (e) {
      emit(state.copyWith(
        busyTools: _busyMinus('notify'),
        notifySent: false,
        errorTool: 'notify',
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onMigrationRun(
    DevToolsMigrationRunRequested event,
    Emitter<DevToolsState> emit,
  ) async {
    if (state.isBusy(event.id)) return;
    emit(state.copyWith(busyTools: _busyPlus(event.id), clearError: true));
    try {
      await _runMigration(event.id);
      final migrations = await _getMigrations();
      emit(state.copyWith(busyTools: _busyMinus(event.id), migrations: migrations));
    } catch (e) {
      emit(state.copyWith(
        busyTools: _busyMinus(event.id),
        errorTool: event.id,
        errorMessage: e.toString(),
      ));
    }
  }
}
