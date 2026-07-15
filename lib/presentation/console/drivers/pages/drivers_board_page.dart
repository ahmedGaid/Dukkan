import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/areas/entities/area.dart';
import '../../../../domain/driver/entities/driver.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/drivers_board_bloc.dart';

/// The Founder Console driver board (`/console/drivers`, FC11). Filter chips
/// over the already-loaded list — the driver pool is small, no pagination or
/// search (mirrors `ShopsBoardBloc`'s reasoning, but even lighter). Row tap
/// opens the detail page with the tapped [Driver] as `extra`.
class DriversBoardPage extends StatelessWidget {
  const DriversBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DriversBoardBloc>()..add(const DriversBoardStarted()),
      child: const _DriversBoardView(),
    );
  }
}

class _DriversBoardView extends StatelessWidget {
  const _DriversBoardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const _FilterBar(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: BlocBuilder<DriversBoardBloc, DriversBoardState>(
              builder: (context, state) => switch (state.status) {
                DriversBoardStatus.loading => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ListShimmer(),
                  ),
                DriversBoardStatus.error => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.driversBoardErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () =>
                        context.read<DriversBoardBloc>().add(const DriversBoardRetryRequested()),
                  ),
                DriversBoardStatus.loaded => state.filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.delivery_dining_outlined,
                        title: l10n.driversBoardEmptyTitle,
                        message: l10n.driversBoardEmptyBody,
                      )
                    : _DriversList(state: state),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filters
// ─────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: BlocSelector<DriversBoardBloc, DriversBoardState, DriversBoardFilter?>(
        selector: (s) => s.filter,
        builder: (context, filter) => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FilterChip(
              label: l10n.shopsFilterAll,
              selected: filter == null,
              onTap: () =>
                  context.read<DriversBoardBloc>().add(const DriversBoardFilterChanged(null)),
            ),
            _FilterChip(
              label: l10n.driversFilterPendingActivation,
              selected: filter == DriversBoardFilter.pendingActivation,
              onTap: () => context.read<DriversBoardBloc>().add(
                    const DriversBoardFilterChanged(DriversBoardFilter.pendingActivation),
                  ),
            ),
            _FilterChip(
              label: l10n.driversFilterActive,
              selected: filter == DriversBoardFilter.active,
              onTap: () => context
                  .read<DriversBoardBloc>()
                  .add(const DriversBoardFilterChanged(DriversBoardFilter.active)),
            ),
            _FilterChip(
              label: l10n.driversFilterSuspended,
              selected: filter == DriversBoardFilter.suspended,
              onTap: () => context
                  .read<DriversBoardBloc>()
                  .add(const DriversBoardFilterChanged(DriversBoardFilter.suspended)),
            ),
            _FilterChip(
              label: l10n.driversFilterOnline,
              selected: filter == DriversBoardFilter.online,
              onTap: () => context
                  .read<DriversBoardBloc>()
                  .add(const DriversBoardFilterChanged(DriversBoardFilter.online)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List + rows
// ─────────────────────────────────────────────────────────────────────────

class _DriversList extends StatelessWidget {
  const _DriversList({required this.state});

  final DriversBoardState state;

  @override
  Widget build(BuildContext context) {
    final drivers = state.filtered;
    final areaNames = {for (final a in state.areas) a.id: a};

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: drivers.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _DriverRow(driver: drivers[i], areaNames: areaNames),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({required this.driver, required this.areaNames});

  final Driver driver;
  final Map<String, Area> areaNames;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/console/drivers/${driver.uid}', extra: driver),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnlineDot(isOnline: driver.isOnline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  driver.name,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  driver.phone ?? '—',
                  style: text.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(
                      label: driver.isSuspended
                          ? l10n.driversFilterSuspended
                          : l10n.driversFilterActive,
                      tone: driver.isSuspended ? StatusTone.caution : StatusTone.positive,
                    ),
                    if (driver.isVerified)
                      StatusChip(label: l10n.driverDetailVerifiedBadge, tone: StatusTone.neutral),
                    for (final id in driver.areaIds)
                      if (areaNames[id] case final area?)
                        StatusChip(label: isArabic ? area.nameAr : area.nameEn),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${driver.activeOrdersCount}/${driver.maxActiveOrders}',
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOnline ? scheme.primary : scheme.outlineVariant,
        ),
      ),
    );
  }
}
