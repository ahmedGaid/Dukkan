import 'package:dukkan/domain/areas/entities/area.dart';
import 'package:dukkan/domain/areas/repositories/areas_repository.dart';
import 'package:dukkan/domain/config/entities/platform_config.dart';
import 'package:dukkan/domain/config/repositories/platform_config_repository.dart';
import 'package:dukkan/domain/order/entities/address.dart';
import 'package:dukkan/domain/order/entities/order.dart';
import 'package:dukkan/domain/order/entities/order_item.dart';
import 'package:dukkan/domain/order/entities/order_status.dart';
import 'package:dukkan/domain/order/repositories/order_repository.dart';
import 'package:dukkan/domain/order/usecases/place_order.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConfigRepository implements PlatformConfigRepository {
  const _FakeConfigRepository();

  @override
  Future<PlatformConfig> getConfig() async => const PlatformConfig(
        commissionBps: 500,
        deliveryFeeMinor: 3000,
        driverDeliveryShareMinor: 2500,
      );
}

class _FakeAreasRepository implements AreasRepository {
  const _FakeAreasRepository(this._areas);

  final List<Area> _areas;

  @override
  Future<List<Area>> getAreas() async => _areas;
}

/// Captures the args `PlaceOrder` hands it, so tests assert on the resolved
/// `deliveryFeeMinor`/`totalMinor` without a real Firestore write.
class _CapturingOrderRepository implements OrderRepository {
  Map<String, dynamic>? lastCall;

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
  }) async {
    lastCall = {
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': totalMinor,
      'subtotalMinor': subtotalMinor,
    };
    return Order(
      id: 'o1',
      shopId: shopId,
      customerUid: customerUid,
      items: items,
      totalMinor: totalMinor,
      status: OrderStatus.pending,
      createdAt: DateTime(2026, 1, 1),
      deliveryAddress: deliveryAddress,
    );
  }

  @override
  Stream<List<Order>> watchShopOrders(String shopId) => const Stream.empty();
  @override
  Stream<List<Order>> watchCustomerOrders(String customerUid) => const Stream.empty();
  @override
  Stream<Order> watchOrder(String orderId) => const Stream.empty();
  @override
  Stream<List<Order>> watchDriverActiveOrders(String driverUid) => const Stream.empty();
  @override
  Stream<List<Order>> watchDriverHistory(String driverUid) => const Stream.empty();
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
}

void main() {
  const items = [
    OrderItem(productId: 'p1', name: 'Item', nameAr: 'منتج', priceMinor: 1000, quantity: 2),
  ];

  test('no areaId falls back to the platform default fee', () async {
    final repo = _CapturingOrderRepository();
    final placeOrder = PlaceOrder(repo, const _FakeConfigRepository(), const _FakeAreasRepository([]));

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo'),
    );

    expect(repo.lastCall!['deliveryFeeMinor'], 3000);
    expect(repo.lastCall!['totalMinor'], 2000 + 3000);
  });

  test('an area with no override falls back to the platform default fee', () async {
    final repo = _CapturingOrderRepository();
    final areas = [const Area(id: 'abu-atwa', nameAr: 'أبو عطوة', nameEn: 'Abu Atwa', sort: 1)];
    final placeOrder = PlaceOrder(repo, const _FakeConfigRepository(), _FakeAreasRepository(areas));

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo', areaId: 'abu-atwa'),
    );

    expect(repo.lastCall!['deliveryFeeMinor'], 3000);
  });

  test('an area with a fee override uses it instead of the platform default (FC9)', () async {
    final repo = _CapturingOrderRepository();
    final areas = [
      const Area(
        id: 'abu-atwa',
        nameAr: 'أبو عطوة',
        nameEn: 'Abu Atwa',
        sort: 1,
        deliveryFeeMinorOverride: 5000,
      ),
    ];
    final placeOrder = PlaceOrder(repo, const _FakeConfigRepository(), _FakeAreasRepository(areas));

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo', areaId: 'abu-atwa'),
    );

    expect(repo.lastCall!['deliveryFeeMinor'], 5000);
    expect(repo.lastCall!['totalMinor'], 2000 + 5000);
  });

  test('an unknown areaId falls back to the platform default fee', () async {
    final repo = _CapturingOrderRepository();
    final placeOrder = PlaceOrder(repo, const _FakeConfigRepository(), const _FakeAreasRepository([]));

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo', areaId: 'ghost-area'),
    );

    expect(repo.lastCall!['deliveryFeeMinor'], 3000);
  });
}
