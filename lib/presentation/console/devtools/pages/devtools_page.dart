import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/permissions.dart';
import '../../../../domain/devtools/entities/health_check_result.dart';
import '../../../../domain/devtools/entities/migration_status.dart';
import '../../../../firebase_options.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/empty_state.dart';
import '../bloc/devtools_bloc.dart';

/// The Founder Console devtools page (`/console/devtools`, FC15,
/// `system.tools`). Environment info + health checks are visible to anyone
/// with `system.tools`; the destructive re-seed tool additionally requires
/// the founder wildcard AND the current Firebase project to be on the dev
/// allowlist (`AppConfig.devProjectIds`) — a second, project-identity gate
/// so a re-seed can never fire against a real production project.
class DevToolsPage extends StatelessWidget {
  const DevToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final actorUid = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) => sl<DevToolsBloc>(param1: actorUid),
      child: const _DevToolsView(),
    );
  }
}

class _DevToolsView extends StatelessWidget {
  const _DevToolsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<DevToolsBloc, DevToolsState>(
      listenWhen: (a, b) => a.errorMessage != b.errorMessage && b.errorMessage != null,
      listener: (context, state) => AppSnackBar.error(context, l10n.devtoolsActionFailed),
      child: BlocBuilder<DevToolsBloc, DevToolsState>(
        buildWhen: (a, b) => a.status != b.status,
        builder: (context, state) {
          return switch (state.status) {
            DevToolsPageStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            DevToolsPageStatus.error => Center(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: l10n.errorTitle,
                  message: l10n.devtoolsLoadError,
                  actionLabel: l10n.actionRetry,
                  onAction: () =>
                      context.read<DevToolsBloc>().add(const DevToolsStarted()),
                ),
              ),
            DevToolsPageStatus.loaded => SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: const [
                    _EnvironmentCard(),
                    SizedBox(height: AppSpacing.md),
                    _HealthChecksCard(),
                    SizedBox(height: AppSpacing.md),
                    _SeedCard(),
                    SizedBox(height: AppSpacing.md),
                    _FakeDataCard(),
                    SizedBox(height: AppSpacing.md),
                    _CachesCard(),
                    SizedBox(height: AppSpacing.md),
                    _NotifyCard(),
                    SizedBox(height: AppSpacing.md),
                    _MigrationsCard(),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Environment
// ─────────────────────────────────────────────────────────────────────────

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.devtoolsEnvironmentTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _EnvRow(l10n.devtoolsEnvVersion, '${AppConfig.version}+${AppConfig.buildNumber}'),
          _EnvRow(l10n.devtoolsEnvProjectId, DefaultFirebaseOptions.currentPlatform.projectId),
          _EnvRow(l10n.devtoolsEnvWorkerUrl, AppConfig.workerBaseUrl),
          _EnvRow(
            l10n.devtoolsEnvWorkerConfigured,
            AppConfig.workerConfigured ? l10n.userDetailYes : l10n.userDetailNo,
          ),
          _EnvRow(l10n.devtoolsEnvFlavor, kDebugMode ? 'debug' : 'release'),
        ],
      ),
    );
  }
}

