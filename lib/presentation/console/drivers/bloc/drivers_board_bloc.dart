import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/get_all_areas.dart';
import '../../../../domain/admin/usecases/get_all_drivers.dart';
import '../../../../domain/areas/entities/area.dart';
import '../../../../domain/driver/entities/driver.dart';

part 'drivers_board_event.dart';
part 'drivers_board_state.dart';

/// Drives the console driver board (`/console/drivers`, FC11). Loads every
/// driver + area once (the platform's driver pool is small) and filters
/// entirely client-side; a mutation on the detail page (`DriverDetailBloc`)
/// doesn't touch this bloc — reopening the board reloads (mirrors
/// `ShopsBoardBloc`). Areas are loaded unfiltered (incl. inactive, like the
/// detail page's picker) so a row's `areaIds` can show names, not raw ids.
class DriversBoardBloc extends Bloc<DriversBoardEvent, DriversBoardState> {
  DriversBoardBloc({required GetAllDrivers getAllDrivers, required GetAllAreas getAllAreas})
      : _getAllDrivers = getAllDrivers,
        _getAllAreas = getAllAreas,
        super(const DriversBoardState()) {
    on<DriversBoardStarted>(_onLoad);
    on<DriversBoardRetryRequested>(_onLoad);
    on<DriversBoardFilterChanged>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
  }

  final GetAllDrivers _getAllDrivers;
  final GetAllAreas _getAllAreas;

  Future<void> _onLoad(DriversBoardEvent event, Emitter<DriversBoardState> emit) async {
    emit(state.copyWith(status: DriversBoardStatus.loading));
    try {
      final results = await Future.wait([_getAllDrivers(), _getAllAreas()]);
      emit(state.copyWith(
        status: DriversBoardStatus.loaded,
        allDrivers: results[0] as List<Driver>,
        areas: results[1] as List<Area>,
      ));
    } catch (_) {
      emit(state.copyWith(status: DriversBoardStatus.error));
    }
  }
}
