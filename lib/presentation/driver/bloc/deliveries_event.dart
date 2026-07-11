part of 'deliveries_bloc.dart';

sealed class DeliveriesEvent extends Equatable {
  const DeliveriesEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to both realtime queries (fired once on page open).
class DeliveriesStarted extends DeliveriesEvent {
  const DeliveriesStarted();
}

/// Courier tapped the Active/History segment.
class DeliveriesTabChanged extends DeliveriesEvent {
  const DeliveriesTabChanged(this.tab);

  final DeliveriesTab tab;

  @override
  List<Object?> get props => [tab];
}

/// Internal: a new active-orders snapshot arrived.
class _ActiveArrived extends DeliveriesEvent {
  const _ActiveArrived(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

/// Internal: the active-orders watch errored.
class _ActiveFailed extends DeliveriesEvent {
  const _ActiveFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Internal: a new history snapshot arrived.
class _HistoryArrived extends DeliveriesEvent {
  const _HistoryArrived(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

/// Internal: the history watch errored.
class _HistoryFailed extends DeliveriesEvent {
  const _HistoryFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Internal: the one-shot area list resolved (card + address-line labels).
class _AreasArrived extends DeliveriesEvent {
  const _AreasArrived(this.areas);

  final List<Area> areas;

  @override
  List<Object?> get props => [areas];
}
