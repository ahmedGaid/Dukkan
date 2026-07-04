import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Streams the signed-in user (null when signed out). The app-wide AuthBloc
/// listens to this to drive routing.
class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.authStateChanges();
}
