import '../repositories/driver_repository.dart';

/// Fired once, right after a courier signup succeeds (`AuthBloc`) — writes
/// the suspended-by-default `/drivers/{uid}` doc.
class CreateDriverProfile {
  const CreateDriverProfile(this._repository);

  final DriverRepository _repository;

  Future<void> call({
    required String uid,
    required String name,
    String? phone,
  }) {
    return _repository.createDriverProfile(uid: uid, name: name, phone: phone);
  }
}
