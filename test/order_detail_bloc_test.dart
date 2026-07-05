import 'dart:async';

import 'package:dukkan/domain/order/entities/address.dart';
import 'package:dukkan/domain/order/entities/order.dart';
import 'package:dukkan/domain/order/entities/order_item.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:dukkan/domain/order/repositories/order_repository.dart';
import 'package:dukkan/domain/order/usecases/cancel_order.dart';
import 'package:dukkan/domain/order/usecases/watch_order.dart';
import 'package:dukkan/presentation/orders/bloc/order_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives one order's stream by hand and lets a test force `cancelOrder` to
/// throw, so the failure path is reachable without Firebase.
class _FakeOrderRepository implements OrderRepository {
  final controller = StreamController<Order>();
  bool cancelShouldFail = false;
  int cancelCalls = 0;

  @override
  Stream<Order> watchOrder(String orderId) => controller.stream;

  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) =>
      const Stream.empty();

  @override
  Stream<List<Order>> watchShopOrders(String shopId) => const Stream.empty();

  @override
  Future<void> cancelOrder(String orderId) async {
    cancelCalls++;
    if (cancelShouldFail) throw Exception('boom');
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {}

  @override
  Future<Order> placeOrder({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
  }) async =>
      _order(OrderStatus.pending);
}

Order _order(OrderStatus status) => Order(
      id: 'o1',
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
  late OrderDetailBloc bloc;

  setUp(() {
    repo = _FakeOrderRepository();
    bloc = OrderDetailBloc(
      orderId: 'o1',
      watchOrder: WatchOrder(repo),
      cancelOrder: CancelOrder(repo),
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.controller.close();
  });

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  test('loads the order from the watch stream', () async {
    bloc.add(const OrderDetailStarted());
    await tick();

    repo.controller.add(_order(OrderStatus.pending));
    await tick();

    expect(bloc.state.status, OrderDetailStatus.loaded);
    expect(bloc.state.order!.status, OrderStatus.pending);
  });

  test('stream error surfaces as error status', () async {
    bloc.add(const OrderDetailStarted());
    await tick();

    repo.controller.addError(Exception('boom'));
    await tick();

    expect(bloc.state.status, OrderDetailStatus.error);
  });

  test('cancel calls the repository once and stays cancellable-driven, not '
      'self-patched', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();

    bloc.add(const OrderDetailCancelRequested());
    await tick();

    expect(repo.cancelCalls, 1);
    // No local patch — status only changes when the stream delivers it.
    expect(bloc.state.order!.status, OrderStatus.pending);
  });

  test('cancel on a non-cancellable order is a no-op', () async {
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.delivered));
    await tick();

    bloc.add(const OrderDetailCancelRequested());
    await tick();

    expect(repo.cancelCalls, 0);
  });

  test('a failed cancel surfaces cancelStatus.failure', () async {
    repo.cancelShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();

    bloc.add(const OrderDetailCancelRequested());
    await tick();

    expect(bloc.state.cancelStatus, OrderCancelStatus.failure);
  });

  test('a new stream snapshot resets cancelStatus back to idle', () async {
    repo.cancelShouldFail = true;
    bloc.add(const OrderDetailStarted());
    await tick();
    repo.controller.add(_order(OrderStatus.pending));
    await tick();
    bloc.add(const OrderDetailCancelRequested());
    await tick();
    expect(bloc.state.cancelStatus, OrderCancelStatus.failure);

    repo.controller.add(_order(OrderStatus.cancelled));
    await tick();

    expect(bloc.state.cancelStatus, OrderCancelStatus.idle);
  });
}
