import 'package:equatable/equatable.dart';

/// `/config/platform` (M12) — the single founder-managed doc for commission
/// and delivery-fee rates. Client-read-only (`firestore.rules`); the founder
/// edits via console. No shop-override/campaign rates yet — see the
/// resolution-order note in `PlaceOrder` (M12 Task E).
class PlatformConfig extends Equatable {
  const PlatformConfig({
    required this.commissionBps,
    required this.deliveryFeeMinor,
    required this.driverDeliveryShareMinor,
  });

  /// Commission rate in basis points (500 = 5%).
  final int commissionBps;
  final int deliveryFeeMinor;
  final int driverDeliveryShareMinor;

  /// The platform's own cut of the delivery fee — derived, never stored.
  int get platformDeliveryShareMinor =>
      deliveryFeeMinor - driverDeliveryShareMinor;

  /// Round-half-up commission on [subtotalMinor] at this rate — the `+ 5000`
  /// before the integer division is the rounding: halves round up, matching
  /// how a human would read a receipt (e.g. 500 EGP × 5% = 25.00 EGP exactly;
  /// an odd subtotal like 333 piasters × 500 bps rounds to 17, not 16).
  int commissionForSubtotal(int subtotalMinor) =>
      (subtotalMinor * commissionBps + 5000) ~/ 10000;

  @override
  List<Object?> get props =>
      [commissionBps, deliveryFeeMinor, driverDeliveryShareMinor];
}
