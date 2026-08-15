import 'dart:async';

import 'package:dukkan/core/network/network_info.dart';
import 'package:dukkan/core/offline/offline_mutation_queue.dart';
import 'package:dukkan/core/offline/pending_mutation.dart';
import 'package:dukkan/domain/order/entities/address.dart';
import 'package:dukkan/domain/order/entities/order.dart';
import 'package:dukkan/domain/order/entities/order_item.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:dukkan/domain/order/repositories/order_repository.dart';
import 'package:dukkan/domain/order/usecases/watch_shop_orders.dart';
import 'package:dukkan/presentation/orders/bloc/owner_orders_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
}

/// Drives the shop-orders stream by hand (mirrors `_FakeOrderRepository` in
/// orders_bloc_test.dart).
class _FakeOrderRepository implements OrderRepository {
  final controller = StreamController<List<Order>>.broadcast();

  @override
  Stream<List<Order>> watchShopOrders(String shopId) => controller.stream;

  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) =>
      const Stream.empty();

  @override
  Stream<Order> watchOrder(String orderId) => const Stream.empty();

  @override
  Stream<List<Order>> watchDriverActiveOrders(String driverUid) =>
      const Stream.empty();

  @override
  Stream<List<Order>> watchDriverHistory(String driverUid) =>
      const Stream.empty();

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

Order _order(String id, OrderStatus status) => Order(
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
      createdAt: DateTime(2026, 1, 1),
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo'),
    );

void main() {
  late _FakeOrderRepository repo;
  late OwnerOrdersBloc bloc;
  late OfflineMutationQueue queue;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = _FakeOrderRepository();
    queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    bloc = OwnerOrdersBloc(
      shopId: 's1',
      watchShopOrders: WatchShopOrders(repo),
      queue: queue,
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.controller.close();
    await queue.dispose();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('a queued mutation for a listed order surfaces in pendingStatuses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    final queuedBloc = OwnerOrdersBloc(
      shopId: 's1',
      watchShopOrders: WatchShopOrders(repo),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const OwnerOrdersStarted());
    await tick();
    repo.controller.add([_order('a', OrderStatus.pending)]);
    await tick();

    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'a',
      targetStatus: OrderStatus.accepted,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));
    await tick();

    expect(queuedBloc.state.pendingStatuses['a'], OrderStatus.accepted);
  });

  test('a mutation already queued before the bloc is constructed still surfaces in the initial state', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    addTearDown(queue.dispose);

    // Queued (and left pending, since _FakeNetworkInfo reports offline)
    // BEFORE the bloc — and therefore its watchAll() subscription — exists.
    // watchAll() never replays to a late subscriber, so this only surfaces
    // if the bloc also reads OfflineMutationQueue.allPending on construction.
    await queue.enqueue(PendingMutation(
      id: 'm1',
      orderId: 'a',
      targetStatus: OrderStatus.accepted,
      actorUid: 'u1',
      enqueuedAt: DateTime(2026, 8, 11),
    ));

    final queuedBloc = OwnerOrdersBloc(
      shopId: 's1',
      watchShopOrders: WatchShopOrders(repo),
      queue: queue,
    );
    addTearDown(queuedBloc.close);

    expect(queuedBloc.state.pendingStatuses['a'], OrderStatus.accepted);
  });

  test('an order not in the queue has no pendingStatuses entry', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final queue = OfflineMutationQueue(
      prefs: prefs,
      networkInfo: _FakeNetworkInfo(),
      remoteUpdate: (_, _) async {},
    );
    final queuedBloc = OwnerOrdersBloc(
      shopId: 's1',
      watchShopOrders: WatchShopOrders(repo),
      queue: queue,
    );
    addTearDown(queuedBloc.close);
    addTearDown(queue.dispose);

    queuedBloc.add(const OwnerOrdersStarted());
    await tick();
    repo.controller.add([_order('a', OrderStatus.pending)]);
    await tick();

    expect(queuedBloc.state.pendingStatuses.containsKey('a'), isFalse);
  });

  test('loads orders from the shop stream', () async {
    bloc.add(const OwnerOrdersStarted());
    await tick();

    repo.controller.add([_order('a', OrderStatus.pending)]);
    await tick();

    expect(bloc.state.status, OwnerOrdersStatus.loaded);
    expect(bloc.state.orders.single.id, 'a');
  });

  test('an empty feed still reaches loaded (not stuck loading)', () async {
    bloc.add(const OwnerOrdersStarted());
    await tick();

    repo.controller.add(const []);
    await tick();

    expect(bloc.state.status, OwnerOrdersStatus.loaded);
    expect(bloc.state.orders, isEmpty);
  });

  test('stream error surfaces as error status', () async {
    bloc.add(const OwnerOrdersStarted());
    await tick();

    repo.controller.addError(Exception('boom'));
    await tick();

    expect(bloc.state.status, OwnerOrdersStatus.error);
  });

  test('retry re-subscribes after an error', () async {
    bloc.add(const OwnerOrdersStarted());
    await tick();
    repo.controller.addError(Exception('boom'));
    await tick();
    expect(bloc.state.status, OwnerOrdersStatus.error);

    bloc.add(const OwnerOrdersRetryRequested());
    await tick();
    repo.controller.add([_order('a', OrderStatus.accepted)]);
    await tick();

    expect(bloc.state.status, OwnerOrdersStatus.loaded);
    expect(bloc.state.orders.single.status, OrderStatus.accepted);
  });
}
