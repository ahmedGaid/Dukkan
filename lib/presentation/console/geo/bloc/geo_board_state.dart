part of 'geo_board_bloc.dart';

enum GeoBoardStatus { loading, loaded, error }

class GeoBoardState extends Equatable {
  const GeoBoardState({
    this.status = GeoBoardStatus.loading,
    this.areas = const [],
    this.actionBusy = false,
    this.actionError = false,
  });

  final GeoBoardStatus status;

  /// Sorted by `sort` ascending, deactivated areas included.
  final List<Area> areas;

  final bool actionBusy;
  final bool actionError;

  GeoBoardState copyWith({
    GeoBoardStatus? status,
    List<Area>? areas,
    bool? actionBusy,
    bool? actionError,
  }) {
    return GeoBoardState(
      status: status ?? this.status,
      areas: areas ?? this.areas,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [status, areas, actionBusy, actionError];
}
