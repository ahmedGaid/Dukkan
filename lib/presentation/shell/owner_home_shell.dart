import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injector.dart';
import '../../domain/shop/entities/shop.dart';
import '../../domain/shop/usecases/get_shop_by_owner.dart';
import '../../l10n/app_localizations.dart';
import '../auth/bloc/auth_bloc.dart';
import '../catalog/pages/catalog_manager_page.dart';
import '../orders/pages/order_desk_page.dart';
import '../settings/pages/settings_page.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/skeletons.dart';

enum _LoadStatus { loading, error, loaded }

/// The owner app frame: three bottom-nav destinations — catalog manager (S2),
/// order desk (S3), and settings (P2a) — over an [IndexedStack] so each tab
/// keeps its state (mirrors the customer `HomeShell`). Needs the owner's own
/// shop id up front to hand to the order-desk tab; the catalog tab still
/// resolves its own shop internally (unchanged from S2).
class OwnerHomeShell extends StatefulWidget {
  const OwnerHomeShell({super.key});

  @override
  State<OwnerHomeShell> createState() => _OwnerHomeShellState();
}

class _OwnerHomeShellState extends State<OwnerHomeShell> {
  int _index = 0;
  _LoadStatus _status = _LoadStatus.loading;
  Shop? _shop;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    setState(() => _status = _LoadStatus.loading);
    try {
      final shop = await sl<GetShopByOwner>()(user.uid);
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _status = _LoadStatus.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _LoadStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = _shop;

    return switch (_status) {
      _LoadStatus.loading => const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ListShimmer(),
            ),
          ),
        ),
      _LoadStatus.error => Scaffold(
          body: SafeArea(
            child: EmptyState(
              icon: Icons.wifi_off_rounded,
              title: l10n.errorTitle,
              message: l10n.catalogErrorBody,
              actionLabel: l10n.actionRetry,
              onAction: _loadShop,
            ),
          ),
        ),
      _LoadStatus.loaded => Scaffold(
          body: IndexedStack(
            index: _index,
            children: [
              const CatalogManagerPage(),
              OrderDeskPage(shopId: shop!.id),
              const SettingsPage(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.storefront_outlined),
                selectedIcon: const Icon(Icons.storefront_rounded),
                label: l10n.navCatalog,
              ),
              NavigationDestination(
                icon: const Icon(Icons.receipt_long_outlined),
                selectedIcon: const Icon(Icons.receipt_long_rounded),
                label: l10n.navOrderDesk,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_rounded),
                selectedIcon: const Icon(Icons.menu_open_rounded),
                label: l10n.navMore,
              ),
            ],
          ),
        ),
    };
  }
}
