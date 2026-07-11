import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injector.dart';
import 'core/l10n/locale_controller.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/root_messenger_key.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/cart/bloc/cart_bloc.dart';
import 'presentation/favorites/bloc/favorites_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // On Flutter web the default Firestore transport (WebChannel/gRPC-web) is
  // often buffered to death by proxies/antivirus, so `.get()` fails with
  // "client is offline" even with a live connection. Force long-polling on web
  // to sidestep that (native mobile keeps the faster default). Must be set
  // before any Firestore call — i.e. before DI wires the datasources.
  if (kIsWeb) {
    FirebaseFirestore.instance.settings =
        const Settings(webExperimentalForceLongPolling: true);
  } else {
    // Crashlytics has no web target — native platforms only. Debug builds
    // still record locally but don't upload, so local runs aren't noise.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  await initDependencies();
  unawaited(sl<NotificationService>().init());
  runApp(const DukkanApp());
}

class DukkanApp extends StatelessWidget {
  const DukkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc first (router listens to it, FavoritesBloc watches it) and
    // provided above the router so every routed page can read it. CartBloc
    // and FavoritesBloc are also app-lifetime — one basket / one heart-state
    // feed across Home/Shop/Search/Cart/Checkout/Favorites. FavoritesBloc
    // uses the default lazy `create` (not `.value`) so its Firestore-backed
    // usecase isn't resolved until first read — never touched while signed
    // out, matching the DI convention below.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<CartBloc>.value(value: sl<CartBloc>()),
        BlocProvider<FavoritesBloc>(create: (_) => sl<FavoritesBloc>()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: sl<ThemeController>(),
        builder: (context, themeMode, _) {
          return ValueListenableBuilder<Locale>(
            valueListenable: sl<LocaleController>(),
            builder: (context, locale, _) {
              return MaterialApp.router(
                scaffoldMessengerKey: rootScaffoldMessengerKey,
                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)!.appName,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(locale),
                darkTheme: AppTheme.dark(locale),
                themeMode: themeMode,
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
          );
        },
      ),
    );
  }
}
