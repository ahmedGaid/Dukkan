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
  });

  final DeliveriesTab tab;
  final DeliveriesListStatus activeStatus;
  final DeliveriesListStatus historyStatus;
  final List<Order> activeOrders;
  final List<Order> historyOrders;

  /// The fixed area list — resolved once, used to show each card's delivery
  /// district name. Optional/display-only: an empty list just hides the line.
  final List<Area> areas;

  DeliveriesState copyWith({
    DeliveriesTab? tab,
    DeliveriesListStatus? activeStatus,
    DeliveriesListStatus? historyStatus,
    List<Order>? activeOrders,
    List<Order>? historyOrders,
    List<Area>? areas,
  }) {
    return DeliveriesState(
      tab: tab ?? this.tab,
      activeStatus: activeStatus ?? this.activeStatus,
      historyStatus: historyStatus ?? this.historyStatus,
      activeOrders: activeOrders ?? this.activeOrders,
      historyOrders: historyOrders ?? this.historyOrders,
      areas: areas ?? this.areas,
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
      ];
}
