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
  });

  final String uid;
  final String name;
  final String? phone;
  final List<String> areaIds;
  final int maxActiveOrders;
  final int activeOrdersCount;
  final bool isOnline;
  final bool isSuspended;

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
      ];
}
