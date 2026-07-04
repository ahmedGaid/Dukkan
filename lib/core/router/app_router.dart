import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/auth/pages/forgot_password_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/signup_page.dart';
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/splash/splash_page.dart';
import '../../presentation/widgets/common/coming_soon_page.dart';
import 'go_router_refresh_stream.dart';

/// Auth-guarded router. Redirect reads the [AuthBloc] session status and the
/// router refreshes whenever that status changes:
///   unknown        → splash (`/`) while Firebase resolves the session
///   unauthenticated → the auth pages only, else pushed to `/login`
///   authenticated   → `/home`, kept off splash + auth pages
class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  static const _authPages = {'/login', '/signup', '/forgot'};

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: _redirect,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/forgot',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      // Placeholders until their sessions land: shop page → C2b, search → C2c.
      GoRoute(
        path: '/shop/:id',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          return ComingSoonPage(
            icon: Icons.storefront_outlined,
            title: l10n.shopComingSoonTitle,
            message: l10n.shopComingSoonBody,
            appBarTitle: l10n.shopComingSoonTitle,
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          return ComingSoonPage(
            icon: Icons.search_rounded,
            title: l10n.searchComingSoonTitle,
            message: l10n.searchComingSoonBody,
            appBarTitle: l10n.searchComingSoonTitle,
          );
        },
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final session = _authBloc.state.session;
    final location = state.matchedLocation;

    switch (session) {
      case SessionStatus.unknown:
        return location == '/' ? null : '/';
      case SessionStatus.unauthenticated:
        return _authPages.contains(location) ? null : '/login';
      case SessionStatus.authenticated:
        return (location == '/' || _authPages.contains(location))
            ? '/home'
            : null;
    }
  }
}
