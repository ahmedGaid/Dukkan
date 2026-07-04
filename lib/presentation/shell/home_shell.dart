import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../home/pages/customer_home_page.dart';
import '../widgets/common/coming_soon_page.dart';

/// The customer app frame: five bottom-nav destinations over an [IndexedStack]
/// so each tab keeps its scroll position and state. Home is the real C2a build;
/// the rest are designed "coming soon" until their sessions land (favorites &
/// orders → C4/P1, category browse → C2b, settings → later).
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

    final tabs = [
      const CustomerHomePage(),
      ComingSoonPage(
        icon: Icons.grid_view_outlined,
        title: l10n.categoriesComingSoonTitle,
        message: l10n.categoriesComingSoonBody,
      ),
      ComingSoonPage(
        icon: Icons.favorite_border_rounded,
        title: l10n.favoritesEmptyTitle,
        message: l10n.favoritesEmptyBody,
      ),
      ComingSoonPage(
        icon: Icons.receipt_long_outlined,
        title: l10n.ordersEmptyTitle,
        message: l10n.ordersEmptyBody,
      ),
      ComingSoonPage(
        icon: Icons.menu_rounded,
        title: l10n.moreComingSoonTitle,
        message: l10n.moreComingSoonBody,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: l10n.navCategories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: l10n.navFavorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: l10n.navOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_rounded),
            selectedIcon: const Icon(Icons.menu_open_rounded),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
