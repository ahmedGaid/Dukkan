import '../../../domain/admin/entities/admin_profile.dart';
import '../../../domain/admin/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

/// Memoizes the staff profile for one uid for the app session (same intent as
/// `PlatformConfigRepositoryImpl`, but keyed by uid and caching the null
/// "not staff" result too — so a non-staff account never re-hits Firestore).
/// [reset] clears it on sign-out.
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  String? _cachedUid;
  AdminProfile? _cached;
  bool _hasCached = false;

  @override
  Future<AdminProfile?> getAdminProfile(String uid) async {
    if (_hasCached && _cachedUid == uid) return _cached;
    final profile = await _remote.get(uid);
    _cachedUid = uid;
    _cached = profile;
    _hasCached = true;
    return profile;
  }

  @override
  Future<AdminProfile?> getAdminProfileForUid(String uid) => _remote.get(uid);

  @override
  void reset() {
    _cachedUid = null;
    _cached = null;
    _hasCached = false;
  }
}
