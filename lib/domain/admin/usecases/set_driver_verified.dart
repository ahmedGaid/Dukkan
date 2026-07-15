import '../repositories/admin_drivers_repository.dart';

/// Console identity-verification toggle. Thin pass-through.
class SetDriverVerified {
  const SetDriverVerified(this._repository);

  final AdminDriversRepository _repository;

  Future<void> call({required String uid, required bool value}) =>
      _repository.setVerified(uid: uid, value: value);
}
