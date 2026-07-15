import '../../driver/entities/driver.dart';
import '../../order/entities/order.dart';
import '../entities/driver_performance.dart';

/// Founder Console driver management (FC11). Reads are Firestore-direct and
/// unfiltered — `/drivers` read is `isSignedIn()`, so there is no permission
/// gate to route through (same reasoning as [AdminShopsRepository]). Every
/// mutation is also Firestore-direct, gated by the `drivers.manage` rules
/// branch — no Worker-routed op here, unlike shop ownership transfer.
abstract class AdminDriversRepository {
  /// Every driver doc, unfiltered. Small marketplace — same contract as
  /// `getAllShops`.
  Future<List<Driver>> getAllDrivers();

  /// Single driver by id, unfiltered; null if it doesn't exist. Used to
  /// reload the detail page's truth after a mutation.
  Future<Driver?> getDriverById(String uid);

  /// [reason] is required by the console UI when suspending, optional when
  /// unsuspending (it's cleared on unsuspend).
  Future<void> setSuspended({required String uid, required bool value, String? reason});

  Future<void> setVerified({required String uid, required bool value});

  /// Everything else editable on the detail page: areas/capacity/vehicle/
  /// contact. `activeOrdersCount` is never touched here — only the
  /// assignment transaction and the Worker touch it.
  Future<void> updateDetails({
    required String uid,
    required String name,
    String? phone,
    required List<String> areaIds,
    required int maxActiveOrders,
    String? vehicleType,
    String? vehiclePlate,
    String? idDocUrl,
  });

  Future<DriverPerformance> getPerformance(String uid);

  /// Orders this driver currently carries (`preparing` | `outForDelivery`) —
  /// the detail page's assigned-orders list, rows link to the shared order
  /// detail page in the staff view.
  Future<List<Order>> getAssignedOrders(String uid);
}
