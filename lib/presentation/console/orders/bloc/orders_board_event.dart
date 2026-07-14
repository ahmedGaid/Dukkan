part of 'orders_board_bloc.dart';

sealed class OrdersBoardEvent extends Equatable {
  const OrdersBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads shops/areas (dropdown labels) plus the
/// first page for [initialStatus] (the dashboard's "orders waiting" quick
/// action deep-links `/console/orders?status=pending` into this).
class OrdersBoardStarted extends OrdersBoardEvent {
  const OrdersBoardStarted({this.initialStatus});

  final String? initialStatus;

  @override
  List<Object?> get props => [initialStatus];
}

class OrdersBoardRetryRequested extends OrdersBoardEvent {
  const OrdersBoardRetryRequested();
}

/// Status filter chip changed — the one server-side facet, so this resets
/// the loaded list and refetches page 1. Null = الكل.
class OrdersBoardStatusFilterChanged extends OrdersBoardEvent {
  const OrdersBoardStatusFilterChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

/// Shop dropdown changed — client-side refine over the loaded pages, no refetch.
class OrdersBoardShopFilterChanged extends OrdersBoardEvent {
  const OrdersBoardShopFilterChanged(this.shopId);

  final String? shopId;

  @override
  List<Object?> get props => [shopId];
}

/// Area dropdown changed — client-side refine, no refetch.
class OrdersBoardAreaFilterChanged extends OrdersBoardEvent {
  const OrdersBoardAreaFilterChanged(this.areaId);

  final String? areaId;

  @override
  List<Object?> get props => [areaId];
}

/// Date range changed — client-side refine, no refetch.
class OrdersBoardDateRangeChanged extends OrdersBoardEvent {
  const OrdersBoardDateRangeChanged({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  @override
  List<Object?> get props => [from, to];
}

/// Reveals the next server page for the current status filter.
class OrdersBoardLoadMoreRequested extends OrdersBoardEvent {
  const OrdersBoardLoadMoreRequested();
}

/// The search field was submitted — a phone-looking query resolves to a
/// customer then their orders; anything else is tried as a direct order id.
class OrdersBoardSearchSubmitted extends OrdersBoardEvent {
  const OrdersBoardSearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class OrdersBoardSearchCleared extends OrdersBoardEvent {
  const OrdersBoardSearchCleared();
}
