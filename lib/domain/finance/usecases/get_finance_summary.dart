import '../entities/finance_summary.dart';
import '../repositories/finance_repository.dart';

/// Loads the founder finance summary. Thin pass-through — matches `GetAreas`.
class GetFinanceSummary {
  const GetFinanceSummary(this._repository);

  final FinanceRepository _repository;

  Future<FinanceSummary> call() => _repository.getSummary();
}
