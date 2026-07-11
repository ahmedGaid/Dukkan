part of 'finance_bloc.dart';

enum FinanceStatus { loading, loaded, error }

class FinanceState extends Equatable {
  const FinanceState({this.status = FinanceStatus.loading, this.summary});

  final FinanceStatus status;
  final FinanceSummary? summary;

  FinanceState copyWith({FinanceStatus? status, FinanceSummary? summary}) {
    return FinanceState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [status, summary];
}
