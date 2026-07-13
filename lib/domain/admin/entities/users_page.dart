import 'package:equatable/equatable.dart';

import 'managed_user.dart';

/// One page of the console user list. Mirrors `AuditPage` — value-based
/// pagination (the cursor is the last row's `uid`, not a `DocumentSnapshot`),
/// so no Firestore type crosses into `domain/`.
class UsersPage extends Equatable {
  const UsersPage({required this.users, required this.hasMore});

  final List<ManagedUser> users;
  final bool hasMore;

  @override
  List<Object?> get props => [users, hasMore];
}
