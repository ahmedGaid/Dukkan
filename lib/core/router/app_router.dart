import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/auth/pages/forgot_password_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/signup_page.dart';
import '../../presentation/cart/pages/cart_page.dart';
import '../../presentation/cart/pages/checkout_page.dart';
import '../../presentation/cart/pages/order_placed_page.dart';
import '../../domain/order/entities/order.dart';
import '../../domain/product/entities/product.dart';
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/orders/pages/order_detail_page.dart';
import '../../presentation/search/pages/search_page.dart';
import '../../presentation/shop/pages/product_detail_page.dart';
import '../../presentation/shop/pages/shop_page.dart';
import '../../presentation/splash/splash_page.dart';
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
      GoRoute(
        path: '/shop/:id',
        builder: (context, state) =>
            ShopPage(shopId: state.pathParameters['id']!),
        routes: [
          // Nested so the shop id stays in the path. The grid seeds `extra` with
          // the tapped product (no refetch); a cold open falls back to GetProduct.
          GoRoute(
            path: 'product/:pid',
            builder: (context, state) => ProductDetailPage(
              productId: state.pathParameters['pid']!,
              seed: state.extra as Product?,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/order-placed',
        builder: (context, state) =>
            OrderPlacedPage(order: state.extra as Order),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) =>
            OrderDetailPage(orderId: state.pathParameters['id']!),
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
