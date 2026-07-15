import '../repositories/admin_drivers_repository.dart';

/// Console suspend/unsuspend toggle. [reason] required by the UI when
/// suspending, cleared on unsuspend. Thin pass-through.
class SetDriverSuspended {
  const SetDriverSuspended(this._repository);

  final AdminDriversRepository _repository;

  Future<void> call({required String uid, required bool value, String? reason}) =>
      _repository.setSuspended(uid: uid, value: value, reason: reason);
}
