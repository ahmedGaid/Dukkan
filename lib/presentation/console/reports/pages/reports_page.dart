import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/dashboard/entities/daily_order_count.dart';
import '../../../../domain/reports/entities/distribution_entry.dart';
import '../../../../domain/reports/entities/report_period_totals.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../../util/export_action.dart';
import '../../widgets/mini_bar_chart.dart';
import '../bloc/reports_bloc.dart';

/// `/console/reports` (FC17, perm `reports.export`). Period picker (7/30/90)
/// drives a per-day series (three reused `MiniBarChart`s + a totals row), the
/// «النمو» growth counts, and the «التوزيع» distribution rows — every table
/// exportable via [exportCsv].
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportsBloc>()..add(const ReportsStarted()),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state.status == ReportsStatus.error && state.totals == null) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.errorTitle,
              message: l10n.reportsErrorBody,
              actionLabel: l10n.actionRetry,
              onAction: () => context.read<ReportsBloc>().add(const ReportsRetryRequested()),
            );
          }
          if (state.totals == null) {
            return const Padding(padding: EdgeInsets.all(AppSpacing.md), child: ListShimmer());
          }
          return _ReportsBody(state: state);
        },
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final locale = isArabic ? 'ar' : 'en';
    final totals = state.totals!;
    final busy = state.status == ReportsStatus.loading;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 7, label: Text(l10n.reportsPeriod7)),
                  ButtonSegment(value: 30, label: Text(l10n.reportsPeriod30)),
                  ButtonSegment(value: 90, label: Text(l10n.reportsPeriod90)),
                ],
                selected: {state.periodDays},
                onSelectionChanged: busy
                    ? null
                    : (v) => context.read<ReportsBloc>().add(ReportsPeriodChanged(v.first)),
              ),
            ),
            if (busy) ...[
              const SizedBox(width: AppSpacing.sm),
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _TotalsRow(totals: totals, locale: locale),
        const SizedBox(height: AppSpacing.md),
        _ChartCard(
          title: l10n.reportsChartOrders,
          data: [for (final p in totals.daily) DailyOrderCount(day: p.day, count: p.ordersCount)],
          locale: locale,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChartCard(
          title: l10n.reportsChartRevenue,
          data: [
            for (final p in totals.daily)
              DailyOrderCount(day: p.day, count: (p.revenueMinor / 100).round()),
          ],
          locale: locale,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChartCard(
          title: l10n.reportsChartCommission,
          data: [
            for (final p in totals.daily)
              DailyOrderCount(day: p.day, count: (p.commissionMinor / 100).round()),
          ],
          locale: locale,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => exportCsv(
              context,
              filenameBase: 'reports_daily_${state.periodDays}d',
              auditTargetType: 'order',
              rows: [
                [l10n.reportsColDay, l10n.reportsChartOrders, l10n.reportsChartRevenue, l10n.reportsChartCommission],
                for (final p in totals.daily)
                  [
                    '${p.day.year}-${p.day.month.toString().padLeft(2, '0')}-${p.day.day.toString().padLeft(2, '0')}',
                    '${p.ordersCount}',
                    Money.format(p.revenueMinor, languageCode: locale),
                    Money.format(p.commissionMinor, languageCode: locale),
                  ],
              ],
            ),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l10n.reportsExportDaily),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.reportsGrowthTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.reportsGrowthCaption,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _StatTile(label: l10n.reportsNewUsers, value: '${totals.newUsers}')),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatTile(label: l10n.reportsNewShops, value: '${totals.newShops}')),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DistributionSection(
          title: l10n.reportsDistributionByArea,
          entries: state.ordersByArea,
          isArabic: isArabic,
          onExport: () => exportCsv(
            context,
            filenameBase: 'reports_orders_by_area',
            auditTargetType: 'area',
            rows: [
              [l10n.consoleNavGeo, l10n.reportsColCount],
              for (final e in state.ordersByArea) [isArabic ? e.labelAr : e.labelEn, '${e.count}'],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DistributionSection(
          title: l10n.reportsDistributionByCategory,
          entries: state.productsByCategory,
          isArabic: isArabic,
          onExport: () => exportCsv(
            context,
            filenameBase: 'reports_products_by_category',
            auditTargetType: 'product',
            rows: [
              [l10n.consoleNavTaxonomy, l10n.reportsColCount],
              for (final e in state.productsByCategory)
                [isArabic ? e.labelAr : e.labelEn, '${e.count}'],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DistributionSection(
          title: l10n.reportsDistributionByShop,
          entries: state.ordersByShop,
          isArabic: isArabic,
          onExport: () => exportCsv(
            context,
            filenameBase: 'reports_orders_by_shop',
            auditTargetType: 'shop',
            rows: [
              [l10n.consoleNavShops, l10n.reportsColCount],
              for (final e in state.ordersByShop) [isArabic ? e.labelAr : e.labelEn, '${e.count}'],
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.totals, required this.locale});

  final ReportPeriodTotals totals;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: _StatTile(label: l10n.reportsChartOrders, value: '${totals.totalOrders}')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: l10n.reportsChartRevenue,
            value: Money.format(totals.totalRevenueMinor, languageCode: locale),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: l10n.reportsChartCommission,
            value: Money.format(totals.totalCommissionMinor, languageCode: locale),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: text.bodySmall?.copyWith(color: muted)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.data, required this.locale});

  final String title;
  final List<DailyOrderCount> data;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          MiniBarChart(data: data, locale: locale),
        ],
      ),
    );
  }
}

class _DistributionSection extends StatelessWidget {
  const _DistributionSection({
    required this.title,
    required this.entries,
    required this.isArabic,
    required this.onExport,
  });

  final String title;
  final List<DistributionEntry> entries;
  final bool isArabic;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final max = entries.isEmpty ? 0 : entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            IconButton(
              icon: const Icon(Icons.download_outlined, size: 18),
              tooltip: l10n.reportsExportSection,
              onPressed: entries.isEmpty ? null : onExport,
            ),
          ],
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              l10n.reportsDistributionEmpty,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          )
        else
          for (final e in entries)
            _DistributionRow(
              label: isArabic ? e.labelAr : e.labelEn,
              count: e.count,
              max: max,
            ),
      ],
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.label, required this.count, required this.max});

  final String label;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = max == 0 ? 0.0 : count / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 10,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 32,
            child: Text('$count', textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
