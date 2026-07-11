import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/auth/entities/app_user.dart';
import '../../../domain/auth/usecases/get_user_by_id.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/usecases/cancel_order.dart';
import '../../../domain/order/usecases/rate_order.dart';
import '../../../domain/order/usecases/watch_order.dart';

part 'order_detail_event.dart';
part 'order_detail_state.dart';

/// Drives one order's tracking page. Subscribes to [WatchOrder] for realtime
/// status; cancel is a one-shot [CancelOrder] call — the resulting status
/// change comes back through the same stream, so a success needs no local
/// patch. Page-scoped: the order id is the factory param (mirrors
/// [ProductsBloc]'s shopId). When `isOwner` (M2, the owner order-details
/// page), it additionally resolves the customer's `/users` profile once the
/// order's `customerUid` is known — a display-only lookup via [GetUserById],
/// never surfaced as a page-level failure if it comes back null.
class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc({
    required String orderId,
    required WatchOrder watchOrder,
    required CancelOrder cancelOrder,
    required RateOrder rateOrder,
    GetUserById? getUserById,
    bool isOwner = false,
  })  : _orderId = orderId,
        _watchOrder = watchOrder,
        _cancelOrder = cancelOrder,
        _rateOrder = rateOrder,
        _getUserById = getUserById,
        _isOwner = isOwner,
        super(const OrderDetailState()) {
    on<OrderDetailStarted>(_onStarted);
    on<OrderDetailCancelRequested>(_onCancelRequested);
    on<OrderDetailRateSubmitted>(_onRateSubmitted);
    on<_OrderArrived>(_onArrived);
    on<_OrderWatchFailed>(_onWatchFailed);
    on<_OrderCancelFailed>(_onCancelFailed);
    on<_OrderRateFailed>(_onRateFailed);
    on<_CustomerArrived>(_onCustomerArrived);
  }

  final String _orderId;
  final WatchOrder _watchOrder;
  final CancelOrder _cancelOrder;
  final RateOrder _rateOrder;
  final GetUserById? _getUserById;
  final bool _isOwner;
  StreamSubscription<Order>? _sub;

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
    ));
    // Fetch once per order, not on every realtime snapshot.
    if (_isOwner &&
        _getUserById != null &&
        state.customer?.uid != event.order.customerUid) {
      _loadCustomer(event.order.customerUid);
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

  void _onCustomerArrived(
    _CustomerArrived event,
    Emitter<OrderDetailState> emit,
  ) {
    if (event.customer != null) emit(state.copyWith(customer: event.customer));
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

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
