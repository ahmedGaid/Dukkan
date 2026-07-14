import '../../areas/repositories/areas_repository.dart';
import '../../config/repositories/platform_config_repository.dart';
import '../entities/address.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../repositories/order_repository.dart';

/// Places the order and snapshots the commission/fee rates onto it (M12).
/// `totalMinor` is no longer caller-supplied — it's items subtotal + the
/// resolved delivery fee, computed here so a stale/tampered client total can
/// never land on the doc. Fee resolution order (FC9 Task C): the delivery
/// area's `deliveryFeeMinorOverride` if set, else the platform default;
/// commission rate resolution stays platform-default-only for now — see the
/// shop-override/campaign note this class carried for when that lands.
class PlaceOrder {
  const PlaceOrder(this._repository, this._configRepository, this._areasRepository);

  final OrderRepository _repository;
  final PlatformConfigRepository _configRepository;
  final AreasRepository _areasRepository;

  Future<Order> call({
    required String shopId,
    required String customerUid,
    required List<OrderItem> items,
    required Address deliveryAddress,
    String? notes,
  }) async {
    final config = await _configRepository.getConfig();
    final subtotalMinor =
        items.fold(0, (sum, item) => sum + item.subtotalMinor);
    final commissionMinor = config.commissionForSubtotal(subtotalMinor);
    final deliveryFeeMinor = await _resolveDeliveryFeeMinor(
      areaId: deliveryAddress.areaId,
      defaultFeeMinor: config.deliveryFeeMinor,
    );

    return _repository.placeOrder(
      shopId: shopId,
      customerUid: customerUid,
      items: items,
      deliveryAddress: deliveryAddress,
      notes: notes,
      subtotalMinor: subtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor,
      commissionBps: config.commissionBps,
      commissionMinor: commissionMinor,
      driverDeliveryShareMinor: config.driverDeliveryShareMinor,
      platformDeliveryShareMinor: config.platformDeliveryShareMinor,
      totalMinor: subtotalMinor + deliveryFeeMinor,
    );
  }

  /// The area list is tiny and already one-shot/cached (`AreasRepository`
  /// doc) — no areaId (pre-M8 client, or a lookup miss) falls back to the
  /// platform default rather than failing the order.
  Future<int> _resolveDeliveryFeeMinor({
    required String? areaId,
    required int defaultFeeMinor,
  }) async {
    if (areaId == null) return defaultFeeMinor;
    final areas = await _areasRepository.getAreas();
    for (final area in areas) {
      if (area.id == areaId) return area.deliveryFeeMinorOverride ?? defaultFeeMinor;
    }
    return defaultFeeMinor;
  }
}