class _EnvRow extends StatelessWidget {
  const _EnvRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: text.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: SelectableText(value, style: text.bodyMedium)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Health checks
// ─────────────────────────────────────────────────────────────────────────

class _HealthChecksCard extends StatelessWidget {
  const _HealthChecksCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<DevToolsBloc, DevToolsState>(
      buildWhen: (a, b) =>
          a.healthResults != b.healthResults || a.isBusy('health') != b.isBusy('health'),
      builder: (context, state) {
        final busy = state.isBusy('health');
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.devtoolsHealthTitle,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => context
                            .read<DevToolsBloc>()
                            .add(const DevToolsHealthCheckRequested()),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.devtoolsHealthRunAll),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.healthResults.isEmpty)
                Text(l10n.devtoolsHealthEmpty)
              else
                for (final result in state.healthResults) _HealthRow(result: result),
            ],
          ),
        );
      },
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({required this.result});

  final HealthCheckResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            result.ok ? Icons.check_circle_outline : Icons.error_outline,
            color: result.ok ? AppColors.success : AppColors.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(_healthLabel(l10n, result.id))),
          Text('${result.latencyMs}ms', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

String _healthLabel(AppLocalizations l10n, String id) => switch (id) {
      'workerPing' => l10n.devtoolsHealthWorkerPing,
      'firestoreRead' => l10n.devtoolsHealthFirestoreRead,
      'configSanity' => l10n.devtoolsHealthConfigSanity,
      'taxonomyNonEmpty' => l10n.devtoolsHealthTaxonomy,
      'areasNonEmpty' => l10n.devtoolsHealthAreas,
      'activeDriverExists' => l10n.devtoolsHealthActiveDriver,
      _ => id,
    };

// ─────────────────────────────────────────────────────────────────────────
// Seed
// ─────────────────────────────────────────────────────────────────────────

class _SeedCard extends StatefulWidget {
  const _SeedCard();

  @override
  State<_SeedCard> createState() => _SeedCardState();
}

class _SeedCardState extends State<_SeedCard> {
  bool _rbac = true;
  bool _catalog = true;
  bool _customers = true;

  Future<void> _confirmAndRun(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.devtoolsSeedConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.devtoolsSeedConfirmBody),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(labelText: l10n.devtoolsSeedConfirmField),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: ctrl.text.trim() == 'SEED'
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DevToolsBloc>().add(
            DevToolsSeedRequested(rbac: _rbac, catalog: _catalog, customers: _customers),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allowed = context.select((AuthBloc b) =>
            b.state.adminProfile?.permissions.contains(Permissions.all) ?? false) &&
        AppConfig.devProjectIds.contains(DefaultFirebaseOptions.currentPlatform.projectId);
    if (!allowed) return const SizedBox.shrink();

    return BlocBuilder<DevToolsBloc, DevToolsState>(
      buildWhen: (a, b) => a.seedOk != b.seedOk || a.isBusy('seed') != b.isBusy('seed'),
      builder: (context, state) {
        final busy = state.isBusy('seed');
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.devtoolsSeedTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.devtoolsSeedWarning, style: Theme.of(context).textTheme.bodySmall),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _rbac,
                title: Text(l10n.devtoolsSeedRbac),
                onChanged: (v) => setState(() => _rbac = v ?? _rbac),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _catalog,
                title: Text(l10n.devtoolsSeedCatalog),
                onChanged: (v) => setState(() => _catalog = v ?? _catalog),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _customers,
                title: Text(l10n.devtoolsSeedCustomers),
                onChanged: (v) => setState(() => _customers = v ?? _customers),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  FilledButton(
                    onPressed: busy ? null : () => _confirmAndRun(context),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.devtoolsSeedAction),
                  ),
                  if (state.seedOk == true) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                  ],
                  if (state.seedOk == false) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Fake data
// ─────────────────────────────────────────────────────────────────────────

class _FakeDataCard extends StatefulWidget {
  const _FakeDataCard();

  @override
  State<_FakeDataCard> createState() => _FakeDataCardState();
}

class _FakeDataCardState extends State<_FakeDataCard> {
  int _customerCount = 5;
  int _orderCount = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<DevToolsBloc, DevToolsState>(
      builder: (context, state) {
        final customersBusy = state.isBusy('fakeCustomers');
        final ordersBusy = state.isBusy('fakeOrders');
        final cleanupBusy = state.isBusy('fakeCleanup');
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.devtoolsFakeTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: Text(l10n.devtoolsFakeCustomersLabel)),
                  SizedBox(
                    width: 72,
                    child: TextFormField(
                      initialValue: '$_customerCount',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _customerCount = int.tryParse(v) ?? _customerCount,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: customersBusy
                        ? null
                        : () => context
                            .read<DevToolsBloc>()
                            .add(DevToolsFakeCustomersRequested(_customerCount)),
                    child: customersBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.devtoolsFakeGenerate),
                  ),
                ],
              ),
              if (state.fakeCustomersCreated != null)
                Text(l10n.devtoolsFakeCustomersResult(state.fakeCustomersCreated!)),
              const Divider(height: AppSpacing.lg),
              if (state.shops.isEmpty)
                Text(l10n.devtoolsFakeNoShops)
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: state.selectedShopId,
                  decoration: InputDecoration(labelText: l10n.devtoolsFakeShopLabel),
                  items: [
                    for (final shop in state.shops)
                      DropdownMenuItem(value: shop.id, child: Text(shop.name)),
                  ],
                  onChanged: (v) {
                    if (v != null) context.read<DevToolsBloc>().add(DevToolsShopSelected(v));
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: Text(l10n.devtoolsFakeOrdersLabel)),
                    SizedBox(
                      width: 72,
                      child: TextFormField(
                        initialValue: '$_orderCount',
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _orderCount = int.tryParse(v) ?? _orderCount,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: ordersBusy
                          ? null
                          : () => context
                              .read<DevToolsBloc>()
                              .add(DevToolsFakeOrdersRequested(_orderCount)),
                      child: ordersBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.devtoolsFakeGenerate),
                    ),
                  ],
                ),
                if (state.fakeOrdersCreated != null)
                  Text(l10n.devtoolsFakeOrdersResult(state.fakeOrdersCreated!)),
              ],
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: cleanupBusy
                    ? null
                    : () =>
                        context.read<DevToolsBloc>().add(const DevToolsFakeCleanupRequested()),
                child: cleanupBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.devtoolsFakeCleanupAction),
              ),
              if (state.fakeCleanupCount != null)
                Text(l10n.devtoolsFakeCleanupResult(state.fakeCleanupCount!)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Caches / test notification
// ─────────────────────────────────────────────────────────────────────────

class _CachesCard extends StatelessWidget {
  const _CachesCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<DevToolsBloc, DevToolsState>(
      buildWhen: (a, b) =>
          a.cachesCleared != b.cachesCleared || a.isBusy('caches') != b.isBusy('caches'),
      builder: (context, state) {
        final busy = state.isBusy('caches');
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.devtoolsCachesTitle, style: Theme.of(context).textTheme.titleSmall),
                    if (state.cachesCleared) Text(l10n.devtoolsCachesCleared),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () =>
                        context.read<DevToolsBloc>().add(const DevToolsCachesClearRequested()),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.devtoolsCachesAction),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotifyCard extends StatelessWidget {
  const _NotifyCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<DevToolsBloc, DevToolsState>(
      buildWhen: (a, b) => a.notifySent != b.notifySent || a.isBusy('notify') != b.isBusy('notify'),
      builder: (context, state) {
        final busy = state.isBusy('notify');
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.devtoolsNotifyTitle, style: Theme.of(context).textTheme.titleSmall),
                    if (state.notifySent == true) Text(l10n.devtoolsNotifySent),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => context
                        .read<DevToolsBloc>()
                        .add(const DevToolsTestNotificationRequested()),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.devtoolsNotifyAction),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Migrations
// ─────────────────────────────────────────────────────────────────────────

class _MigrationsCard extends StatelessWidget {
  const _MigrationsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<DevToolsBloc, DevToolsState>(
      builder: (context, state) {
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.devtoolsMigrationsTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              for (final migration in state.migrations)
                _MigrationRow(migration: migration, busy: state.isBusy(migration.id)),
            ],
          ),
        );
      },
    );
  }
}

class _MigrationRow extends StatelessWidget {
  const _MigrationRow({required this.migration, required this.busy});

  final MigrationStatus migration;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        migration.applied ? Icons.check_circle_outline : Icons.radio_button_unchecked,
        color: migration.applied ? AppColors.success : null,
      ),
      title: Text(migration.id),
      subtitle: Text(migration.description),
      trailing: busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(
              onPressed: () =>
                  context.read<DevToolsBloc>().add(DevToolsMigrationRunRequested(migration.id)),
              child: Text(migration.applied ? l10n.devtoolsMigrationRerun : l10n.devtoolsMigrationRun),
            ),
    );
  }
}
