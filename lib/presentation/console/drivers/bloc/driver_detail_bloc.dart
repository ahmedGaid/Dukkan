import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/entities/driver_performance.dart';
import '../../../../domain/admin/usecases/get_all_areas.dart';
import '../../../../domain/admin/usecases/get_driver_assigned_orders.dart';
import '../../../../domain/admin/usecases/get_driver_by_id.dart';
import '../../../../domain/admin/usecases/get_driver_performance.dart';
import '../../../../domain/admin/usecases/set_driver_suspended.dart';
import '../../../../domain/admin/usecases/set_driver_verified.dart';
import '../../../../domain/admin/usecases/update_driver.dart';
import '../../../../domain/areas/entities/area.dart';
import '../../../../domain/driver/entities/driver.dart';
import '../../../../domain/order/entities/order.dart';

part 'driver_detail_event.dart';
part 'driver_detail_state.dart';

/// Drives the console driver detail page (`/console/drivers/:uid`, FC11).
/// Every mutation is Firestore-direct + best-effort audit (see
/// `AdminDriversRepositoryImpl`); after each one succeeds this reloads the
/// driver by id so the page always shows the post-mutation truth, not an
/// optimistic guess (mirrors `ShopDetailBloc`). Performance + assigned orders
/// load once on open, independent of the driver reload.
class DriverDetailBloc extends Bloc<DriverDetailEvent, DriverDetailState> {
  DriverDetailBloc({
    required Driver seed,
    required GetDriverById getDriverById,
    required SetDriverSuspended setDriverSuspended,
    required SetDriverVerified setDriverVerified,
    required UpdateDriver updateDriver,
    required GetDriverPerformance getDriverPerformance,
    required GetDriverAssignedOrders getDriverAssignedOrders,
    required GetAllAreas getAllAreas,
  })  : _getDriverById = getDriverById,
        _setDriverSuspended = setDriverSuspended,
        _setDriverVerified = setDriverVerified,
        _updateDriver = updateDriver,
        _getDriverPerformance = getDriverPerformance,
        _getDriverAssignedOrders = getDriverAssignedOrders,
        _getAllAreas = getAllAreas,
        super(DriverDetailState(driver: seed)) {
    on<DriverDetailStarted>(_onStarted);
    on<DriverDetailSetSuspendedRequested>(
      (e, emit) => _runAction(
        emit,
        () => _setDriverSuspended(uid: state.driver.uid, value: e.value, reason: e.reason),
      ),
    );
    on<DriverDetailSetVerifiedRequested>(
      (e, emit) => _runAction(
        emit,
        () => _setDriverVerified(uid: state.driver.uid, value: e.value),
      ),
    );
    on<DriverDetailUpdateRequested>(
      (e, emit) => _runAction(
        emit,
        () => _updateDriver(
          uid: state.driver.uid,
          name: e.name,
          phone: e.phone,
          areaIds: e.areaIds,
          maxActiveOrders: e.maxActiveOrders,
          vehicleType: e.vehicleType,
          vehiclePlate: e.vehiclePlate,
          idDocUrl: e.idDocUrl,
        ),
      ),
    );

    add(const DriverDetailStarted());
  }

  final GetDriverById _getDriverById;
  final SetDriverSuspended _setDriverSuspended;
  final SetDriverVerified _setDriverVerified;
  final UpdateDriver _updateDriver;
  final GetDriverPerformance _getDriverPerformance;
  final GetDriverAssignedOrders _getDriverAssignedOrders;
  final GetAllAreas _getAllAreas;

  Future<void> _onStarted(
    DriverDetailStarted event,
    Emitter<DriverDetailState> emit,
  ) async {
    try {
      final results = await Future.wait([
        _getDriverPerformance(state.driver.uid),
        _getDriverAssignedOrders(state.driver.uid),
        _getAllAreas(),
      ]);
      emit(state.copyWith(
        performance: results[0] as DriverPerformance,
        assignedOrders: results[1] as List<Order>,
        areas: results[2] as List<Area>,
        secondaryLoaded: true,
      ));
    } catch (_) {
      // The primary driver card still works without this — leave the
      // performance/assigned-orders card in its empty shimmer state rather
      // than failing the whole page.
    }
  }

  /// Runs one Firestore-direct mutation; on success reloads the driver by id
  /// so the page reflects the real post-mutation state. On failure, surfaces
  /// [DriverDetailState.actionError] for a snackbar; the page's data stays
  /// as-is.
  Future<void> _runAction(
    Emitter<DriverDetailState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: null));
    try {
      await action();
      final reloaded = await _getDriverById(state.driver.uid);
      emit(state.copyWith(actionBusy: false, driver: reloaded ?? state.driver));
    } catch (e) {
      emit(state.copyWith(actionBusy: false, actionError: e.toString()));
    }
  }
}
