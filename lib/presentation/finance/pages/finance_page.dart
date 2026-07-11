import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/finance/entities/finance_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/skeletons.dart';
import '../bloc/finance_bloc.dart';

/// The founder-only finance summary (M13) — six aggregate stat tiles over
/// the whole `/orders` collection. Reached only via the settings row that
/// `SettingsPage` hides behind `AppConfig.founderUid`; the router's redirect
/// bounces anyone else who lands on `/finance` directly. Calm monochrome by
/// design (north star: this is a ledger, not a marketing dashboard) — no
/// accent colour on the tiles, unlike `_DailySummaryStrip`'s green totals.
class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FinanceBloc>()..add(const FinanceStarted()),
      child: const _FinanceView(),
    );
  }
}

class _FinanceView extends StatelessWidget {
  const _FinanceView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.financeTitle)),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () {
            final bloc = context.read<FinanceBloc>();
            bloc.add(const FinanceRefreshRequested());
            return bloc.stream.firstWhere(
              (s) => s.status != FinanceStatus.loading,
            );
          },
          child: BlocBuilder<FinanceBloc, FinanceState>(
            builder: (context, state) => switch (state.status) {
              FinanceStatus.loading => ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: const [GridShimmer(count: 6, columns: 2, aspectRatio: 1.3)],
                ),
              FinanceStatus.error => ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    EmptyState(
                      icon: Icons.error_outline,
                      title: l10n.errorTitle,
                      message: l10n.financeErrorBody,
                      actionLabel: l10n.actionRetry,
                      onAction: () => context
                          .read<FinanceBloc>()
                          .add(const FinanceStarted()),
                    ),
                  ],
                ),
              FinanceStatus.loaded => _FinanceLoaded(summary: state.summary!),
            },
          ),
        ),
      ),
    );
  }
}

class _FinanceLoaded extends StatelessWidget {
  const _FinanceLoaded({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n.financeLedgerNote,
          style: text.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.3,
          children: [
            _FinanceTile(
              icon: Icons.receipt_long_outlined,
              label: l10n.financeTotalOrders,
              valueText: '${summary.totalOrders}',
            ),
            _FinanceTile(
              icon: Icons.check_circle_outline,
              label: l10n.financeDeliveredOrders,
              valueText: '${summary.deliveredOrders}',
            ),
            _FinanceTile(
              icon: Icons.cancel_outlined,
              label: l10n.financeCancelledOrders,
              valueText: '${summary.cancelledOrders}',
            ),
            _FinanceTile(
              icon: Icons.pie_chart_outline,
              label: l10n.financeTotalCommission,
              valueMinor: summary.commissionMinor,
            ),
            _FinanceTile(
              icon: Icons.local_shipping_outlined,
              label: l10n.financeDeliveryRevenue,
              valueMinor: summary.deliveryRevenueMinor,
            ),
            _FinanceTile(
              icon: Icons.account_balance_outlined,
              label: l10n.financeTotalPlatformRevenue,
              valueMinor: summary.platformRevenueMinor,
            ),
          ],
        ),
      ],
    );
  }
}

/// One tile — either a plain count ([valueText]) or a money amount
/// ([valueMinor], rendered via [PriceTag] but recoloured to onSurface so
/// the whole page stays monochrome).
class _FinanceTile extends StatelessWidget {
  const _FinanceTile({
    required this.icon,
    required this.label,
    this.valueText,
    this.valueMinor,
  }) : assert(
          (valueText == null) != (valueMinor == null),
          'exactly one of valueText/valueMinor must be set',
        );

  final IconData icon;
  final String label;
  final String? valueText;
  final int? valueMinor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final valueStyle =
        text.titleLarge?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: scheme.onSurface.withValues(alpha: 0.6)),
          const Spacer(),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          valueMinor != null
              ? PriceTag(valueMinor!, style: valueStyle)
              : Text(valueText!, style: valueStyle),
        ],
      ),
    );
  }
}
