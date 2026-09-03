import 'dart:async';

import 'package:dukkan/core/errors/failures.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:dukkan/domain/areas/entities/area.dart';
import 'package:dukkan/domain/areas/repositories/areas_repository.dart';
import 'package:dukkan/domain/areas/usecases/get_areas.dart';
import 'package:dukkan/domain/order/entities/address.dart';
import 'package:dukkan/domain/order/entities/order.dart';
import 'package:dukkan/domain/order/entities/order_item.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:dukkan/domain/order/repositories/order_repository.dart';
import 'package:dukkan/domain/order/usecases/watch_driver_active_orders.dart';
import 'package:dukkan/domain/order/usecases/watch_driver_order_history.dart';
import 'package:dukkan/presentation/driver/bloc/deliveries_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Always throws an offline-shaped [ServerFailure] — deterministically keeps
/// an enqueued mutation queued (mirrors the old always-`false`
/// `_FakeNetworkInfo`, now that replay has no upfront connectivity probe to
/// gate on, final-review I3).
Future<void> _neverReaches(String orderId, OrderStatus status) async =>
    throw const ServerFailure('offline', 'unavailable');

/// Drives the courier's two streams by hand (mirrors `_FakeOrderRepository`
/// in owner_orders_bloc_test.dart).
class _FakeOrderRepository implements OrderRepository {
  final activeController = StreamController<List<Order>>.broadcast();
  final historyController = StreamController<List<Order>>.broadcast();

  @override
  Stream<List<Order>> watchDriverActiveOrders(String driverUid) =>
      activeController.stream;

  @override
  Stream<List<Order>> watchDriverHistory(String driverUid) =>
      historyController.stream;

  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) =>
      const Stream.empty();

  @override
  Stream<List<Order>> watchShopOrders(String shopId) => const Stream.empty();

  @override
  Stream<Order> watchOrder(String orderId) => const Stream.empty();

  @override
  Future<void> cancelOrder(String orderId) async {}

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {}

  @override
  Future<void> rateOrder({
    required String orderId,
    required String shopId,
    required int rating,
  }) async {}

  @override
  Future<Order> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required Address deliveryAddress,
    required int subtotalMinor,
    required int deliveryFeeMinor,
    required int commissionBps,
    required int commissionMinor,
    required int driverDeliveryShareMinor,
    required int platformDeliveryShareMinor,
    required int totalMinor,
    String? notes,
    String? couponCode,
    int discountMinor = 0,
  }) async =>
      _order('unused', OrderStatus.pending);
}

class _FakeAreasRepository implements AreasRepository {
  @override
  Future<List<Area>> getAreas() async => const [
        Area(id: 'abu-atwa', nameAr: 'أبو عطوة', nameEn: 'Abu Atwa', sort: 1),
      ];
}

Order _order(String id, OrderStatus status, {DateTime? createdAt}) => Order(
      id: id,
      shopId: 's1',
      customerUid: 'u1',
      items: const [
        OrderItem(
          productId: 'p1',
          name: 'Item',
          nameAr: 'منتج',
          priceMinor: 1000,
          quantity: 1,
        ),
      ],
      totalMinor: 1000,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      deliveryAddress: const Address(
        line1: 'Street 1',
        city: 'Ismailia',
        areaId: 'abu-atwa',
      ),
      driverUid: 'd1',
    );

