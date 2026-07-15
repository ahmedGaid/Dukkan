part of 'driver_detail_bloc.dart';

class DriverDetailState extends Equatable {
  const DriverDetailState({
    required this.driver,
    this.actionBusy = false,
    this.actionError,
    this.performance,
    this.assignedOrders = const [],
    this.areas = const [],
    this.secondaryLoaded = false,
  });

  final Driver driver;

  /// True while any mutation is in flight — the page disables its buttons.
  final bool actionBusy;

  /// The last mutation's technical failure code, or null if it succeeded /
  /// none has run yet. The page's `BlocListener` watches `actionBusy`
  /// transitioning true → false and reads this to decide the snackbar.
  final String? actionError;

  /// Null until [DriverDetailStarted] resolves (or it failed silently — see
  /// [secondaryLoaded]).
  final DriverPerformance? performance;
  final List<Order> assignedOrders;

  /// Every area (incl. inactive), for the edit form's multi-select — loaded
  /// alongside performance/assigned orders, not the driver itself.
  final List<Area> areas;

  /// True once the performance/assigned-orders/areas load has settled
  /// (success or failure) — the cards switch from shimmer to real content.
  final bool secondaryLoaded;

  static const _unset = Object();

  DriverDetailState copyWith({
    Driver? driver,
    bool? actionBusy,
    Object? actionError = _unset,
    DriverPerformance? performance,
    List<Order>? assignedOrders,
    List<Area>? areas,
    bool? secondaryLoaded,
  }) {
    return DriverDetailState(
      driver: driver ?? this.driver,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: actionError == _unset ? this.actionError : actionError as String?,
      performance: performance ?? this.performance,
      assignedOrders: assignedOrders ?? this.assignedOrders,
      areas: areas ?? this.areas,
      secondaryLoaded: secondaryLoaded ?? this.secondaryLoaded,
    );
  }

  @override
  List<Object?> get props => [
        driver,
        actionBusy,
        actionError,
        performance,
        assignedOrders,
        areas,
        secondaryLoaded,
      ];
}
