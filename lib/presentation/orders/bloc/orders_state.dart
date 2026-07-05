part of 'orders_bloc.dart';

enum OrdersStatus { loading, loaded, error }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.loading,
    this.orders = const [],
  });

  final OrdersStatus status;

  /// Newest-first (query order lives in the remote datasource).
  final List<Order> orders;

  OrdersState copyWith({OrdersStatus? status, List<Order>? orders}) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object?> get props => [status, orders];
}
