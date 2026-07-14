part of 'geo_board_bloc.dart';

sealed class GeoBoardEvent extends Equatable {
  const GeoBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads every area (unfiltered, deactivated
/// included; the list is small enough to need no pagination).
class GeoBoardStarted extends GeoBoardEvent {
  const GeoBoardStarted();
}

class GeoBoardRetryRequested extends GeoBoardEvent {
  const GeoBoardRetryRequested();
}

class GeoBoardActiveToggled extends GeoBoardEvent {
  const GeoBoardActiveToggled(this.areaId, this.value);

  final String areaId;
  final bool value;

  @override
  List<Object?> get props => [areaId, value];
}

class GeoBoardCreateRequested extends GeoBoardEvent {
  const GeoBoardCreateRequested({
    required this.nameAr,
    required this.nameEn,
    required this.governorate,
    required this.city,
    this.deliveryFeeMinorOverride,
  });

  final String nameAr;
  final String nameEn;
  final String governorate;
  final String city;
  final int? deliveryFeeMinorOverride;

  @override
  List<Object?> get props =>
      [nameAr, nameEn, governorate, city, deliveryFeeMinorOverride];
}

class GeoBoardUpdateRequested extends GeoBoardEvent {
  const GeoBoardUpdateRequested({
    required this.areaId,
    required this.nameAr,
    required this.nameEn,
    required this.governorate,
    required this.city,
    this.deliveryFeeMinorOverride,
  });

  final String areaId;
  final String nameAr;
  final String nameEn;
  final String governorate;
  final String city;
  final int? deliveryFeeMinorOverride;

  @override
  List<Object?> get props =>
      [areaId, nameAr, nameEn, governorate, city, deliveryFeeMinorOverride];
}

class GeoBoardDeleteRequested extends GeoBoardEvent {
  const GeoBoardDeleteRequested(this.areaId);

  final String areaId;

  @override
  List<Object?> get props => [areaId];
}
