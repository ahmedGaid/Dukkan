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
    this.minOrderMinor = 0,
    // Display/reporting only for COD v1 — not applied to any total yet;
    // added ahead of a future VAT-inclusive pricing pass (M12 Task A note).
    this.vatBps = 0,
    this.supportPhone = '',
    this.supportWhatsApp = '',
    this.businessHoursNote = '',
    this.maintenanceMode = false,
    this.minSupportedBuild = 0,
  });

  /// Commission rate in basis points (500 = 5%).
  final int commissionBps;
  final int deliveryFeeMinor;
  final int driverDeliveryShareMinor;
  final int minOrderMinor;
  final int vatBps;
  final String supportPhone;
  final String supportWhatsApp;
  final String businessHoursNote;

  /// Blocks the app for non-staff — see the splash boot gate in
  /// `AppRouter._redirect` (M12 Task D).
  final bool maintenanceMode;

  /// Blocks any app build below this number — compared against
  /// `AppConfig.buildNumber`.
  final int minSupportedBuild;

  /// The platform's own cut of the delivery fee — derived, never stored.
  int get platformDeliveryShareMinor =>
      deliveryFeeMinor - driverDeliveryShareMinor;

  /// Round-half-up commission on [subtotalMinor] at this rate — the `+ 5000`
  /// before the integer division is the rounding: halves round up, matching
  /// how a human would read a receipt (e.g. 500 EGP × 5% = 25.00 EGP exactly;
  /// an odd subtotal like 333 piasters × 500 bps rounds to 17, not 16).
  int commissionForSubtotal(int subtotalMinor) =>
      (subtotalMinor * commissionBps + 5000) ~/ 10000;

  /// Every field keyed by its Firestore name — the console settings bloc
  /// reads this to build a save-group's audit `before` snapshot.
  Map<String, dynamic> toFieldMap() => {
        'commissionBps': commissionBps,
        'deliveryFeeMinor': deliveryFeeMinor,
        'driverDeliveryShareMinor': driverDeliveryShareMinor,
        'minOrderMinor': minOrderMinor,
        'vatBps': vatBps,
        'supportPhone': supportPhone,
        'supportWhatsApp': supportWhatsApp,
        'businessHoursNote': businessHoursNote,
        'maintenanceMode': maintenanceMode,
        'minSupportedBuild': minSupportedBuild,
      };

  @override
  List<Object?> get props => [
        commissionBps,
        deliveryFeeMinor,
        driverDeliveryShareMinor,
        minOrderMinor,
        vatBps,
        supportPhone,
        supportWhatsApp,
        businessHoursNote,
        maintenanceMode,
        minSupportedBuild,
      ];
}
