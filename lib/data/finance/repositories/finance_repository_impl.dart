import '../../../domain/finance/entities/finance_summary.dart';
import '../../../domain/finance/repositories/finance_repository.dart';
import '../datasources/finance_remote_datasource.dart';

/// No offline branch, no caching — the founder pulls-to-refresh for fresh
/// numbers, and stale finance figures are worse than a network wait.
class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl(this._remote);

  final FinanceRemoteDataSource _remote;

  @override
  Future<FinanceSummary> getSummary() => _remote.getSummary();
}
