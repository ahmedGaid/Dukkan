import 'package:go_router/go_router.dart';

import '../../presentation/splash/splash_page.dart';

/// Route shell. Auth-guarded redirects land in F3 once real Auth exists.
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    ],
  );
}
