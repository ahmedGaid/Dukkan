import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injector.dart';
import 'core/l10n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/cart/bloc/cart_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initDependencies();
  runApp(const DukkanApp());
}

class DukkanApp extends StatelessWidget {
  const DukkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc first (router listens to it) and provided above the router so
    // every routed page can read it. CartBloc is also app-lifetime — one
    // basket across Home/Shop/Search/Cart/Checkout.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<CartBloc>.value(value: sl<CartBloc>()),
      ],
      child: ValueListenableBuilder<Locale>(
        valueListenable: sl<LocaleController>(),
        builder: (context, locale, _) {
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(locale),
            darkTheme: AppTheme.dark(locale),
            locale: locale,
            supportedLocales: LocaleController.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: sl<AppRouter>().router,
          );
        },
      ),
    );
  }
}
