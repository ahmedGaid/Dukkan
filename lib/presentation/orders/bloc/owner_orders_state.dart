part of 'owner_orders_bloc.dart';

enum OwnerOrdersStatus { loading, loaded, error }

class OwnerOrdersState extends Equatable {
  const OwnerOrdersState({
    this.status = OwnerOrdersStatus.loading,
    this.orders = const [],
  });

  final OwnerOrdersStatus status;

  /// Newest-first (query order lives in the remote datasource).
  final List<Order> orders;

  OwnerOrdersState copyWith({OwnerOrdersStatus? status, List<Order>? orders}) {
    return OwnerOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object?> get props => [status, orders];
}
