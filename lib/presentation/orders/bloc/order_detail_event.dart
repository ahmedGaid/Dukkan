part of 'order_detail_bloc.dart';

sealed class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to this order's realtime status (fired once on page open).
class OrderDetailStarted extends OrderDetailEvent {
  const OrderDetailStarted();
}

/// Customer tapped "cancel order" and confirmed the dialog.
class OrderDetailCancelRequested extends OrderDetailEvent {
  const OrderDetailCancelRequested();
}

/// Internal: a new snapshot arrived from the stream.
class _OrderArrived extends OrderDetailEvent {
  const _OrderArrived(this.order);

  final Order order;

  @override
  List<Object?> get props => [order];
}

/// Internal: the watch stream errored.
class _OrderWatchFailed extends OrderDetailEvent {
  const _OrderWatchFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Internal: the cancel call failed.
class _OrderCancelFailed extends OrderDetailEvent {
  const _OrderCancelFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
