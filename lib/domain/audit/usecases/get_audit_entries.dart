import '../entities/audit_filter.dart';
import '../entities/audit_page.dart';
import '../repositories/audit_repository.dart';

/// Loads one page of audit entries for the console viewer. Thin pass-through —
/// matches `GetFinanceSummary`.
class GetAuditEntries {
  const GetAuditEntries(this._repository);

  final AuditRepository _repository;

  Future<AuditPage> call({
    required AuditFilter filter,
    String? afterCreatedAt,
  }) =>
      _repository.getEntries(filter: filter, afterCreatedAt: afterCreatedAt);
}
