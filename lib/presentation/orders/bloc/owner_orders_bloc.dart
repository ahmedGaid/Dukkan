import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/order/entities/order.dart';
import '../../../domain/order/usecases/watch_shop_orders.dart';

part 'owner_orders_event.dart';
part 'owner_orders_state.dart';

/// Drives the owner's order desk (S3). Subscribes to [WatchShopOrders] for
/// the signed-in owner's shop — newest first (query order lives in the
/// remote datasource). Page-scoped: one subscription per page-open, the shop
/// id is the factory param (mirrors [OrdersBloc]'s customerUid). Status
/// changes (accept/reject/advance) are one-shot [UpdateOrderStatus] calls
/// made directly from the card widget — same pattern as catalog CRUD — the
/// resulting status change comes back through this same stream.
class OwnerOrdersBloc extends Bloc<OwnerOrdersEvent, OwnerOrdersState> {
  OwnerOrdersBloc({
    required String shopId,
    required WatchShopOrders watchShopOrders,
  })  : _shopId = shopId,
        _watchShopOrders = watchShopOrders,
        super(const OwnerOrdersState()) {
    on<OwnerOrdersStarted>(_onStarted);
    on<OwnerOrdersRetryRequested>(_onStarted);
    on<_OwnerOrdersUpdated>(_onUpdated);
    on<_OwnerOrdersFailed>(_onFailed);
  }

  final String _shopId;
  final WatchShopOrders _watchShopOrders;
  StreamSubscription<List<Order>>? _sub;

  Future<void> _onStarted(
    OwnerOrdersEvent event,
    Emitter<OwnerOrdersState> emit,
  ) async {
    emit(state.copyWith(status: OwnerOrdersStatus.loading));
    await _sub?.cancel();
    _sub = _watchShopOrders(_shopId).listen(
      (orders) => add(_OwnerOrdersUpdated(orders)),
      onError: (Object error) => add(_OwnerOrdersFailed(error)),
    );
  }

  void _onUpdated(_OwnerOrdersUpdated event, Emitter<OwnerOrdersState> emit) {
    emit(state.copyWith(status: OwnerOrdersStatus.loaded, orders: event.orders));
  }

  void _onFailed(_OwnerOrdersFailed event, Emitter<OwnerOrdersState> emit) {
    emit(state.copyWith(status: OwnerOrdersStatus.error));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
