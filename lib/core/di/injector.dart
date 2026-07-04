import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../data/auth/datasources/auth_remote_datasource.dart';
import '../../data/auth/repositories/auth_repository_impl.dart';
import '../../domain/auth/repositories/auth_repository.dart';
import '../../domain/auth/usecases/log_in.dart';
import '../../domain/auth/usecases/log_out.dart';
import '../../domain/auth/usecases/send_password_reset.dart';
import '../../domain/auth/usecases/sign_up.dart';
import '../../domain/auth/usecases/watch_auth_state.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../l10n/locale_controller.dart';
import '../network/network_info.dart';
import '../router/app_router.dart';

final sl = GetIt.instance;

/// DI registration order: network → firebase → datasources → repositories →
/// use cases → BLoCs → router (Shoppy convention; `shared_preferences` slots in
/// ahead of network once a cache datasource needs it). App-lifetime BLoCs are
/// lazy singletons. Everything is lazy, so nothing touches Firebase until first
/// resolved — tests override `AuthRepository` with a fake before that happens.
Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<LocaleController>(() => LocaleController());

  // Firebase
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Auth — data
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(auth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // Auth — use cases
  sl.registerLazySingleton(() => WatchAuthState(sl()));
  sl.registerLazySingleton(() => LogIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SendPasswordReset(sl()));
  sl.registerLazySingleton(() => LogOut(sl()));

  // Auth — bloc (app lifetime)
  sl.registerLazySingleton(
    () => AuthBloc(
      watchAuthState: sl(),
      logIn: sl(),
      signUp: sl(),
      sendPasswordReset: sl(),
      logOut: sl(),
    ),
  );

  // Router (reads AuthBloc)
  sl.registerLazySingleton(() => AppRouter(sl()));
}
