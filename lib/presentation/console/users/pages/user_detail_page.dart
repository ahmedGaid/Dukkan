import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/money.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/admin_profile.dart';
import '../../../../domain/admin/entities/auth_lookup.dart';
import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/admin/entities/permissions.dart';
import '../../../../domain/admin/entities/staff_role.dart';
import '../../../../domain/audit/entities/audit_filter.dart';
import '../../../../domain/audit/usecases/get_audit_entries.dart';
import '../../../../domain/auth/entities/user_role.dart';
import '../../../../domain/order/entities/order.dart';
import '../../../../domain/order/usecases/watch_customer_orders.dart';
import '../../../../domain/shop/entities/shop.dart';
import '../../../../domain/shop/usecases/get_shop_by_owner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/user_detail_bloc.dart';

/// The Founder Console user detail page (`/console/users/:uid`, Session 6).
/// Always opened from the list row tap (`extra: ManagedUser`) — there is no
/// get-by-uid read on `AdminUsersRepository`, only exact email/phone, so a
/// bare deep link with no seed shows a "go back" empty state rather than a
/// silent crash.
class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key, required this.seed});

  final ManagedUser? seed;

  @override
  Widget build(BuildContext context) {
    final seed = this.seed;
    if (seed == null) {
      final l10n = AppLocalizations.of(context)!;
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.userDetailMissingSeed, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => context.go('/console/users'),
                  child: Text(l10n.userDetailBackToList),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<UserDetailBloc>(param1: seed)..add(const UserDetailStarted()),
      child: const _UserDetailView(),
    );
  }
}

