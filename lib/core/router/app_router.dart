import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/auth/pages/forgot_password_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/signup_page.dart';
import '../../presentation/cart/pages/cart_page.dart';
import '../../presentation/cart/pages/checkout_page.dart';
import '../../presentation/cart/pages/order_placed_page.dart';
import '../../presentation/finance/pages/finance_page.dart';
import '../../domain/auth/entities/user_role.dart';
import '../../domain/order/entities/order.dart';
import '../../domain/product/entities/product.dart';
import '../../domain/shop/usecases/get_shop_by_owner.dart';
import '../../presentation/home/pages/home_page.dart';
import '../../presentation/shell/courier_home_shell.dart';
import '../../presentation/catalog/pages/collections_manager_page.dart';
import '../../presentation/catalog/pages/product_form_page.dart';
import '../../presentation/orders/order_viewer_role.dart';
import '../../presentation/orders/pages/order_detail_page.dart';
import '../../presentation/search/pages/search_page.dart';
import '../../presentation/shop/pages/product_detail_page.dart';
import '../../presentation/shop/pages/shop_onboarding_page.dart';
import '../../presentation/shop/pages/shop_page.dart';
import '../../presentation/splash/splash_page.dart';
import '../config/app_config.dart';
import '../di/injector.dart';
import 'go_router_refresh_stream.dart';

/// Auth-guarded router. Redirect reads the [AuthBloc] session status and the
/// router refreshes whenever that status changes:
///   unknown        → splash (`/`) while Firebase resolves the session
///   unauthenticated → the auth pages only, else pushed to `/login`
///   authenticated   → `/home`, kept off splash + auth pages — except an
///                     owner with no shop yet (S1b), who is sent to
///                     `/shop-onboarding` instead. That check only runs at
///                     the splash/auth-page entry point, never on every
///                     in-app navigation.
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
        path: '/courier',
        builder: (context, state) => const CourierHomeShell(),
      ),
      GoRoute(
        path: '/shop-onboarding',
        builder: (context, state) => const ShopOnboardingPage(),
      ),
      GoRoute(
        path: '/catalog/product-form',
        builder: (context, state) {
          final args = state.extra as ProductFormArgs;
          return ProductFormPage(shopId: args.shopId, product: args.product);
        },
      ),
      GoRoute(
        path: '/catalog/collections',
        builder: (context, state) =>
            CollectionsManagerPage(shopId: state.extra as String),
      ),
      GoRoute(
        path: '/shop/:id',
        builder: (context, state) => ShopPage(
          shopId: state.pathParameters['id']!,
          initialCategory: state.extra as String?,
        ),
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
        path: '/finance',
        builder: (context, state) => const FinancePage(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
          role: switch (state.uri.queryParameters['role']) {
            'owner' => OrderViewerRole.owner,
            'courier' => OrderViewerRole.courier,
            _ => OrderViewerRole.customer,
          },
        ),
      ),
    ],
  );

  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final session = _authBloc.state.session;
    final location = state.matchedLocation;

    switch (session) {
      case SessionStatus.unknown:
        return location == '/' ? null : '/';
      case SessionStatus.unauthenticated:
        return _authPages.contains(location) ? null : '/login';
      case SessionStatus.authenticated:
        // Founder-only finance summary (M13) — bounces anyone else who lands
        // on this path directly, since it's otherwise a normal in-app route.
        if (location == '/finance' &&
            _authBloc.state.user?.uid != AppConfig.founderUid) {
          return '/home';
        }
        if (location != '/' && !_authPages.contains(location)) return null;
        final user = _authBloc.state.user;
        if (user?.role == UserRole.courier) return '/courier';
        if (user?.role != UserRole.owner) return '/home';
        final shop = await sl<GetShopByOwner>()(user!.uid);
        return shop == null ? '/shop-onboarding' : '/home';
    }
  }
}
