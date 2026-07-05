part of 'order_detail_bloc.dart';

enum OrderDetailStatus { loading, loaded, error }

/// Status of the in-flight cancel call — separate from [OrderDetailStatus] so
/// a cancel attempt never re-triggers the page's own Loading state.
enum OrderCancelStatus { idle, submitting, failure }

class OrderDetailState extends Equatable {
  const OrderDetailState({
    this.status = OrderDetailStatus.loading,
    this.order,
    this.cancelStatus = OrderCancelStatus.idle,
  });

  final OrderDetailStatus status;
  final Order? order;
  final OrderCancelStatus cancelStatus;

  bool get isCancelling => cancelStatus == OrderCancelStatus.submitting;

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    Order? order,
    OrderCancelStatus? cancelStatus,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      cancelStatus: cancelStatus ?? this.cancelStatus,
    );
  }

  @override
  List<Object?> get props => [status, order, cancelStatus];
}
