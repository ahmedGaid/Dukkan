import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/order/entities/order.dart';
import '../../../domain/order/usecases/watch_customer_orders.dart';

part 'orders_event.dart';
part 'orders_state.dart';

/// Drives the customer "Orders" tab. Subscribes to [WatchCustomerOrders] for
/// the signed-in customer — newest first (query order lives in the remote
/// datasource). Page-scoped: one subscription per tab-open, the customer uid
/// is the factory param (mirrors [ProductsBloc]'s shopId).
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({
    required String customerUid,
    required WatchCustomerOrders watchCustomerOrders,
  })  : _customerUid = customerUid,
        _watchCustomerOrders = watchCustomerOrders,
        super(const OrdersState()) {
    on<OrdersStarted>(_onStarted);
    on<OrdersRetryRequested>(_onStarted);
    on<_OrdersUpdated>(_onUpdated);
    on<_OrdersFailed>(_onFailed);
  }

  final String _customerUid;
  final WatchCustomerOrders _watchCustomerOrders;
  StreamSubscription<List<Order>>? _sub;

  Future<void> _onStarted(OrdersEvent event, Emitter<OrdersState> emit) async {
    emit(state.copyWith(status: OrdersStatus.loading));
    await _sub?.cancel();
    _sub = _watchCustomerOrders(_customerUid).listen(
      (orders) => add(_OrdersUpdated(orders)),
      onError: (Object error) => add(_OrdersFailed(error)),
    );
  }

  void _onUpdated(_OrdersUpdated event, Emitter<OrdersState> emit) {
    emit(state.copyWith(status: OrdersStatus.loaded, orders: event.orders));
  }

  void _onFailed(_OrdersFailed event, Emitter<OrdersState> emit) {
    emit(state.copyWith(status: OrdersStatus.error));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
