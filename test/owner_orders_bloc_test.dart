import 'dart:async';

import 'package:dukkan/domain/order/entities/address.dart';
import 'package:dukkan/domain/order/entities/order.dart';
import 'package:dukkan/domain/order/entities/order_item.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:dukkan/domain/order/repositories/order_repository.dart';
import 'package:dukkan/domain/order/usecases/watch_shop_orders.dart';
import 'package:dukkan/presentation/orders/bloc/owner_orders_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
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

  setUp(() {
    repo = _FakeOrderRepository();
    bloc = OwnerOrdersBloc(
      shopId: 's1',
      watchShopOrders: WatchShopOrders(repo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.controller.close();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

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
