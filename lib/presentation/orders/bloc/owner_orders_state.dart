part of 'owner_orders_bloc.dart';

enum OwnerOrdersStatus { loading, loaded, error }

class OwnerOrdersState extends Equatable {
  const OwnerOrdersState({
    this.status = OwnerOrdersStatus.loading,
    this.orders = const [],
    this.pendingStatuses = const {},
  });

  final OwnerOrdersStatus status;

  /// Newest-first (query order lives in the remote datasource).
  final List<Order> orders;

  /// orderId → queued target status (O2 slice 1) — non-empty only for an
  /// order with a pending offline mutation; the desk card overrides its
  /// displayed status with this and shows [PendingSyncBadge].
  final Map<String, OrderStatus> pendingStatuses;

  OwnerOrdersState copyWith({
    OwnerOrdersStatus? status,
    List<Order>? orders,
    Map<String, OrderStatus>? pendingStatuses,
  }) {
    return OwnerOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      pendingStatuses: pendingStatuses ?? this.pendingStatuses,
    );
  }

  @override
  List<Object?> get props => [status, orders, pendingStatuses];
}
