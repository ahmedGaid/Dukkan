import 'package:equatable/equatable.dart';

import 'audit_entry.dart';

/// One page of audit entries plus whether another page likely exists. The
/// cursor is value-based (the last entry's `createdAt`), so the domain never
/// touches a Firestore `DocumentSnapshot` — the BLoC just passes the last
/// entry's timestamp back in to fetch the next page.
class AuditPage extends Equatable {
  const AuditPage({required this.entries, required this.hasMore});

  final List<AuditEntry> entries;
  final bool hasMore;

  @override
  List<Object?> get props => [entries, hasMore];
}
