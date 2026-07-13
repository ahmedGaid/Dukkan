import '../../../domain/dashboard/entities/dashboard_summary.dart';
import '../../../domain/dashboard/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

/// No offline branch, no caching — the console refreshes for live numbers, and
/// a stale platform figure is worse than a short network wait (mirrors
/// `FinanceRepositoryImpl`).
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<DashboardSummary> getSummary({required bool includeUsers}) =>
      _remote.getSummary(includeUsers: includeUsers);
}
