import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/auth/entities/user_role.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/users_bloc.dart';

/// The Founder Console user management list (`/console/users`, Session 6).
/// Search (exact email/phone, else a page-local name filter), role/status
/// chips, a paginated list, and a multi-select bulk suspend/unsuspend bar.
class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UsersBloc>()..add(const UsersStarted()),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          const _SearchAndFilterBar(),
          const Divider(height: 1, thickness: 1),
          BlocSelector<UsersBloc, UsersState, Set<String>>(
            selector: (s) => s.selected,
            builder: (context, selected) =>
                selected.isEmpty ? const SizedBox.shrink() : const _BulkActionBar(),
          ),
          Expanded(
            child: BlocConsumer<UsersBloc, UsersState>(
              listenWhen: (a, b) => a.bulkBusy && !b.bulkBusy,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.usersBulkSummary(state.bulkSucceeded, state.bulkTotal)),
                ));
              },
              buildWhen: (a, b) =>
                  a.status != b.status ||
                  a.visibleUsers != b.visibleUsers ||
                  a.hasMore != b.hasMore ||
                  a.loadingMore != b.loadingMore ||
                  a.selected != b.selected ||
                  a.searchResults != b.searchResults,
              builder: (context, state) => switch (state.status) {
                UsersStatus.loading => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ListShimmer(),
                  ),
                UsersStatus.error => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.usersErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () =>
                        context.read<UsersBloc>().add(const UsersRetryRequested()),
                  ),
                UsersStatus.loaded => state.visibleUsers.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: l10n.usersEmptyTitle,
                        message: l10n.usersEmptyBody,
                      )
                    : _UsersList(state: state),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Search + filters
// ─────────────────────────────────────────────────────────────────────────

class _SearchAndFilterBar extends StatefulWidget {
  const _SearchAndFilterBar();

  @override
  State<_SearchAndFilterBar> createState() => _SearchAndFilterBarState();
}

class _SearchAndFilterBarState extends State<_SearchAndFilterBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.usersSearchLabel,
                hintText: l10n.usersSearchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<UsersBloc>().add(const UsersSearchCleared());
                  },
                ),
                border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
              ),
              onSubmitted: (v) =>
                  context.read<UsersBloc>().add(UsersSearchSubmitted(v)),
            ),
          ),
          BlocSelector<UsersBloc, UsersState, (String?, String?)>(
            selector: (s) => (s.role, s.statusFilter),
            builder: (context, filters) {
              final (role, status) = filters;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _Dropdown(
                    label: l10n.usersFilterRole,
                    value: role,
                    allLabel: l10n.auditFilterAll,
                    items: {
                      UserRole.customer.wire: l10n.usersRoleCustomer,
                      UserRole.owner.wire: l10n.usersRoleOwner,
                      UserRole.courier.wire: l10n.usersRoleCourier,
                    },
                    onChanged: (v) => context
                        .read<UsersBloc>()
                        .add(UsersFilterChanged(role: v, status: status)),
                  ),
                  _Dropdown(
                    label: l10n.usersFilterStatus,
                    value: status,
                    allLabel: l10n.auditFilterAll,
                    items: {
                      'active': l10n.usersStatusActive,
                      'suspended': l10n.usersStatusSuspended,
                      'banned': l10n.usersStatusBanned,
                    },
                    onChanged: (v) => context
                        .read<UsersBloc>()
                        .add(UsersFilterChanged(role: role, status: v)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.allLabel,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String allLabel;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: text.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isDense: true,
              borderRadius: AppRadius.mdAll,
              hint: Text(allLabel, style: text.bodyMedium),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
                for (final e in items.entries)
                  DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bulk action bar
// ─────────────────────────────────────────────────────────────────────────

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final count = context.select((UsersBloc b) => b.state.selected.length);
    final busy = context.select((UsersBloc b) => b.state.bulkBusy);

    return Container(
      color: scheme.secondary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(l10n.usersSelectedCount(count)),
          const Spacer(),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else ...[
            TextButton(
              onPressed: () => _confirmBulk(context, 'suspended', l10n.usersBulkSuspend),
              child: Text(l10n.usersBulkSuspend),
            ),
            TextButton(
              onPressed: () => _confirmBulk(context, 'active', l10n.usersBulkUnsuspend),
              child: Text(l10n.usersBulkUnsuspend),
            ),
            TextButton(
              onPressed: () => context.read<UsersBloc>().add(const UsersSelectionCleared()),
              child: Text(l10n.auditFilterClear),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmBulk(BuildContext context, String status, String actionLabel) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UsersBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.usersBulkConfirmTitle),
        content: Text(l10n.usersBulkConfirmBody(actionLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(UsersBulkSetDisabledRequested(status));
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List + rows
// ─────────────────────────────────────────────────────────────────────────

class _UsersList extends StatelessWidget {
  const _UsersList({required this.state});

  final UsersState state;

  @override
  Widget build(BuildContext context) {
    final users = state.visibleUsers;
    final isSearch = state.searchResults != null;
    final showFooter = !isSearch && state.hasMore;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (!isSearch && n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
          context.read<UsersBloc>().add(const UsersLoadMoreRequested());
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: users.length + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i >= users.length) {
            return _LoadMoreFooter(loading: state.loadingMore);
          }
          final user = users[i];
          final selected = state.selected.contains(user.uid);
          return _UserRow(user: user, selected: selected);
        },
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : OutlinedButton(
                onPressed: () =>
                    context.read<UsersBloc>().add(const UsersLoadMoreRequested()),
                child: Text(l10n.auditLoadMore),
              ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.selected});

  final ManagedUser user;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/console/users/${user.uid}', extra: user),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) =>
                context.read<UsersBloc>().add(UserSelectionToggled(user.uid)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name.isEmpty ? '—' : user.name,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: user.deleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.deleted) ...[
                      const SizedBox(width: AppSpacing.xs),
                      StatusChip(label: l10n.usersDeletedLabel, tone: StatusTone.caution),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  style: text.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    StatusChip(label: _roleLabel(l10n, user.role)),
                    const SizedBox(width: AppSpacing.xs),
                    StatusChip(
                      label: _statusLabel(l10n, user.status),
                      tone: switch (user.status) {
                        'banned' => StatusTone.caution,
                        'suspended' => StatusTone.caution,
                        _ => StatusTone.positive,
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _roleLabel(AppLocalizations l10n, UserRole role) => switch (role) {
      UserRole.customer => l10n.usersRoleCustomer,
      UserRole.owner => l10n.usersRoleOwner,
      UserRole.courier => l10n.usersRoleCourier,
    };

String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
      'suspended' => l10n.usersStatusSuspended,
      'banned' => l10n.usersStatusBanned,
      _ => l10n.usersStatusActive,
    };
