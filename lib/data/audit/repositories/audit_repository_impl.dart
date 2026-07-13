import '../../../domain/audit/entities/audit_filter.dart';
import '../../../domain/audit/entities/audit_page.dart';
import '../../../domain/audit/repositories/audit_repository.dart';
import '../datasources/audit_remote_datasource.dart';

/// No cache — the audit trail is read live every time (a stale security log is
/// worse than a network wait, same contract as `FinanceRepositoryImpl`).
class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl(this._remote);

  final AuditRemoteDataSource _remote;

  @override
  Future<AuditPage> getEntries({
    required AuditFilter filter,
    String? afterCreatedAt,
  }) =>
      _remote.getEntries(filter: filter, afterCreatedAt: afterCreatedAt);
}
