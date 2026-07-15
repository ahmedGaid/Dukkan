part of 'drivers_board_bloc.dart';

sealed class DriversBoardEvent extends Equatable {
  const DriversBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open — loads every driver (unfiltered; the board
/// filters client-side, the driver count is small).
class DriversBoardStarted extends DriversBoardEvent {
  const DriversBoardStarted();
}

class DriversBoardRetryRequested extends DriversBoardEvent {
  const DriversBoardRetryRequested();
}

/// Filter chip changed. Null = الكل (all).
class DriversBoardFilterChanged extends DriversBoardEvent {
  const DriversBoardFilterChanged(this.filter);

  final DriversBoardFilter? filter;

  @override
  List<Object?> get props => [filter];
}
