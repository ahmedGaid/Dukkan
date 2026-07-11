import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetUserById {
  const GetUserById(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call(String uid) => _repository.getUserById(uid);
}
