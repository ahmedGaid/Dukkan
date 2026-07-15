import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/auth/pages/forgot_password_page.dart';
import '../../presentation/auth/pages/login_page.dart';
import '../../presentation/auth/pages/signup_page.dart';
import '../../presentation/cart/pages/cart_page.dart';
import '../../presentation/cart/pages/checkout_page.dart';
import '../../presentation/cart/pages/order_placed_page.dart';
import '../../domain/admin/entities/managed_user.dart';
import '../../presentation/console/audit/pages/audit_log_page.dart';
import '../../presentation/console/dashboard/pages/dashboard_page.dart';
import '../../presentation/console/drivers/pages/driver_detail_page.dart';
import '../../presentation/console/drivers/pages/drivers_board_page.dart';
import '../../presentation/console/geo/pages/geo_board_page.dart';
import '../../presentation/console/orders/pages/orders_board_page.dart';
import '../../presentation/console/shell/console_sections.dart';
import '../../presentation/console/shell/console_shell.dart';
import '../../presentation/console/products/pages/products_board_page.dart';
import '../../presentation/console/shops/pages/create_shop_page.dart';
import '../../presentation/console/shops/pages/shop_detail_page.dart';
import '../../presentation/console/shops/pages/shops_board_page.dart';
import '../../presentation/console/taxonomy/pages/taxonomy_board_page.dart';
import '../../presentation/console/users/pages/user_detail_page.dart';
import '../../presentation/console/users/pages/users_list_page.dart';
import '../../presentation/finance/pages/finance_page.dart';
import '../../domain/admin/entities/admin_profile.dart';
import '../../domain/admin/entities/permissions.dart';
import '../../domain/auth/entities/user_role.dart';
import '../../domain/order/entities/order.dart';
import '../../domain/driver/entities/driver.dart';
import '../../domain/product/entities/product.dart';
import '../../domain/shop/entities/shop.dart';
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
      // Founder Console (Phase 7). Desktop-first back office behind an admin
      // guard (see `_redirect`). The shell hosts one child per vertical; routes
      // land across sessions 03–17.
      ShellRoute(
        builder: (context, state, child) => ConsoleShell(child: child),
        routes: [
          GoRoute(
            path: '/console',
            builder: (context, state) => const DashboardPage(),
          ),
          // Immutable audit trail viewer (FILE_04). Gated by `auditlogs.read`
          // in the console menu + Firestore rules; the shell provides the app
          // bar/title, this route just supplies the body.
          GoRoute(
            path: '/console/audit',
            builder: (context, state) => const AuditLogPage(),
          ),
          // User management (FILE_06). Gated by `users.read` in the console
          // menu + Firestore rules. The detail route is always reached via
          // the list row's `extra: ManagedUser` — see `UserDetailPage`.
          GoRoute(
            path: '/console/users',
            builder: (context, state) => const UsersListPage(),
          ),
          GoRoute(
            path: '/console/users/:uid',
            builder: (context, state) =>
                UserDetailPage(seed: state.extra as ManagedUser?),
          ),
          // Shop management (FILE_07). Gated by `shops.update` in the console
          // menu + Firestore rules. `/new` is a static route so it never
          // matches the `:id` param route below it (go_router prefers a
          // literal segment match over a param match).
          GoRoute(
            path: '/console/shops',
            builder: (context, state) => const ShopsBoardPage(),
          ),
          GoRoute(
            path: '/console/shops/new',
            builder: (context, state) => const CreateShopPage(),
          ),
          GoRoute(
            path: '/console/shops/:id',
            builder: (context, state) =>
                ShopDetailPage(seed: state.extra as Shop?),
          ),
          // Product management (FILE_08). Gated by `products.update` in the
          // console menu + Firestore rules. No detail route — row/bulk
          // actions live inline on the board (see `ProductsBoardPage`), and
          // edit reuses the existing owner `/catalog/product-form` route.
          GoRoute(
            path: '/console/products',
            builder: (context, state) => const ProductsBoardPage(),
          ),
          // Order admin (FILE_10). Gated by `orders.read` in the console menu
          // + Firestore rules. No detail route — row tap reuses the shared
          // `/order/:id?role=staff` route (see below).
          GoRoute(
            path: '/console/orders',
            builder: (context, state) => const OrdersBoardPage(),
          ),
          // Taxonomy + geo management (FILE_09). Gated by `taxonomy.edit`/
          // `geo.edit` in the console menu + Firestore rules.
          GoRoute(
            path: '/console/taxonomy',
            builder: (context, state) => const TaxonomyBoardPage(),
          ),
          GoRoute(
            path: '/console/geo',
            builder: (context, state) => const GeoBoardPage(),
          ),
          // Driver admin (FILE_11). Gated by `drivers.manage` in the console
          // menu + Firestore rules. The detail route is always reached via
          // the board row's `extra: Driver` — see `DriverDetailPage`.
          GoRoute(
            path: '/console/drivers',
            builder: (context, state) => const DriversBoardPage(),
          ),
          GoRoute(
            path: '/console/drivers/:uid',
            builder: (context, state) =>
                DriverDetailPage(seed: state.extra as Driver?),
          ),
        ],
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
          role: switch (state.uri.queryParameters['role']) {
            'owner' => OrderViewerRole.owner,
            'courier' => OrderViewerRole.courier,
            // Staff console view (FC10) — only granted when the signed-in
            // account actually has `orders.read`; anyone else deep-linking
            // `?role=staff` just gets the ordinary customer view.
            'staff' when _authBloc.state.can(Permissions.ordersRead) => OrderViewerRole.staff,
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
        // Finance summary (M13) — permission-gated (Founder Console RBAC).
        // Bounces anyone without `finance.read`; the founder uid stays as a
        // break-glass fallback until `/admins` seeding is verified on device.
        if (location == '/finance' &&
            !_authBloc.state.can(Permissions.financeRead) &&
            _authBloc.state.user?.uid != AppConfig.founderUid) {
          return '/home';
        }
        // Founder Console — any active staff member may enter the shell; each
        // section is gated again by Firestore rules + the Worker on write. A
        // non-staff account is bounced home; a staff member deep-linking to a
        // section they lack the permission for is bounced to the dashboard
        // (the menu already hides it — the URL is guarded too).
        if (location.startsWith('/console')) {
          final AdminProfile? admin = _authBloc.state.adminProfile;
          if (admin == null || !admin.isActive) return '/home';
          final section = consoleSectionForLocation(location);
          if (section?.requiredPerm != null &&
              !admin.can(section!.requiredPerm!)) {
            return '/console';
          }
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
