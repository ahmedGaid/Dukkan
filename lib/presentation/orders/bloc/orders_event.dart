part of 'orders_bloc.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the customer's orders feed (fired once on tab open).
class OrdersStarted extends OrdersEvent {
  const OrdersStarted();
}

/// Re-subscribe after an error (retry action).
class OrdersRetryRequested extends OrdersEvent {
  const OrdersRetryRequested();
}

/// Internal: a new list arrived from the stream.
class _OrdersUpdated extends OrdersEvent {
  const _OrdersUpdated(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

/// Internal: the stream errored.
class _OrdersFailed extends OrdersEvent {
  const _OrdersFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
