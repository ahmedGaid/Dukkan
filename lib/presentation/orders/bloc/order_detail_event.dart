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

/// Customer tapped a star on the post-delivery rating row.
class OrderDetailRateSubmitted extends OrderDetailEvent {
  const OrderDetailRateSubmitted(this.rating);

  final int rating;

  @override
  List<Object?> get props => [rating];
}

/// Courier tapped their one primary action ("Picked up" / "Delivered",
/// Session 10) — already confirmed by the page for the final `delivered` step.
class OrderDetailAdvanceRequested extends OrderDetailEvent {
  const OrderDetailAdvanceRequested(this.target);

  final OrderStatus target;

  @override
  List<Object?> get props => [target];
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

/// Internal: the rate call failed.
class _OrderRateFailed extends OrderDetailEvent {
  const _OrderRateFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Internal: the owner-view customer profile fetch resolved (owner view
/// only) — null if the lookup failed or the doc doesn't exist.
class _CustomerArrived extends OrderDetailEvent {
  const _CustomerArrived(this.customer);

  final AppUser? customer;

  @override
  List<Object?> get props => [customer];
}

/// Internal: the courier-view area lookup resolved — null if there's no
/// `areaId` on the order or the lookup failed (display-only, never blocks).
class _AreaArrived extends OrderDetailEvent {
  const _AreaArrived(this.area);

  final Area? area;

  @override
  List<Object?> get props => [area];
}

/// Internal: the courier's advance-status call failed.
class _OrderAdvanceFailed extends OrderDetailEvent {
  const _OrderAdvanceFailed(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Staff tapped "force status" and confirmed the dialog (FC10, staff role only).
class OrderDetailForceStatusRequested extends OrderDetailEvent {
  const OrderDetailForceStatusRequested({required this.toStatus, required this.reason});

  final OrderStatus toStatus;
  final String reason;

  @override
  List<Object?> get props => [toStatus, reason];
}

/// Staff tapped "reassign driver" and confirmed a new driver (or "unassign").
class OrderDetailReassignRequested extends OrderDetailEvent {
  const OrderDetailReassignRequested({
    this.newDriverUid,
    this.clear = false,
    required this.reason,
  });

  final String? newDriverUid;
  final bool clear;
  final String reason;

  @override
  List<Object?> get props => [newDriverUid, clear, reason];
}

/// Staff tapped "cancel" and confirmed the reason/refund-note dialog.
class OrderDetailStaffCancelRequested extends OrderDetailEvent {
  const OrderDetailStaffCancelRequested({required this.reason, this.refundNoteMinor});

  final String reason;
  final int? refundNoteMinor;

  @override
  List<Object?> get props => [reason, refundNoteMinor];
}

/// Staff submitted the internal-note field.
class OrderDetailNoteAdded extends OrderDetailEvent {
  const OrderDetailNoteAdded(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Internal: a new notes snapshot arrived (staff role only).
class _NotesArrived extends OrderDetailEvent {
  const _NotesArrived(this.notes);

  final List<OrderNote> notes;

  @override
  List<Object?> get props => [notes];
}
