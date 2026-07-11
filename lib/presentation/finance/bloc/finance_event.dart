part of 'finance_bloc.dart';

sealed class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on page open.
class FinanceStarted extends FinanceEvent {
  const FinanceStarted();
}

/// Pull-to-refresh — re-runs the exact same load as [FinanceStarted].
class FinanceRefreshRequested extends FinanceEvent {
  const FinanceRefreshRequested();
}
