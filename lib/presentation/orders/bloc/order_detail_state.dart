part of 'order_detail_bloc.dart';

enum OrderDetailStatus { loading, loaded, error }

/// Status of the in-flight cancel call — separate from [OrderDetailStatus] so
/// a cancel attempt never re-triggers the page's own Loading state.
enum OrderCancelStatus { idle, submitting, failure }

/// Status of the in-flight rate call — same reasoning as [OrderCancelStatus].
/// Success needs no local flag: the new `order.rating` arrives through the
/// same watch stream, same pattern as cancel.
enum OrderRateStatus { idle, submitting, failure }

class OrderDetailState extends Equatable {
  const OrderDetailState({
    this.status = OrderDetailStatus.loading,
    this.order,
    this.cancelStatus = OrderCancelStatus.idle,
    this.rateStatus = OrderRateStatus.idle,
  });

  final OrderDetailStatus status;
  final Order? order;
  final OrderCancelStatus cancelStatus;
  final OrderRateStatus rateStatus;

  bool get isCancelling => cancelStatus == OrderCancelStatus.submitting;
  bool get isRating => rateStatus == OrderRateStatus.submitting;

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    Order? order,
    OrderCancelStatus? cancelStatus,
    OrderRateStatus? rateStatus,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      rateStatus: rateStatus ?? this.rateStatus,
    );
  }

  @override
  List<Object?> get props => [status, order, cancelStatus, rateStatus];
}
