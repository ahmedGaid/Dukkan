import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/permissions.dart';
import '../../../../domain/audit/entities/audit_entry.dart';
import '../../../../domain/dashboard/entities/dashboard_summary.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../../widgets/mini_bar_chart.dart';
import '../../widgets/stat_tile.dart';
import '../bloc/dashboard_bloc.dart';

/// Crashlytics stays external (no in-app crash console); the dashboard just
/// surfaces the link as selectable text — `/_/` resolves to the default
/// Firebase project, so this needs no project id and no `url_launcher` dep.
const _crashlyticsUrl =
    'https://console.firebase.google.com/project/_/crashlytics';

/// The console home (FC5). Live platform stats, a 7-day order chart, a recent-
/// activity strip, and quick actions — every figure an aggregate query. The
/// nav shell supplies the app bar + title; this route is the body only.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final auth = context.read<AuthBloc>().state;
        return sl<DashboardBloc>()
          ..add(DashboardStarted(
            canReadUsers: auth.can(Permissions.usersRead),
            canReadAudit: auth.can(Permissions.auditlogsRead),
          ));
      },
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () {
          final bloc = context.read<DashboardBloc>();
          bloc.add(const DashboardRefreshRequested());
          return bloc.stream
              .firstWhere((s) => s.status != DashboardStatus.loading);
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) => switch (state.status) {
            DashboardStatus.loading => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: const [
                  GridShimmer(count: 8, columns: 2, aspectRatio: 1.25),
                  SizedBox(height: AppSpacing.md),
                  ListShimmer(count: 1, itemHeight: 148),
                ],
              ),
            DashboardStatus.error => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.dashboardErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () {
                      final auth = context.read<AuthBloc>().state;
                      context.read<DashboardBloc>().add(DashboardStarted(
                            canReadUsers: auth.can(Permissions.usersRead),
                            canReadAudit: auth.can(Permissions.auditlogsRead),
                          ));
                    },
                  ),
                ],
              ),
            DashboardStatus.loaded => _DashboardLoaded(state: state),
          },
        ),
      ),
    );
  }
}

class _DashboardLoaded extends StatelessWidget {
  const _DashboardLoaded({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final summary = state.summary!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _StatGrid(summary: summary),
        const SizedBox(height: AppSpacing.lg),

        _SectionHeader(title: l10n.dashboardChartTitle),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: MiniBarChart(data: summary.last7Days, locale: locale),
        ),

        if (state.canViewAudit) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            title: l10n.dashboardActivityTitle,
            actionLabel: l10n.dashboardViewAll,
            onAction: () => context.go('/console/audit'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActivityCard(entries: state.recentActivity!),

          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: l10n.dashboardQuickActionsTitle),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                avatar: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text(l10n.dashboardQuickAudit),
                onPressed: () => context.go('/console/audit'),
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(title: l10n.dashboardExternalTitle),
        const SizedBox(height: AppSpacing.sm),
        const _CrashlyticsCard(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stat grid
// ─────────────────────────────────────────────────────────────────────────

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tiles = <Widget>[
      StatTile(
        icon: Icons.receipt_long_outlined,
        label: l10n.dashboardOrdersToday,
        valueText: '${summary.ordersToday}',
      ),
      StatTile(
        icon: Icons.payments_outlined,
        label: l10n.dashboardRevenueToday,
        valueMinor: summary.revenueTodayMinor,
      ),
      StatTile(
        icon: Icons.pie_chart_outline,
        label: l10n.dashboardCommissionToday,
        valueMinor: summary.commissionTodayMinor,
      ),
      StatTile(
        icon: Icons.hourglass_bottom_outlined,
        label: l10n.dashboardOrdersWaiting,
        valueText: '${summary.ordersWaiting}',
      ),
      StatTile(
        icon: Icons.people_outline,
        label: l10n.dashboardTotalUsers,
        // '—' when the viewer can't read /users (see DashboardSummary).
        valueText: summary.totalUsers?.toString() ?? '—',
      ),
      StatTile(
        icon: Icons.storefront_outlined,
        label: l10n.dashboardTotalShops,
        valueText: '${summary.totalShops}',
      ),
      StatTile(
        icon: Icons.inventory_2_outlined,
        label: l10n.dashboardTotalProducts,
        valueText: '${summary.totalProducts}',
      ),
      StatTile(
        icon: Icons.delivery_dining_outlined,
        label: l10n.dashboardDriversOnline,
        valueText: '${summary.driversOnline}',
      ),
      StatTile(
        icon: Icons.pending_actions_outlined,
        label: l10n.dashboardPendingShops,
        valueText: '${summary.pendingShops}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.25,
          children: tiles,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Recent activity
// ─────────────────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entries});

  final List<AuditEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (entries.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l10n.dashboardActivityEmpty,
          style: text.bodyMedium
              ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _ActivityRow(entry: entries[i]),
            if (i != entries.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => context.go('/console/audit'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.12),
                borderRadius: AppRadius.smAll,
              ),
              alignment: Alignment.center,
              child: Icon(_targetIcon(entry.targetType),
                  size: 18, color: scheme.secondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.action.isEmpty ? '—' : entry.action,
                    style:
                        text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.targetType} · ${entry.targetId}',
                    style: text.bodySmall?.copyWith(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _relativeTime(l10n, locale, entry.createdAt),
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// External tools
// ─────────────────────────────────────────────────────────────────────────

class _CrashlyticsCard extends StatelessWidget {
  const _CrashlyticsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bug_report_outlined, color: muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dashboardCrashlyticsTitle,
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  l10n.dashboardCrashlyticsNote,
                  style: text.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  _crashlyticsUrl,
                  style: text.bodySmall?.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: text.titleMedium)),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

String _relativeTime(AppLocalizations l10n, String locale, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  final mins = diff.inMinutes;
  if (mins < 1) return l10n.auditTimeJustNow;
  if (mins < 60) return l10n.auditTimeMinutesAgo(mins);
  final hours = diff.inHours;
  if (hours < 24) return l10n.auditTimeHoursAgo(hours);
  final days = diff.inDays;
  if (days < 7) return l10n.auditTimeDaysAgo(days);
  return DateFormat.yMMMd(locale).format(dt);
}

IconData _targetIcon(String type) => switch (type) {
      'user' => Icons.person_outline,
      'shop' => Icons.storefront_outlined,
      'product' => Icons.inventory_2_outlined,
      'order' => Icons.receipt_long_outlined,
      'driver' => Icons.delivery_dining_outlined,
      'config' || 'settings' || 'flags' => Icons.settings_outlined,
      'taxonomy' => Icons.category_outlined,
      'area' => Icons.map_outlined,
      'media' || 'image' => Icons.image_outlined,
      'notification' => Icons.campaign_outlined,
      'admin' || 'role' => Icons.shield_outlined,
      _ => Icons.bolt_outlined,
    };
