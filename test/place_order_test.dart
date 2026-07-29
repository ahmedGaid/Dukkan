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
import 'package:dukkan/domain/promos/entities/coupon.dart';
import 'package:dukkan/domain/promos/repositories/coupon_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConfigRepository implements PlatformConfigRepository {
  const _FakeConfigRepository();

  @override
  Future<PlatformConfig> getConfig() async => const PlatformConfig(
        commissionBps: 500,
        deliveryFeeMinor: 3000,
        driverDeliveryShareMinor: 2500,
      );

  @override
  Future<PlatformConfig> refresh() => getConfig();
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
    String? couponCode,
    int discountMinor = 0,
  }) async {
    lastCall = {
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': totalMinor,
      'subtotalMinor': subtotalMinor,
      'commissionMinor': commissionMinor,
      'couponCode': couponCode,
      'discountMinor': discountMinor,
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

class _FakeCouponRepository implements CouponRepository {
  String? redeemedCode;

  @override
  Future<Coupon?> getByCode(String code) async => null;

  @override
  Future<void> redeem(String code) async {
    redeemedCode = code;
  }
}

void main() {
  const items = [
    OrderItem(productId: 'p1', name: 'Item', nameAr: 'منتج', priceMinor: 1000, quantity: 2),
  ];

  test('no areaId falls back to the platform default fee', () async {
    final repo = _CapturingOrderRepository();
    final placeOrder = PlaceOrder(
      repo,
      const _FakeConfigRepository(),
      const _FakeAreasRepository([]),
      _FakeCouponRepository(),
    );

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
    final placeOrder = PlaceOrder(
      repo,
      const _FakeConfigRepository(),
      _FakeAreasRepository(areas),
      _FakeCouponRepository(),
    );

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
    final placeOrder = PlaceOrder(
      repo,
      const _FakeConfigRepository(),
      _FakeAreasRepository(areas),
      _FakeCouponRepository(),
    );

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
    final placeOrder = PlaceOrder(
      repo,
      const _FakeConfigRepository(),
      const _FakeAreasRepository([]),
      _FakeCouponRepository(),
    );

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo', areaId: 'ghost-area'),
    );

    expect(repo.lastCall!['deliveryFeeMinor'], 3000);
  });

  test('a percent coupon discounts pre-commission, redeems after order create (FC16)', () async {
    final repo = _CapturingOrderRepository();
    final coupons = _FakeCouponRepository();
    final placeOrder = PlaceOrder(
      repo,
      const _FakeConfigRepository(),
      const _FakeAreasRepository([]),
      coupons,
    );
    // subtotal 2000, 10% (1000 bps) -> round-half-up(2000*1000+5000)/10000 = 200.
    const coupon = Coupon(
      code: 'SAVE10',
      type: CouponType.percent,
      valueBps: 1000,
      minOrderMinor: 0,
    );

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo'),
      coupon: coupon,
    );

    expect(repo.lastCall!['discountMinor'], 200);
    expect(repo.lastCall!['couponCode'], 'SAVE10');
    expect(repo.lastCall!['commissionMinor'], 100); // 5% of the 2000 subtotal, unaffected
    expect(repo.lastCall!['totalMinor'], 2000 + 3000 - 200);
    expect(coupons.redeemedCode, 'SAVE10');
  });

  test('a fixed coupon larger than the subtotal clamps to the subtotal (FC16)', () async {
    final repo = _CapturingOrderRepository();
    final placeOrder = PlaceOrder(
      repo,
      const _FakeConfigRepository(),
      const _FakeAreasRepository([]),
      _FakeCouponRepository(),
    );
    const coupon = Coupon(
      code: 'BIG',
      type: CouponType.fixed,
      valueMinor: 999999,
      minOrderMinor: 0,
    );

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo'),
      coupon: coupon,
    );

    expect(repo.lastCall!['discountMinor'], 2000);
    expect(repo.lastCall!['totalMinor'], 3000); // subtotal fully discounted, only delivery fee left
  });

  test('no coupon leaves discountMinor/couponCode untouched', () async {
    final repo = _CapturingOrderRepository();
    final coupons = _FakeCouponRepository();
    final placeOrder = PlaceOrder(
      repo,
      const _FakeConfigRepository(),
      const _FakeAreasRepository([]),
      coupons,
    );

    await placeOrder(
      shopId: 's1',
      customerUid: 'u1',
      items: items,
      deliveryAddress: const Address(line1: 'Street 1', city: 'Cairo'),
    );

    expect(repo.lastCall!['discountMinor'], 0);
    expect(repo.lastCall!['couponCode'], isNull);
    expect(coupons.redeemedCode, isNull);
  });
}
