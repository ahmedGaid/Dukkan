import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../domain/admin/entities/permissions.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import '../favorites/pages/favorites_page.dart';
import '../home/pages/customer_home_page.dart';
import '../orders/pages/orders_page.dart';
import '../settings/pages/settings_page.dart';
import '../widgets/common/coming_soon_page.dart';

/// The customer app frame: five bottom-nav destinations over an [IndexedStack]
/// so each tab keeps its scroll position and state. Home (C2a), Orders (C4),
/// Favorites (P1), and Settings (P2a) are the real builds; only category
/// browse stays a designed "coming soon" until its session lands (C2b).
///
/// Founder/staff accounts get two more destinations, Console and Finance —
/// same visibility gate as the rows `SettingsPage` already hides them behind.
/// Those two routes live outside this shell's `IndexedStack` (Console is a
/// go_router `ShellRoute` with its own nested pages), so tapping them
/// navigates away via `context.go` instead of switching the stack index.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final showConsole = authState.adminProfile?.isActive == true;
    final showFinance = authState.can(Permissions.financeRead) ||
        authState.user?.uid == AppConfig.founderUid;

    final tabs = [
      const CustomerHomePage(),
      ComingSoonPage(
        icon: Icons.grid_view_outlined,
        title: l10n.categoriesComingSoonTitle,
        message: l10n.categoriesComingSoonBody,
      ),
      const FavoritesPage(),
      const OrdersPage(),
      const SettingsPage(),
    ];

    // "More" stays the last destination, as in the original 5-tab bar — any
    // founder-only entries are inserted before it, not appended after.
    final entries = [
      _NavEntry.tab(
        tabIndex: 0,
        dest: NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.navHome,
        ),
      ),
      _NavEntry.tab(
        tabIndex: 1,
        dest: NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view_rounded),
          label: l10n.navCategories,
        ),
      ),
      _NavEntry.tab(
        tabIndex: 2,
        dest: NavigationDestination(
          icon: const Icon(Icons.favorite_border_rounded),
          selectedIcon: const Icon(Icons.favorite_rounded),
          label: l10n.navFavorites,
        ),
      ),
      _NavEntry.tab(
        tabIndex: 3,
        dest: NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long_rounded),
          label: l10n.navOrders,
        ),
      ),
      if (showConsole)
        _NavEntry.route(
          route: '/console',
          dest: NavigationDestination(
            icon: const Icon(Icons.dashboard_customize_outlined),
            selectedIcon: const Icon(Icons.dashboard_customize_rounded),
            label: l10n.settingsConsoleRow,
          ),
        ),
      if (showFinance)
        _NavEntry.route(
          route: '/finance',
          dest: NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            selectedIcon: const Icon(Icons.account_balance_rounded),
            label: l10n.financeTitle,
          ),
        ),
      _NavEntry.tab(
        tabIndex: 4,
        dest: NavigationDestination(
          icon: const Icon(Icons.menu_rounded),
          selectedIcon: const Icon(Icons.menu_open_rounded),
          label: l10n.navMore,
        ),
      ),
    ];

    final selectedEntry = entries.indexWhere((e) => e.tabIndex == _index);

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedEntry < 0 ? 0 : selectedEntry,
        labelBehavior: showConsole || showFinance
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          final entry = entries[i];
          if (entry.tabIndex != null) {
            setState(() => _index = entry.tabIndex!);
          } else {
            // push, not go: go() is peer navigation and collapses this
            // shell out of the stack, so system back has nothing left to
            // pop and exits the app instead of returning here.
            context.push(entry.route!);
          }
        },
        destinations: [for (final e in entries) e.dest],
      ),
    );
  }
}

/// One bottom-nav slot: either a page inside this shell's [IndexedStack]
/// ([tabIndex]) or an external route reached via `go_router` ([route]).
class _NavEntry {
  const _NavEntry.tab({required this.dest, required int tabIndex})
      : tabIndex = tabIndex,
        route = null;
  const _NavEntry.route({required this.dest, required String route})
      : tabIndex = null,
        route = route;

  final NavigationDestination dest;
  final int? tabIndex;
  final String? route;
}
