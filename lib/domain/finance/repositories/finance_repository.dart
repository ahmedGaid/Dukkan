import '../entities/finance_summary.dart';

/// Finance boundary — founder-only, cross-shop aggregate read (M13). Always
/// a fresh remote read (pull-to-refresh is the only "cache invalidation" the
/// page needs); no offline branch, same contract as `OrderRepository`.
abstract class FinanceRepository {
  Future<FinanceSummary> getSummary();
}
