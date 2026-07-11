import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/areas/entities/area.dart';
import '../../../domain/areas/usecases/get_areas.dart';
import '../../../domain/order/entities/order.dart';
import '../../../domain/order/usecases/watch_driver_active_orders.dart';
import '../../../domain/order/usecases/watch_driver_order_history.dart';

part 'deliveries_event.dart';
part 'deliveries_state.dart';

/// Drives the courier's deliveries list (Session 10): two independent
/// realtime subscriptions — active (`preparing`/`outForDelivery`, sorted
/// oldest-assigned-first so the next job is always on top) and history
/// (`delivered`, newest first, capped at 20 by the datasource) — feeding one
/// segmented page, plus a one-shot area list for each card's district label.
/// Status advances happen on the order-detail page (`OrderDetailBloc`,
/// courier role) and come back through these same streams, so no local patch
/// is needed here. App-session-scoped: the driver uid is the factory param
/// (mirrors [OrdersBloc]'s customerUid).
class DeliveriesBloc extends Bloc<DeliveriesEvent, DeliveriesState> {
  DeliveriesBloc({
    required String driverUid,
    required WatchDriverActiveOrders watchActive,
    required WatchDriverOrderHistory watchHistory,
    required GetAreas getAreas,
  })  : _driverUid = driverUid,
        _watchActive = watchActive,
        _watchHistory = watchHistory,
        _getAreas = getAreas,
        super(const DeliveriesState()) {
    on<DeliveriesStarted>(_onStarted);
    on<DeliveriesTabChanged>(_onTabChanged);
    on<_ActiveArrived>(_onActiveArrived);
    on<_ActiveFailed>(_onActiveFailed);
    on<_HistoryArrived>(_onHistoryArrived);
    on<_HistoryFailed>(_onHistoryFailed);
    on<_AreasArrived>(_onAreasArrived);
  }

  final String _driverUid;
  final WatchDriverActiveOrders _watchActive;
  final WatchDriverOrderHistory _watchHistory;
  final GetAreas _getAreas;
  StreamSubscription<List<Order>>? _activeSub;
  StreamSubscription<List<Order>>? _historySub;

  Future<void> _onStarted(
    DeliveriesEvent event,
    Emitter<DeliveriesState> emit,
  ) async {
    emit(state.copyWith(
      activeStatus: DeliveriesListStatus.loading,
      historyStatus: DeliveriesListStatus.loading,
    ));
    await _activeSub?.cancel();
    await _historySub?.cancel();
    _activeSub = _watchActive(_driverUid).listen(
      (orders) => add(_ActiveArrived(orders)),
      onError: (Object error) => add(_ActiveFailed(error)),
    );
    _historySub = _watchHistory(_driverUid).listen(
      (orders) => add(_HistoryArrived(orders)),
      onError: (Object error) => add(_HistoryFailed(error)),
    );
    try {
      add(_AreasArrived(await _getAreas()));
    } catch (_) {
      // Display-only (card district label) — never blocks the lists.
    }
  }

  void _onTabChanged(DeliveriesTabChanged event, Emitter<DeliveriesState> emit) {
    emit(state.copyWith(tab: event.tab));
  }

  void _onActiveArrived(_ActiveArrived event, Emitter<DeliveriesState> emit) {
    final orders = [...event.orders]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    emit(state.copyWith(
      activeStatus: DeliveriesListStatus.loaded,
      activeOrders: orders,
    ));
  }

  void _onActiveFailed(_ActiveFailed event, Emitter<DeliveriesState> emit) {
    emit(state.copyWith(activeStatus: DeliveriesListStatus.error));
  }

  void _onHistoryArrived(_HistoryArrived event, Emitter<DeliveriesState> emit) {
    emit(state.copyWith(
      historyStatus: DeliveriesListStatus.loaded,
      historyOrders: event.orders,
    ));
  }

  void _onHistoryFailed(_HistoryFailed event, Emitter<DeliveriesState> emit) {
    emit(state.copyWith(historyStatus: DeliveriesListStatus.error));
  }

  void _onAreasArrived(_AreasArrived event, Emitter<DeliveriesState> emit) {
    emit(state.copyWith(areas: event.areas));
  }

  @override
  Future<void> close() {
    _activeSub?.cancel();
    _historySub?.cancel();
    return super.close();
  }
}