class _UserDetailView extends StatelessWidget {
  const _UserDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<UserDetailBloc, UserDetailState>(
      listenWhen: (a, b) => a.actionBusy && !b.actionBusy,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(SnackBar(
          content: Text(state.actionError == null
              ? l10n.userDetailActionOk
              : l10n.userDetailActionFailed),
        ));
      },
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _Header(),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: BlocBuilder<UserDetailBloc, UserDetailState>(
                builder: (context, state) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _ActionsCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _AuthCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _StaffCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _ShopsSection(uid: state.user.uid),
                      const SizedBox(height: AppSpacing.md),
                      _OrdersSection(uid: state.user.uid),
                      const SizedBox(height: AppSpacing.md),
                      _AuditHistorySection(uid: state.user.uid),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final user = context.select((UserDetailBloc b) => b.state.user);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/console/users'),
          ),
          Expanded(
            child: Text(
              user.name.isEmpty ? user.email : user.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (context.select((UserDetailBloc b) => b.state.actionBusy))
            const Padding(
              padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Profile card
// ─────────────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});

  final UserDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = state.user;
    final locale = Localizations.localeOf(context).languageCode;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.userDetailProfileTitle,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              StatusChip(label: _roleLabel(l10n, user.role)),
              const SizedBox(width: AppSpacing.xs),
              StatusChip(
                label: _statusLabel(l10n, user.status),
                tone: user.status == 'active' ? StatusTone.positive : StatusTone.caution,
              ),
              if (user.deleted) ...[
                const SizedBox(width: AppSpacing.xs),
                StatusChip(label: l10n.usersDeletedLabel, tone: StatusTone.caution),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(label: l10n.auditDetailTarget, value: user.uid),
          _Field(label: l10n.userDetailEmail, value: user.email),
          _Field(label: l10n.userDetailPhone, value: user.phone ?? '—'),
          _Field(
            label: l10n.userDetailMemberSince,
            value: user.createdAt == null
                ? l10n.userDetailUnknown
                : DateFormat.yMMMd(locale).format(user.createdAt!),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

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
            width: 120,
            child: Text(label,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: SelectableText(value, style: text.bodyMedium)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Actions card
// ─────────────────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.state});

  final UserDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = state.user;
    final busy = state.actionBusy;
    final bloc = context.read<UserDetailBloc>();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.userDetailActionsTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (user.status != 'suspended')
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _confirm(
                            context,
                            l10n.userDetailConfirmSuspend,
                            () => bloc.add(UserDetailSetDisabledRequested(
                                uid: user.uid, status: 'suspended')),
                          ),
                  child: Text(l10n.usersBulkSuspend),
                ),
              if (user.status != 'banned')
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _confirm(
                            context,
                            l10n.userDetailConfirmBan,
                            () => bloc.add(UserDetailSetDisabledRequested(
                                uid: user.uid, status: 'banned')),
                          ),
                  child: Text(l10n.userDetailBan),
                ),
              if (user.status != 'active')
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => bloc.add(
                          UserDetailSetDisabledRequested(uid: user.uid, status: 'active')),
                  child: Text(l10n.usersBulkUnsuspend),
                ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => _confirm(
                          context,
                          l10n.userDetailConfirmPasswordReset,
                          () => bloc.add(const UserDetailSendPasswordResetRequested()),
                        ),
                child: Text(l10n.userDetailSendPasswordReset),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => _changeEmailDialog(context, bloc, user),
                child: Text(l10n.userDetailChangeEmail),
              ),
              OutlinedButton(
                onPressed: busy ? null : () => _personaRoleDialog(context, bloc, user),
                child: Text(l10n.userDetailSetPersonaRole),
              ),
              if (!user.deleted)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _confirm(
                            context,
                            l10n.userDetailConfirmSoftDelete,
                            () => bloc.add(UserDetailSoftDeleteRequested(user.uid)),
                          ),
                  child: Text(l10n.userDetailSoftDelete),
                )
              else
                FilledButton(
                  onPressed:
                      busy ? null : () => bloc.add(UserDetailRestoreRequested(user.uid)),
                  child: Text(l10n.userDetailRestore),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, String body, VoidCallback onConfirm) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  Future<void> _changeEmailDialog(
      BuildContext context, UserDetailBloc bloc, ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: user.email);
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.userDetailChangeEmail),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l10n.userDetailEmail),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (email != null && email.isNotEmpty && email != user.email) {
      bloc.add(UserDetailChangeEmailRequested(uid: user.uid, email: email));
    }
  }

  Future<void> _personaRoleDialog(
      BuildContext context, UserDetailBloc bloc, ManagedUser user) async {
    final l10n = AppLocalizations.of(context)!;
    var selected = user.role;
    final result = await showDialog<UserRole>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.userDetailSetPersonaRole),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in UserRole.values)
                ListTile(
                  leading: Icon(
                    selected == role
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(_roleLabel(l10n, role)),
                  onTap: () => setState(() => selected = role),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(selected),
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      ),
    );
    if (result != null && result != user.role) {
      bloc.add(UserDetailSetPersonaRoleRequested(uid: user.uid, role: result.wire));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Auth card
// ─────────────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.state});

  final UserDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final AuthLookup? lookup = state.authLookup;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.userDetailAuthTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (state.status == UserDetailStatus.loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ))
          else if (lookup == null)
            Text(l10n.userDetailUnknown)
          else ...[
            _Field(
                label: l10n.userDetailEmailVerified,
                value: lookup.emailVerified ? l10n.userDetailYes : l10n.userDetailNo),
            _Field(
                label: l10n.userDetailAuthDisabled,
                value: lookup.disabled ? l10n.userDetailYes : l10n.userDetailNo),
            _Field(
              label: l10n.userDetailLastLogin,
              value: lookup.lastLoginAt == null
                  ? l10n.userDetailUnknown
                  : DateFormat.yMMMd(locale).add_Hm().format(lookup.lastLoginAt!),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Staff card
// ─────────────────────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.state});

  final UserDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final AdminProfile? staff = state.staffProfile;
    final canManage = context.select((AuthBloc b) => b.state.can(Permissions.adminsManage));

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.userDetailStaffTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (staff == null)
            Text(l10n.userDetailNotStaff)
          else ...[
            _Field(label: l10n.userDetailStaffRole, value: _staffRoleLabel(l10n, staff.role)),
            _Field(
              label: l10n.userDetailStaffPermissions,
              value: staff.permissions.isEmpty ? '—' : staff.permissions.join(', '),
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: () => _staffEditorDialog(context, state),
                  child: Text(staff == null
                      ? l10n.userDetailMakeStaff
                      : l10n.userDetailEditStaff),
                ),
                if (staff != null)
                  OutlinedButton(
                    onPressed: () => context
                        .read<UserDetailBloc>()
                        .add(UserDetailRemoveAdminRequested(state.user.uid)),
                    child: Text(l10n.userDetailRemoveStaff),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _staffEditorDialog(BuildContext context, UserDetailState state) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<UserDetailBloc>();
    var role = state.staffProfile?.role ?? StaffRole.support;
    final extras = <String>{...(state.staffProfile?.permissions ?? const {})};

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.userDetailEditStaff),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<StaffRole>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: l10n.userDetailStaffRole),
                    items: [
                      for (final r in StaffRole.values)
                        DropdownMenuItem(value: r, child: Text(_staffRoleLabel(l10n, r))),
                    ],
                    onChanged: (v) => setState(() => role = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.userDetailExtraPermissionsHint,
                      style: Theme.of(context).textTheme.bodySmall),
                  for (final perm in Permissions.values)
                    CheckboxListTile(
                      dense: true,
                      value: extras.contains(perm),
                      title: Text(perm),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          extras.add(perm);
                        } else {
                          extras.remove(perm);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      bloc.add(UserDetailSetAdminRequested(
        uid: state.user.uid,
        role: role.wire,
        extraPermissions: extras.toList(),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shops / Orders / Audit sections
// ─────────────────────────────────────────────────────────────────────────

class _ShopsSection extends StatelessWidget {
  const _ShopsSection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Shop?>(
      future: sl<GetShopByOwner>()(uid),
      builder: (context, snapshot) {
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.userDetailShopsTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (snapshot.data == null)
                Text(l10n.userDetailNoShop)
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(snapshot.data!.name),
                  trailing: StatusChip(
                    label: snapshot.data!.isOpen ? l10n.shopOpen : l10n.shopClosed,
                    tone: snapshot.data!.isOpen ? StatusTone.positive : StatusTone.neutral,
                  ),
                  onTap: () => context.push('/shop/${snapshot.data!.id}'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return StreamBuilder<List<Order>>(
      stream: sl<WatchCustomerOrders>()(uid),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? const <Order>[];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.userDetailOrdersTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (!snapshot.hasData)
                const LinearProgressIndicator()
              else if (orders.isEmpty)
                Text(l10n.userDetailNoOrders)
              else
                for (final order in orders.take(10))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(Money.format(order.totalMinor, languageCode: locale)),
                    subtitle: Text(order.status.name),
                    trailing: Text(DateFormat.MMMd(locale).format(order.createdAt)),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _AuditHistorySection extends StatelessWidget {
  const _AuditHistorySection({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return FutureBuilder(
      future: sl<GetAuditEntries>()(
        filter: AuditFilter(targetType: 'user', targetId: uid),
      ),
      builder: (context, snapshot) {
        final entries = snapshot.data?.entries ?? const [];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.userDetailAuditTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (entries.isEmpty)
                Text(l10n.auditEmptyTitle)
              else
                for (final entry in entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.bolt_outlined),
                    title: Text(entry.action),
                    trailing: Text(DateFormat.yMMMd(locale).add_Hm().format(entry.createdAt)),
                  ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────

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

String _staffRoleLabel(AppLocalizations l10n, StaffRole role) => switch (role) {
      StaffRole.founder => l10n.roleFounder,
      StaffRole.admin => l10n.roleAdmin,
      StaffRole.moderator => l10n.roleModerator,
      StaffRole.support => l10n.roleSupport,
    };
