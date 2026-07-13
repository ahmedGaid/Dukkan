import '../entities/managed_user.dart';
import '../entities/users_page.dart';

/// Read-only, Firestore-direct access to `/users` for the console (rules
/// allow it via `hasPerm('users.read')` — see `firestore.rules`). No write
/// path here; every mutation goes through [AdminUserActions] instead.
abstract class AdminUsersRepository {
  /// One page of users, newest-doc-id-order via [FieldPath.documentId] (never
  /// `createdAt` — that field's type differs between client- and Worker-
  /// created docs, see `firebase.js`'s `fsTimestamp`). [cursor] is the
  /// previous page's last `uid`; null for the first page.
  Future<UsersPage> getUsers({String? role, String? status, String? cursor});

  /// Exact-match lookup; null when no user has that email.
  Future<ManagedUser?> getByEmail(String email);

  /// Exact-match lookup; null when no user has that phone.
  Future<ManagedUser?> getByPhone(String phone);
}
