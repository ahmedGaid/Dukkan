import '../../config/repositories/platform_config_repository.dart';
import '../entities/address.dart';
import '../entities/order.dart';
import '../entities/order_item.dart';
import '../repositories/order_repository.dart';

/// Places the order and snapshots the commission/fee rates onto it (M12).
/// `totalMinor` is no longer caller-supplied — it's items subtotal + the
/// platform's current delivery fee, computed here so a stale/tampered client
/// total can never land on the doc. Resolution order for the rate is just
/// the platform default today; see the shop-override/campaign note this
/// class carries for when that lands (M12 Task E).
class PlaceOrder {
  const PlaceOrder(this._repository, this._configRepository);

  final OrderRepository _repository;
  final PlatformConfigRepository _configRepository;

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
    // Rate resolution order for later: shop override → campaign → platform
    // default (this line). The snapshot fields below already isolate each
    // order's history from later rate changes, so nothing else changes when
    // that resolution chain is added.
    final commissionMinor = config.commissionForSubtotal(subtotalMinor);

    return _repository.placeOrder(
      shopId: shopId,
      customerUid: customerUid,
      items: items,
      deliveryAddress: deliveryAddress,
      notes: notes,
      subtotalMinor: subtotalMinor,
      deliveryFeeMinor: config.deliveryFeeMinor,
      commissionBps: config.commissionBps,
      commissionMinor: commissionMinor,
      driverDeliveryShareMinor: config.driverDeliveryShareMinor,
      platformDeliveryShareMinor: config.platformDeliveryShareMinor,
      totalMinor: subtotalMinor + config.deliveryFeeMinor,
    );
  }
}
