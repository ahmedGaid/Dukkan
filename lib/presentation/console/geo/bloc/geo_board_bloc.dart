import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/usecases/create_area.dart';
import '../../../../domain/admin/usecases/delete_area.dart';
import '../../../../domain/admin/usecases/get_all_areas.dart';
import '../../../../domain/admin/usecases/set_area_active.dart';
import '../../../../domain/admin/usecases/update_area.dart';
import '../../../../domain/areas/entities/area.dart';

part 'geo_board_event.dart';
part 'geo_board_state.dart';

/// Drives the console geo board (`/console/geo`, FC9). Every mutation is
/// Firestore-direct + best-effort audit (see `AdminGeoRepositoryImpl`); on
/// success this reloads the whole list, mirroring `TaxonomyBoardBloc`.
class GeoBoardBloc extends Bloc<GeoBoardEvent, GeoBoardState> {
  GeoBoardBloc({
    required GetAllAreas getAllAreas,
    required CreateArea createArea,
    required UpdateArea updateArea,
    required SetAreaActive setAreaActive,
    required DeleteArea deleteArea,
  })  : _getAllAreas = getAllAreas,
        _createArea = createArea,
        _updateArea = updateArea,
        _setAreaActive = setAreaActive,
        _deleteArea = deleteArea,
        super(const GeoBoardState()) {
    on<GeoBoardStarted>(_onLoad);
    on<GeoBoardRetryRequested>(_onLoad);
    on<GeoBoardActiveToggled>(
      (e, emit) => _runAction(
        emit,
        () => _setAreaActive(areaId: e.areaId, value: e.value),
      ),
    );
    on<GeoBoardCreateRequested>(
      (e, emit) => _runAction(
        emit,
        () => _createArea(
          nameAr: e.nameAr,
          nameEn: e.nameEn,
          governorate: e.governorate,
          city: e.city,
          deliveryFeeMinorOverride: e.deliveryFeeMinorOverride,
        ),
      ),
    );
    on<GeoBoardUpdateRequested>(
      (e, emit) => _runAction(
        emit,
        () => _updateArea(
          areaId: e.areaId,
          nameAr: e.nameAr,
          nameEn: e.nameEn,
          governorate: e.governorate,
          city: e.city,
          deliveryFeeMinorOverride: e.deliveryFeeMinorOverride,
        ),
      ),
    );
    on<GeoBoardDeleteRequested>(
      (e, emit) => _runAction(emit, () => _deleteArea(e.areaId)),
    );
  }

  final GetAllAreas _getAllAreas;
  final CreateArea _createArea;
  final UpdateArea _updateArea;
  final SetAreaActive _setAreaActive;
  final DeleteArea _deleteArea;

  Future<void> _onLoad(GeoBoardEvent event, Emitter<GeoBoardState> emit) async {
    emit(state.copyWith(status: GeoBoardStatus.loading));
    try {
      final areas = await _getAllAreas();
      emit(state.copyWith(status: GeoBoardStatus.loaded, areas: areas));
    } catch (_) {
      emit(state.copyWith(status: GeoBoardStatus.error));
    }
  }

  /// Runs one Firestore-direct mutation; on success reloads the whole list.
  /// On failure, surfaces [GeoBoardState.actionError] for a snackbar and
  /// keeps the last-known-good list (mirrors `TaxonomyBoardBloc`).
  Future<void> _runAction(
    Emitter<GeoBoardState> emit,
    Future<void> Function() action,
  ) async {
    emit(state.copyWith(actionBusy: true, actionError: false));
    try {
      await action();
      final areas = await _getAllAreas();
      emit(state.copyWith(status: GeoBoardStatus.loaded, actionBusy: false, areas: areas));
    } catch (_) {
      emit(state.copyWith(actionBusy: false, actionError: true));
    }
  }
}
