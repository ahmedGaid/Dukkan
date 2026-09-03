import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/offline/offline_mutation_queue.dart';
import '../../../core/offline/pending_mutation.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/entities/order_status.dart';
import '../../../domain/order/usecases/watch_shop_orders.dart';

part 'owner_orders_event.dart';
part 'owner_orders_state.dart';

/// Drives the owner's order desk (S3). Subscribes to [WatchShopOrders] for
/// the signed-in owner's shop — newest first (query order lives in the
/// remote datasource). Page-scoped: one subscription per page-open, the shop
/// id is the factory param (mirrors [OrdersBloc]'s customerUid). Status
/// changes (accept/reject/advance) are one-shot [UpdateOrderStatus] calls
/// made directly from the card widget — same pattern as catalog CRUD — the
/// resulting status change comes back through this same stream. Initial
/// `pendingStatuses` is seeded from [OfflineMutationQueue.allPending] (a
/// mutation queued before this page opened, e.g. from a previous visit or an
/// app restart, must still show), then kept live via
/// [OfflineMutationQueue.watchAll] (O2 slice 1) so a queued mutation for one
/// of this shop's orders shows a pending-sync overlay before the real write
/// lands.
class OwnerOrdersBloc extends Bloc<OwnerOrdersEvent, OwnerOrdersState> {
  OwnerOrdersBloc({
    required String shopId,
    required WatchShopOrders watchShopOrders,
    required OfflineMutationQueue queue,
  })  : _shopId = shopId,
        _watchShopOrders = watchShopOrders,
        _queue = queue,
        super(
          OwnerOrdersState(
            pendingStatuses: {
              for (final mutation in queue.allPending)
                mutation.orderId: mutation.targetStatus,
            },
          ),
        ) {
    on<OwnerOrdersStarted>(_onStarted);
    on<OwnerOrdersRetryRequested>(_onStarted);
    on<_OwnerOrdersUpdated>(_onUpdated);
    on<_OwnerOrdersFailed>(_onFailed);
    on<_PendingMutationsUpdated>(_onPendingMutationsUpdated);

    _queueSub = _queue.watchAll().listen(
      (mutations) => add(_PendingMutationsUpdated(mutations)),
    );
  }

  final String _shopId;
  final WatchShopOrders _watchShopOrders;
  final OfflineMutationQueue _queue;
  StreamSubscription<List<Order>>? _sub;
  StreamSubscription<List<PendingMutation>>? _queueSub;

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

  void _onPendingMutationsUpdated(
    _PendingMutationsUpdated event,
    Emitter<OwnerOrdersState> emit,
  ) {
    final byOrder = <String, OrderStatus>{};
    for (final mutation in event.mutations) {
      byOrder[mutation.orderId] = mutation.targetStatus;
    }
    emit(state.copyWith(pendingStatuses: byOrder));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _queueSub?.cancel();
    return super.close();
  }
}
