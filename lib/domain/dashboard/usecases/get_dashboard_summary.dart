import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

/// Loads the live console dashboard snapshot. Thin pass-through — matches
/// `GetFinanceSummary`.
class GetDashboardSummary {
  const GetDashboardSummary(this._repository);

  final DashboardRepository _repository;

  Future<DashboardSummary> call({required bool includeUsers}) =>
      _repository.getSummary(includeUsers: includeUsers);
}
