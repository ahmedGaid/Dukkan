import 'dart:async';

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
    required int totalMinor,
    required Address deliveryAddress,
    String? notes,
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

  setUp(() {
    repo = _FakeOrderRepository();
    bloc = DeliveriesBloc(
      driverUid: 'd1',
      watchActive: WatchDriverActiveOrders(repo),
      watchHistory: WatchDriverOrderHistory(repo),
      getAreas: GetAreas(_FakeAreasRepository()),
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.activeController.close();
    await repo.historyController.close();
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
}
