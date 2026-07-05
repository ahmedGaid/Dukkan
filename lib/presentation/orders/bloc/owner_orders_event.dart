part of 'owner_orders_bloc.dart';

sealed class OwnerOrdersEvent extends Equatable {
  const OwnerOrdersEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the shop's orders feed (fired once on page open).
class OwnerOrdersStarted extends OwnerOrdersEvent {
  const OwnerOrdersStarted();
}

/// Re-subscribe after an error (retry action).
class OwnerOrdersRetryRequested extends OwnerOrdersEvent {
  const OwnerOrdersRetryRequested();
}

/// Internal: a new list arrived from the stream.
class _OwnerOrdersUpdated extends OwnerOrdersEvent {
  const _OwnerOrdersUpdated(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

/// Internal: the stream errored.
class _OwnerOrdersFailed extends OwnerOrdersEvent {
  const _OwnerOrdersFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
