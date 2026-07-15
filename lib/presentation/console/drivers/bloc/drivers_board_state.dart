part of 'drivers_board_bloc.dart';

enum DriversBoardStatus { loading, loaded, error }

/// The four filter chips FILE_11 specifies — mutually exclusive buckets over
/// the same driver list, not independent toggles.
enum DriversBoardFilter { pendingActivation, active, suspended, online }

class DriversBoardState extends Equatable {
  const DriversBoardState({
    this.status = DriversBoardStatus.loading,
    this.allDrivers = const [],
    this.areas = const [],
    this.filter,
  });

  final DriversBoardStatus status;
  final List<Driver> allDrivers;
  final List<Area> areas;
  final DriversBoardFilter? filter;

  /// [allDrivers] narrowed by the filter chip. `pendingActivation` = still
  /// suspended and never verified (a brand-new signup); `active` = not
  /// suspended (verified or not); `suspended` = suspended regardless of
  /// verification; `online` = currently online, any status.
  List<Driver> get filtered {
    return switch (filter) {
      DriversBoardFilter.pendingActivation =>
        allDrivers.where((d) => d.isSuspended && !d.isVerified).toList(growable: false),
      DriversBoardFilter.active =>
        allDrivers.where((d) => !d.isSuspended).toList(growable: false),
      DriversBoardFilter.suspended =>
        allDrivers.where((d) => d.isSuspended).toList(growable: false),
      DriversBoardFilter.online =>
        allDrivers.where((d) => d.isOnline).toList(growable: false),
      null => allDrivers,
    };
  }

  static const _unset = Object();

  DriversBoardState copyWith({
    DriversBoardStatus? status,
    List<Driver>? allDrivers,
    List<Area>? areas,
    Object? filter = _unset,
  }) {
    return DriversBoardState(
      status: status ?? this.status,
      allDrivers: allDrivers ?? this.allDrivers,
      areas: areas ?? this.areas,
      filter: filter == _unset ? this.filter : filter as DriversBoardFilter?,
    );
  }

  @override
  List<Object?> get props => [status, allDrivers, areas, filter];
}
