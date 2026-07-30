part of 'reports_bloc.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class ReportsStarted extends ReportsEvent {
  const ReportsStarted();
}

class ReportsRetryRequested extends ReportsEvent {
  const ReportsRetryRequested();
}

/// 7/30/90 — the period picker.
class ReportsPeriodChanged extends ReportsEvent {
  const ReportsPeriodChanged(this.periodDays);

  final int periodDays;

  @override
  List<Object?> get props => [periodDays];
}
