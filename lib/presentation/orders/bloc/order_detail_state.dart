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
    this.customer,
  });

  final OrderDetailStatus status;
  final Order? order;
  final OrderCancelStatus cancelStatus;
  final OrderRateStatus rateStatus;

  /// The customer's `/users` profile — owner view only (M2), resolved once
  /// per order. Null while loading, missing, or on the customer's own view.
  final AppUser? customer;

  bool get isCancelling => cancelStatus == OrderCancelStatus.submitting;
  bool get isRating => rateStatus == OrderRateStatus.submitting;

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    Order? order,
    OrderCancelStatus? cancelStatus,
    OrderRateStatus? rateStatus,
    AppUser? customer,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      rateStatus: rateStatus ?? this.rateStatus,
      customer: customer ?? this.customer,
    );
  }

  @override
  List<Object?> get props =>
      [status, order, cancelStatus, rateStatus, customer];
}
