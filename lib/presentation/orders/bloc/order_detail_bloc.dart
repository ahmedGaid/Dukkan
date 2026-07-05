import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/order/entities/order.dart';
import '../../../domain/order/usecases/cancel_order.dart';
import '../../../domain/order/usecases/watch_order.dart';

part 'order_detail_event.dart';
part 'order_detail_state.dart';

/// Drives one order's tracking page. Subscribes to [WatchOrder] for realtime
/// status; cancel is a one-shot [CancelOrder] call — the resulting status
/// change comes back through the same stream, so a success needs no local
/// patch. Page-scoped: the order id is the factory param (mirrors
/// [ProductsBloc]'s shopId).
class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc({
    required String orderId,
    required WatchOrder watchOrder,
    required CancelOrder cancelOrder,
  })  : _orderId = orderId,
        _watchOrder = watchOrder,
        _cancelOrder = cancelOrder,
        super(const OrderDetailState()) {
    on<OrderDetailStarted>(_onStarted);
    on<OrderDetailCancelRequested>(_onCancelRequested);
    on<_OrderArrived>(_onArrived);
    on<_OrderWatchFailed>(_onWatchFailed);
    on<_OrderCancelFailed>(_onCancelFailed);
  }

  final String _orderId;
  final WatchOrder _watchOrder;
  final CancelOrder _cancelOrder;
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
    ));
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

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
