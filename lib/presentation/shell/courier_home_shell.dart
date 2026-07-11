import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import '../driver/pages/deliveries_page.dart';
import '../settings/pages/settings_page.dart';

/// The courier app frame — deliveries + settings tabs over an [IndexedStack],
/// mirroring `OwnerHomeShell`. Deliveries was a designed "coming soon"
/// placeholder through Session 08; the real list/detail/advance-status flow
/// landed in Session 10 (`FILE_10_COURIER_SHELL.md`). Settings is shared as-is
/// so a courier can switch language/theme and log out.
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
    final driverUid = context.read<AuthBloc>().state.user!.uid;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [DeliveriesPage(driverUid: driverUid), const SettingsPage()],
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
