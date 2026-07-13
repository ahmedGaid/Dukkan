import '../entities/audit_filter.dart';
import '../entities/audit_page.dart';

/// Read-only access to the immutable `/auditLogs` trail. There is no write
/// path here by design — only the Worker (service account) writes entries.
abstract class AuditRepository {
  /// One page of entries matching [filter], newest first. Pass the previous
  /// page's last entry `createdAt` (ISO-8601 UTC) as [afterCreatedAt] to fetch
  /// the following page; null for the first page.
  Future<AuditPage> getEntries({
    required AuditFilter filter,
    String? afterCreatedAt,
  });
}
