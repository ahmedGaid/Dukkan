part of 'driver_detail_bloc.dart';

sealed class DriverDetailEvent extends Equatable {
  const DriverDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads the performance card + assigned-orders
/// list (the driver itself is already seeded from the board row).
class DriverDetailStarted extends DriverDetailEvent {
  const DriverDetailStarted();
}

/// [reason] required by the confirm dialog when [value] is true (suspending);
/// null clears it on unsuspend.
class DriverDetailSetSuspendedRequested extends DriverDetailEvent {
  const DriverDetailSetSuspendedRequested({required this.value, this.reason});

  final bool value;
  final String? reason;

  @override
  List<Object?> get props => [value, reason];
}

class DriverDetailSetVerifiedRequested extends DriverDetailEvent {
  const DriverDetailSetVerifiedRequested(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

class DriverDetailUpdateRequested extends DriverDetailEvent {
  const DriverDetailUpdateRequested({
    required this.name,
    this.phone,
    required this.areaIds,
    required this.maxActiveOrders,
    this.vehicleType,
    this.vehiclePlate,
    this.idDocUrl,
  });

  final String name;
  final String? phone;
  final List<String> areaIds;
  final int maxActiveOrders;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? idDocUrl;

  @override
  List<Object?> get props =>
      [name, phone, areaIds, maxActiveOrders, vehicleType, vehiclePlate, idDocUrl];
}
