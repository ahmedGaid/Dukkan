import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/widgets.dart' show Locale;

import '../../../domain/admin/usecases/add_order_note.dart';
import '../../../domain/admin/usecases/cancel_order_as_staff.dart';
import '../../../domain/admin/usecases/force_order_status.dart';
import '../../../domain/admin/usecases/reassign_order_driver.dart';
import '../../../domain/admin/usecases/watch_order_notes.dart';
import '../../../domain/areas/entities/area.dart';
import '../../../domain/areas/usecases/get_areas.dart';
import '../../../domain/auth/entities/app_user.dart';
import '../../../domain/auth/usecases/get_user_by_id.dart';
import '../../../domain/notifications/repositories/notification_repository.dart';
import '../../../domain/notifications/usecases/notify_order_event.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_note.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/usecases/cancel_order.dart';
import '../../../domain/order/usecases/rate_order.dart';
import '../../../domain/order/usecases/update_order_status.dart';
import '../../../domain/order/usecases/watch_order.dart';
import '../../../l10n/app_localizations.dart';
import '../order_viewer_role.dart';

part 'order_detail_event.dart';
part 'order_detail_state.dart';

/// Drives one order's tracking page. Subscribes to [WatchOrder] for realtime
/// status; cancel/rate/advance are one-shot calls — the resulting change
/// comes back through the same stream, so success never needs a local patch.
/// Page-scoped: the order id is the factory param (mirrors [ProductsBloc]'s
/// shopId). [role] gates two side lookups, both display-only and never
/// surfaced as a page-level failure if they come back null: the owner/courier
/// view resolves the customer's `/users` profile via [GetUserById]; the
/// courier view additionally resolves the delivery area's name via
/// [GetAreas] (M10). Courier status advances ("Picked up"/"Delivered", M10)
/// reuse the same [UpdateOrderStatus] path as the owner's order-desk actions.
class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc({
    required String orderId,
    required WatchOrder watchOrder,
    required CancelOrder cancelOrder,
    required RateOrder rateOrder,
    required UpdateOrderStatus updateOrderStatus,
    required ForceOrderStatus forceOrderStatus,
    required ReassignOrderDriver reassignOrderDriver,
    required CancelOrderAsStaff staffCancelOrder,
    required WatchOrderNotes watchOrderNotes,
    required AddOrderNote addOrderNote,
    GetUserById? getUserById,
    GetAreas? getAreas,
    NotifyOrderEvent? notifyOrderEvent,
    OrderViewerRole role = OrderViewerRole.customer,
  })  : _orderId = orderId,
        _watchOrder = watchOrder,
        _cancelOrder = cancelOrder,
        _rateOrder = rateOrder,
        _updateOrderStatus = updateOrderStatus,
        _forceOrderStatus = forceOrderStatus,
        _reassignOrderDriver = reassignOrderDriver,
        _staffCancelOrder = staffCancelOrder,
        _watchOrderNotes = watchOrderNotes,
        _addOrderNote = addOrderNote,
        _getUserById = getUserById,
        _getAreas = getAreas,
        _notifyOrderEvent = notifyOrderEvent,
        _role = role,
        super(const OrderDetailState()) {
    on<OrderDetailStarted>(_onStarted);
    on<OrderDetailCancelRequested>(_onCancelRequested);
    on<OrderDetailRateSubmitted>(_onRateSubmitted);
    on<OrderDetailAdvanceRequested>(_onAdvanceRequested);
    on<OrderDetailForceStatusRequested>(_onForceStatusRequested);
    on<OrderDetailReassignRequested>(_onReassignRequested);
    on<OrderDetailStaffCancelRequested>(_onStaffCancelRequested);
    on<OrderDetailNoteAdded>(_onNoteAdded);
    on<_OrderArrived>(_onArrived);
    on<_OrderWatchFailed>(_onWatchFailed);
    on<_OrderCancelFailed>(_onCancelFailed);
    on<_OrderRateFailed>(_onRateFailed);
    on<_OrderAdvanceFailed>(_onAdvanceFailed);
    on<_CustomerArrived>(_onCustomerArrived);
    on<_AreaArrived>(_onAreaArrived);
    on<_NotesArrived>((event, emit) => emit(state.copyWith(notes: event.notes)));

    if (_role == OrderViewerRole.staff) {
      _notesSub = _watchOrderNotes(_orderId).listen(
        (notes) => add(_NotesArrived(notes)),
      );
    }
  }

  final String _orderId;
  final WatchOrder _watchOrder;
  final CancelOrder _cancelOrder;
  final RateOrder _rateOrder;
  final UpdateOrderStatus _updateOrderStatus;
  final ForceOrderStatus _forceOrderStatus;
  final ReassignOrderDriver _reassignOrderDriver;
  final CancelOrderAsStaff _staffCancelOrder;
  final WatchOrderNotes _watchOrderNotes;
  final AddOrderNote _addOrderNote;
  final GetUserById? _getUserById;
  final GetAreas? _getAreas;
  final NotifyOrderEvent? _notifyOrderEvent;
  final OrderViewerRole _role;
  StreamSubscription<Order>? _sub;
  StreamSubscription<List<OrderNote>>? _notesSub;

  Future<void> _onStarted(
    OrderDetailEvent event,
    Emitter<OrderDetailState> emit,
  ) async {
    emit(state.copyWith(status: OrderDetailStatus.loading));
    await _sub?.cancel();
    _sub = _watchOrder(_orderId).listen(
      (order) => add(_OrderArrived(order)),
      onError: (Object error) => add(_OrderWatchFailed(error)),
    );
  }

  void _onArrived(_OrderArrived event, Emitter<OrderDetailState> emit) {
    emit(state.copyWith(
      status: OrderDetailStatus.loaded,
      order: event.order,
      cancelStatus: OrderCancelStatus.idle,
      rateStatus: OrderRateStatus.idle,
      advanceStatus: OrderAdvanceStatus.idle,
    ));
    // Fetch once per order, not on every realtime snapshot.
    if (_role != OrderViewerRole.customer &&
        _getUserById != null &&
        state.customer?.uid != event.order.customerUid) {
      _loadCustomer(event.order.customerUid);
    }
    final areaId = event.order.deliveryAddress.areaId;
    if (_role == OrderViewerRole.courier &&
        _getAreas != null &&
        state.area == null &&
        areaId != null) {
      _loadArea(areaId);
    }
  }

  Future<void> _loadCustomer(String customerUid) async {
    AppUser? customer;
    try {
      customer = await _getUserById!(customerUid);
    } catch (_) {
      customer = null;
    }
    add(_CustomerArrived(customer));
  }

  Future<void> _loadArea(String areaId) async {
    Area? area;
    try {
      final areas = await _getAreas!();
      for (final a in areas) {
        if (a.id == areaId) {
          area = a;
          break;
        }
      }
    } catch (_) {
      area = null;
    }
    add(_AreaArrived(area));
  }

  void _onCustomerArrived(
    _CustomerArrived event,
    Emitter<OrderDetailState> emit,
  ) {
    if (event.customer != null) emit(state.copyWith(customer: event.customer));
  }

  void _onAreaArrived(_AreaArrived event, Emitter<OrderDetailState> emit) {
    if (event.area != null) emit(state.copyWith(area: event.area));
  }

  void _onWatchFailed(_OrderWatchFailed event, Emitter<OrderDetailState> emit) {
    emit(state.copyWith(status: OrderDetailStatus.error));
  }

  Future<void> _onCancelRequested(
    OrderDetailCancelRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    final order = state.order;
    if (order == null || !order.status.isCancellable || state.isCancelling) {
      return;
    }
    emit(state.copyWith(cancelStatus: OrderCancelStatus.submitting));
    try {
      await _cancelOrder(_orderId);
    } catch (error) {
      add(_OrderCancelFailed(error));
    }
  }

  void _onCancelFailed(
    _OrderCancelFailed event,
    Emitter<OrderDetailState> emit,
  ) {
    emit(state.copyWith(cancelStatus: OrderCancelStatus.failure));
  }

  Future<void> _onRateSubmitted(
    OrderDetailRateSubmitted event,
    Emitter<OrderDetailState> emit,
  ) async {
    final order = state.order;
    if (order == null || order.status != OrderStatus.delivered ||
        order.rating != null || state.isRating) {
      return;
    }
    emit(state.copyWith(rateStatus: OrderRateStatus.submitting));
    try {
      await _rateOrder(
        orderId: _orderId,
        shopId: order.shopId,
        rating: event.rating,
      );
    } catch (error) {
      add(_OrderRateFailed(error));
    }
  }

  void _onRateFailed(
    _OrderRateFailed event,
    Emitter<OrderDetailState> emit,
  ) {
    emit(state.copyWith(rateStatus: OrderRateStatus.failure));
  }

  Future<void> _onAdvanceRequested(
    OrderDetailAdvanceRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    if (state.isAdvancing) return;
    emit(state.copyWith(advanceStatus: OrderAdvanceStatus.submitting));
    try {
      await _updateOrderStatus(_orderId, event.target);
      if (_role == OrderViewerRole.courier &&
          event.target == OrderStatus.delivered) {
        _notifyShopOwner();
      }
    } catch (error) {
      add(_OrderAdvanceFailed(error));
    }
  }

  /// Fire-and-forget push to the shop owner once the courier confirms
  /// delivery (M11-followup — the symmetric case to `driverAssigned`, `owner
  /// -> driver`). Bilingual, same reasoning as the other `_notify*` call
  /// sites (order_desk_page/assign_driver_sheet): the app never tracks each
  /// user's chosen language, so every push carries both. A failure here must
  /// never surface to the UI — `NotifyOrderEvent`'s repository swallows its
  /// own errors.
  void _notifyShopOwner() {
    final notify = _notifyOrderEvent;
    if (notify == null) return;
    final lAr = lookupAppLocalizations(const Locale('ar'));
    final lEn = lookupAppLocalizations(const Locale('en'));
    unawaited(notify(
      orderId: _orderId,
      type: NotificationEventType.orderDelivered,
      title: '${lAr.notifyOrderDeliveredTitle} / ${lEn.notifyOrderDeliveredTitle}',
      body: '${lAr.notifyOrderDeliveredBody} / ${lEn.notifyOrderDeliveredBody}',
    ));
  }

  void _onAdvanceFailed(
    _OrderAdvanceFailed event,
    Emitter<OrderDetailState> emit,
  ) {
    emit(state.copyWith(advanceStatus: OrderAdvanceStatus.failure));
  }

  /// Every staff action (force-status/reassign/cancel) shares one busy/error
  /// flag — only one runs at a time from the action bar, and success needs no
  /// local patch: the correction lands via `writeAudit`'s underlying Firestore
  /// write, which arrives back through the order's own watch stream.
  Future<void> _runStaffAction(
    Emitter<OrderDetailState> emit,
    Future<void> Function() action,
  ) async {
    if (state.isStaffActionBusy) return;
    emit(state.copyWith(staffActionStatus: StaffActionStatus.submitting));
    try {
      await action();
      emit(state.copyWith(staffActionStatus: StaffActionStatus.idle));
    } catch (_) {
      emit(state.copyWith(staffActionStatus: StaffActionStatus.failure));
    }
  }

  Future<void> _onForceStatusRequested(
    OrderDetailForceStatusRequested event,
    Emitter<OrderDetailState> emit,
  ) =>
      _runStaffAction(
        emit,
        () => _forceOrderStatus(
          orderId: _orderId,
          toStatus: event.toStatus.wire,
          reason: event.reason,
        ),
      );

  Future<void> _onReassignRequested(
    OrderDetailReassignRequested event,
    Emitter<OrderDetailState> emit,
  ) =>
      _runStaffAction(
        emit,
        () => _reassignOrderDriver(
          orderId: _orderId,
          newDriverUid: event.newDriverUid,
          clear: event.clear,
          reason: event.reason,
        ),
      );

  Future<void> _onStaffCancelRequested(
    OrderDetailStaffCancelRequested event,
    Emitter<OrderDetailState> emit,
  ) =>
      _runStaffAction(
        emit,
        () => _staffCancelOrder(
          orderId: _orderId,
          reason: event.reason,
          refundNoteMinor: event.refundNoteMinor,
        ),
      );

  Future<void> _onNoteAdded(
    OrderDetailNoteAdded event,
    Emitter<OrderDetailState> emit,
  ) =>
      _runStaffAction(emit, () => _addOrderNote(orderId: _orderId, text: event.text));

  @override
  Future<void> close() {
    _sub?.cancel();
    _notesSub?.cancel();
    return super.close();
  }
}
