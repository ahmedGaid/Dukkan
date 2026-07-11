import '../repositories/driver_repository.dart';

class SetDriverOnline {
  const SetDriverOnline(this._repository);

  final DriverRepository _repository;

  Future<void> call(String uid, bool isOnline) =>
      _repository.setOnline(uid, isOnline);
}
