import 'package:equatable/equatable.dart';

/// A platform driver's delivery profile (`/drivers/{uid}`, M8). A new courier
/// signup always creates one suspended — a founder activates it via console
/// or seed. `activeOrdersCount`/`maxActiveOrders` gate the Session 9
/// assignment transaction; `areaIds` gate which orders a driver can be
/// offered.
class Driver extends Equatable {
  const Driver({
    required this.uid,
    required this.name,
    required this.areaIds,
    required this.maxActiveOrders,
    required this.activeOrdersCount,
    required this.isOnline,
    required this.isSuspended,
    this.phone,
    this.vehicleType,
    this.vehiclePlate,
    this.idDocUrl,
    this.isVerified = false,
    this.suspendReason,
  });

  final String uid;
  final String name;
  final String? phone;
  final List<String> areaIds;
  final int maxActiveOrders;
  final int activeOrdersCount;
  final bool isOnline;
  final bool isSuspended;

  /// FC11, console-editable. E.g. «موتوسيكل».
  final String? vehicleType;
  final String? vehiclePlate;

  /// FC11 — uploaded to `driver-docs/` via the Worker, console-only.
  final String? idDocUrl;

  /// FC11 — a founder-confirmed identity check, separate from [isSuspended]
  /// (a driver can be active but not yet verified).
  final bool isVerified;

  /// FC11 — set by the console when [isSuspended] flips true; null otherwise.
  final String? suspendReason;

  @override
  List<Object?> get props => [
        uid,
        name,
        phone,
        areaIds,
        maxActiveOrders,
        activeOrdersCount,
        isOnline,
        isSuspended,
        vehicleType,
        vehiclePlate,
        idDocUrl,
        isVerified,
        suspendReason,
      ];
}
