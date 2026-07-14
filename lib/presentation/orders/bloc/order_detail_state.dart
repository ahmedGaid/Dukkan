part of 'order_detail_bloc.dart';

enum OrderDetailStatus { loading, loaded, error }

/// Status of the in-flight cancel call — separate from [OrderDetailStatus] so
/// a cancel attempt never re-triggers the page's own Loading state.
enum OrderCancelStatus { idle, submitting, failure }

/// Status of the in-flight rate call — same reasoning as [OrderCancelStatus].
/// Success needs no local flag: the new `order.rating` arrives through the
/// same watch stream, same pattern as cancel.
enum OrderRateStatus { idle, submitting, failure }

/// Status of the courier's in-flight advance call (Session 10) — same
/// reasoning as [OrderCancelStatus]; the new `status` arrives back through
/// the same watch stream.
enum OrderAdvanceStatus { idle, submitting, failure }

/// Status of the staff action bar's in-flight call (FC10 — force-status/
/// reassign/cancel/add-note all share this, only one runs at a time). Same
/// reasoning as [OrderCancelStatus]: a correction's success needs no local
/// patch, it arrives back through the order's own watch stream.
enum StaffActionStatus { idle, submitting, failure }

class OrderDetailState extends Equatable {
  const OrderDetailState({
    this.status = OrderDetailStatus.loading,
    this.order,
    this.cancelStatus = OrderCancelStatus.idle,
    this.rateStatus = OrderRateStatus.idle,
    this.advanceStatus = OrderAdvanceStatus.idle,
    this.staffActionStatus = StaffActionStatus.idle,
    this.customer,
    this.area,
    this.notes,
  });

  final OrderDetailStatus status;
  final Order? order;
  final OrderCancelStatus cancelStatus;
  final OrderRateStatus rateStatus;
  final OrderAdvanceStatus advanceStatus;
  final StaffActionStatus staffActionStatus;

  /// The customer's `/users` profile — owner/courier/staff view only (M2,
  /// M10, FC10), resolved once per order. Null while loading, missing, or on
  /// the customer's own view.
  final AppUser? customer;

  /// The delivery area's display name — courier view only (M10), resolved
  /// once per order from the order's `deliveryAddress.areaId`. Optional
  /// secondary info, never blocks the page if it fails to resolve.
  final Area? area;

  /// Internal staff notes (FC10, staff role only) — null while the first
  /// snapshot hasn't arrived yet, empty list once it has and there are none.
  final List<OrderNote>? notes;

  bool get isCancelling => cancelStatus == OrderCancelStatus.submitting;
  bool get isRating => rateStatus == OrderRateStatus.submitting;
  bool get isAdvancing => advanceStatus == OrderAdvanceStatus.submitting;
  bool get isStaffActionBusy => staffActionStatus == StaffActionStatus.submitting;

  OrderDetailState copyWith({
    OrderDetailStatus? status,
    Order? order,
    OrderCancelStatus? cancelStatus,
    OrderRateStatus? rateStatus,
    OrderAdvanceStatus? advanceStatus,
    StaffActionStatus? staffActionStatus,
    AppUser? customer,
    Area? area,
    List<OrderNote>? notes,
  }) {
    return OrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      rateStatus: rateStatus ?? this.rateStatus,
      advanceStatus: advanceStatus ?? this.advanceStatus,
      staffActionStatus: staffActionStatus ?? this.staffActionStatus,
      customer: customer ?? this.customer,
      area: area ?? this.area,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        cancelStatus,
        rateStatus,
        advanceStatus,
        staffActionStatus,
        customer,
        area,
        notes,
      ];
}
