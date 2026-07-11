import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../settings/pages/settings_page.dart';
import '../widgets/common/empty_state.dart';

/// Placeholder courier app frame (Session 08) — deliveries + settings tabs
/// over an [IndexedStack], mirroring `OwnerHomeShell`. Deliveries tab is a
/// designed "coming soon" state; the real list/detail/advance-status flow
/// lands in Session 10 (`FILE_10_COURIER_SHELL.md`). Settings is shared as-is
/// so a courier can still switch language/theme and log out this session.
class CourierHomeShell extends StatefulWidget {
  const CourierHomeShell({super.key});

  @override
  State<CourierHomeShell> createState() => _CourierHomeShellState();
}

class _CourierHomeShellState extends State<CourierHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [_CourierDeliveriesPlaceholder(), SettingsPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping_rounded),
            label: l10n.navDeliveries,
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

class _CourierDeliveriesPlaceholder extends StatelessWidget {
  const _CourierDeliveriesPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDeliveries)),
      body: SafeArea(
        child: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: l10n.courierComingSoonTitle,
          message: l10n.courierComingSoonBody,
        ),
      ),
    );
  }
}