void main() {
  late _FakeOrderRepository repo;
  late DeliveriesBloc bloc;
  late OfflineMutationQueue queue;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = _FakeOrderRepository();
    queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'd1',
      remoteUpdate: _neverReaches,
    );
    bloc = DeliveriesBloc(
      driverUid: 'd1',
      watchActive: WatchDriverActiveOrders(repo),
      watchHistory: WatchDriverOrderHistory(repo),
      getAreas: GetAreas(_FakeAreasRepository()),
      queue: queue,
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.activeController.close();
    await repo.historyController.close();
    await queue.dispose();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('loads active orders sorted oldest-first', () async {
    bloc.add(const DeliveriesStarted());
    await tick();

    repo.activeController.add([
      _order('newer', OrderStatus.preparing, createdAt: DateTime(2026, 1, 2)),
      _order('older', OrderStatus.outForDelivery, createdAt: DateTime(2026, 1, 1)),
    ]);
    await tick();

    expect(bloc.state.activeStatus, DeliveriesListStatus.loaded);
    expect(bloc.state.activeOrders.map((o) => o.id), ['older', 'newer']);
  });

  test('loads history orders as delivered by the datasource', () async {
    bloc.add(const DeliveriesStarted());
    await tick();

    repo.historyController.add([_order('h1', OrderStatus.delivered)]);
    await tick();

    expect(bloc.state.historyStatus, DeliveriesListStatus.loaded);
    expect(bloc.state.historyOrders.single.id, 'h1');
  });

  test('active stream error surfaces as error status', () async {
    bloc.add(const DeliveriesStarted());
    await tick();

    repo.activeController.addError(Exception('boom'));
    await tick();

    expect(bloc.state.activeStatus, DeliveriesListStatus.error);
  });

  test('resolves the area list once for the card labels', () async {
    bloc.add(const DeliveriesStarted());
    await tick();
    await tick();

    expect(bloc.state.areas.single.id, 'abu-atwa');
  });

  test('tab switch flips which list the page reads', () async {
    bloc.add(const DeliveriesStarted());
    await tick();

    bloc.add(const DeliveriesTabChanged(DeliveriesTab.history));
    await tick();

    expect(bloc.state.tab, DeliveriesTab.history);
  });

  test('a queued mutation for an active order surfaces in pendingStatuses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'd1',
      remoteUpdate: _neverReaches,
    );
    final queuedBloc = DeliveriesBloc(
      driverUid: 'd1',
      watchActive: WatchDriverActiveOrders(repo),
      watchHistory: WatchDriverOrderHistory(repo),
      getAreas: GetAreas(_FakeAreasRepository()),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const DeliveriesStarted());
    await tick();
    repo.activeController.add([_order('a', OrderStatus.preparing)]);
    await tick();

    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'a',
      targetStatus: OrderStatus.outForDelivery,
      actorUid: 'd1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));
    await tick();

    expect(queuedBloc.state.pendingStatuses['a'], OrderStatus.outForDelivery);
  });

  test('an active order not in the queue has no pendingStatuses entry', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'd1',
      remoteUpdate: _neverReaches,
    );
    final queuedBloc = DeliveriesBloc(
      driverUid: 'd1',
      watchActive: WatchDriverActiveOrders(repo),
      watchHistory: WatchDriverOrderHistory(repo),
      getAreas: GetAreas(_FakeAreasRepository()),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const DeliveriesStarted());
    await tick();
    repo.activeController.add([_order('a', OrderStatus.preparing)]);
    await tick();

    expect(queuedBloc.state.pendingStatuses.containsKey('a'), isFalse);
  });

  test(
      'a mutation already queued before the bloc is constructed still surfaces in the initial state',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      currentUidProvider: () => 'd1',
      remoteUpdate: _neverReaches,
    );
    addTearDown(queue.dispose);

    // Queued (and left pending, since _FakeNetworkInfo reports offline)
    // BEFORE the bloc — and therefore its watchAll() subscription — exists.
    // watchAll() never replays to a late subscriber, so this only surfaces
    // if the bloc also reads OfflineMutationQueue.allPending on construction.
    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'a',
      targetStatus: OrderStatus.outForDelivery,
      actorUid: 'd1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));

    final queuedBloc = DeliveriesBloc(
      driverUid: 'd1',
      watchActive: WatchDriverActiveOrders(repo),
      watchHistory: WatchDriverOrderHistory(repo),
      getAreas: GetAreas(_FakeAreasRepository()),
      queue: queue,
    );
    addTearDown(queuedBloc.close);

    expect(queuedBloc.state.pendingStatuses['a'], OrderStatus.outForDelivery);
  });
}
