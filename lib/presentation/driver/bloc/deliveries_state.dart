part of 'deliveries_bloc.dart';

enum DeliveriesTab { active, history }

enum DeliveriesListStatus { loading, loaded, error }

class DeliveriesState extends Equatable {
  const DeliveriesState({
    this.tab = DeliveriesTab.active,
    this.activeStatus = DeliveriesListStatus.loading,
    this.historyStatus = DeliveriesListStatus.loading,
    this.activeOrders = const [],
    this.historyOrders = const [],
    this.areas = const [],
    this.pendingStatuses = const {},
  });

  final DeliveriesTab tab;
  final DeliveriesListStatus activeStatus;
  final DeliveriesListStatus historyStatus;
  final List<Order> activeOrders;
  final List<Order> historyOrders;

  /// The fixed area list — resolved once, used to show each card's delivery
  /// district name. Optional/display-only: an empty list just hides the line.
  final List<Area> areas;

  /// orderId → queued target status (O2 slice 1) — non-empty only for an
  /// order with a pending offline mutation; the delivery card overrides its
  /// displayed status with this and shows [PendingSyncBadge]. Computed from
  /// the whole queue for simplicity — history is all-`delivered` and never
  /// has a pending mutation, so in practice this only ever matches an active
  /// order.
  final Map<String, OrderStatus> pendingStatuses;

  DeliveriesState copyWith({
    DeliveriesTab? tab,
    DeliveriesListStatus? activeStatus,
    DeliveriesListStatus? historyStatus,
    List<Order>? activeOrders,
    List<Order>? historyOrders,
    List<Area>? areas,
    Map<String, OrderStatus>? pendingStatuses,
  }) {
    return DeliveriesState(
      tab: tab ?? this.tab,
      activeStatus: activeStatus ?? this.activeStatus,
      historyStatus: historyStatus ?? this.historyStatus,
      activeOrders: activeOrders ?? this.activeOrders,
      historyOrders: historyOrders ?? this.historyOrders,
      areas: areas ?? this.areas,
      pendingStatuses: pendingStatuses ?? this.pendingStatuses,
    );
  }

  @override
  List<Object?> get props => [
        tab,
        activeStatus,
        historyStatus,
        activeOrders,
        historyOrders,
        areas,
        pendingStatuses,
      ];
}
