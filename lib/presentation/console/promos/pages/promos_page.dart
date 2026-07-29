import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/banners_board_bloc.dart';
import '../bloc/coupons_board_bloc.dart';
import 'banners_tab.dart';
import 'coupons_tab.dart';

/// `/console/promos` (FC16) — one section, two tabs: coupons + banners.
/// Featured shops/products management stays on the shop/product boards
/// (Sessions 7/8); this page only links there.
class PromosPage extends StatelessWidget {
  const PromosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => sl<CouponsBoardBloc>()..add(const CouponsBoardStarted()),
          ),
          BlocProvider(
            create: (_) => sl<BannersBoardBloc>()..add(const BannersBoardStarted()),
          ),
        ],
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: l10n.promosTabCoupons),
                  Tab(text: l10n.promosTabBanners),
                ],
              ),
              const Divider(height: 1, thickness: 1),
              const Expanded(
                child: TabBarView(
                  children: [CouponsTab(), BannersTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
