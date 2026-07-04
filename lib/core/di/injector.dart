import 'package:get_it/get_it.dart';

import '../l10n/locale_controller.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

/// DI registration order: prefs → network → datasources → repositories →
/// use cases → BLoCs (Shoppy convention). Only network + locale exist as of
/// F2; later sessions insert into this order, not append blindly.
Future<void> initDependencies() async {
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<LocaleController>(() => LocaleController());
}
