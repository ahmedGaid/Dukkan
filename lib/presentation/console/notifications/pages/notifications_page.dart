import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/notifications_admin/entities/notification_history_entry.dart';
import '../../../../domain/notifications_admin/entities/notification_stats.dart';
import '../../../../domain/notifications_admin/entities/notification_template.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/notifications_bloc.dart';

const _bodyMaxLen = 1000;

/// The Founder Console notification center (`/console/notifications`, FC13).
/// Two tabs: إرسال (compose + send) and السجل (history + resend). One
/// BLoC drives both — see `NotificationsBloc` doc for the load/send/refresh
/// contract.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsBloc>(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        top: false,
        child: BlocConsumer<NotificationsBloc, NotificationsState>(
          listenWhen: (a, b) => a.sendBusy && !b.sendBusy,
          listener: (context, state) {
            if (state.sendError != null) {
              AppSnackBar.error(context, l10n.notificationsSendFailed);
            } else {
              AppSnackBar.success(context, l10n.notificationsSendOk);
            }
          },
          builder: (context, state) => switch (state.status) {
            NotificationsStatus.loading => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: ListShimmer(count: 4, itemHeight: 96),
              ),
            NotificationsStatus.error => Center(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: l10n.errorTitle,
                  message: l10n.notificationsLoadError,
                  actionLabel: l10n.actionRetry,
                  onAction: () => context
                      .read<NotificationsBloc>()
                      .add(const NotificationsRetryRequested()),
                ),
              ),
            NotificationsStatus.loaded => Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: l10n.notificationsTabSend),
                      Tab(text: l10n.notificationsTabHistory),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [_ComposeTab(), _HistoryTab()],
                    ),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// إرسال — compose
// ─────────────────────────────────────────────────────────────────────────

enum _Audience { customers, owners, couriers, all, specificUser }

class _ComposeTab extends StatefulWidget {
  const _ComposeTab();

  @override
  State<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends State<_ComposeTab> {
  _Audience _audience = _Audience.customers;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _targetSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _targetSearchCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(NotificationTemplate t) {
    setState(() {
      _titleCtrl.text = t.title;
      _bodyCtrl.text = t.body;
    });
  }

  Future<void> _confirmAndSend(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    final bloc = context.read<NotificationsBloc>();
    if (_audience == _Audience.specificUser) {
      final uid = bloc.state.targetUser?.uid;
      if (uid == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.notificationsConfirmTitle),
          content: Text(l10n.notificationsConfirmDirectBody(bloc.state.targetUser!.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.notificationsSendAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      bloc.add(NotificationsDirectSendRequested(title: title, body: body));
    } else {
      final audienceLabel = _audienceLabel(l10n, _audience);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.notificationsConfirmTitle),
          // Honest copy: a topic send has no audience-size feedback (see
          // `handleNotifyBroadcast` — FCM never reports a topic subscriber
          // count back), so the dialog says so instead of a fake estimate.
          content: Text(l10n.notificationsConfirmBroadcastBody(audienceLabel)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.notificationsSendAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      bloc.add(NotificationsBroadcastSendRequested(
        audience: _wireAudience(_audience),
        title: title,
        body: body,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final canSend = _titleCtrl.text.trim().isNotEmpty &&
            _bodyCtrl.text.trim().isNotEmpty &&
            (_audience != _Audience.specificUser || state.targetUser != null) &&
            !state.sendBusy;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.notificationsAudienceLabel,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final a in _Audience.values)
                        ChoiceChip(
                          label: Text(_audienceLabel(l10n, a)),
                          selected: _audience == a,
                          onSelected: (_) => setState(() => _audience = a),
                        ),
                    ],
                  ),
                  if (_audience == _Audience.specificUser) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      label: l10n.notificationsTargetSearchLabel,
                      controller: _targetSearchCtrl,
                      hintText: l10n.notificationsTargetSearchHint,
                      onFieldSubmitted: (v) => context
                          .read<NotificationsBloc>()
                          .add(NotificationsTargetSearchRequested(v)),
                    ),
                    if (state.targetSearching)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: LinearProgressIndicator(),
                      )
                    else if (state.targetUser != null)
                      _TargetFoundChip(user: state.targetUser!)
                    else if (state.targetNotFound)
                      Text(
                        l10n.notificationsTargetNotFound,
                        style: TextStyle(color: AppColors.error),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.templates.isNotEmpty)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.notificationsTemplatesLabel,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final t in state.templates)
                          GestureDetector(
                            onLongPress: () => _showTemplateSheet(context, t),
                            child: ActionChip(
                              label: Text(t.name),
                              onPressed: () => _applyTemplate(t),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: l10n.notificationsTitleLabel,
                    controller: _titleCtrl,
                    onFieldSubmitted: (_) => setState(() {}),
                  ),
                  TextFormField(
                    controller: _bodyCtrl,
                    maxLines: 4,
                    maxLength: _bodyMaxLen,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.notificationsBodyLabel,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: Text(l10n.notificationsSaveTemplateAction),
                    onPressed: _titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty
                        ? null
                        : () => _promptSaveTemplate(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_titleCtrl.text.trim().isNotEmpty || _bodyCtrl.text.trim().isNotEmpty)
              _PreviewCard(title: _titleCtrl.text.trim(), body: _bodyCtrl.text.trim()),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: canSend ? () => _confirmAndSend(context) : null,
                child: state.sendBusy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : Text(l10n.notificationsSendAction),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptSaveTemplate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.notificationsSaveTemplateAction),
        content: AppTextField(label: l10n.notificationsTemplateNameLabel, controller: nameCtrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(nameCtrl.text.trim()),
            child: Text(l10n.actionSave),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    context.read<NotificationsBloc>().add(NotificationsTemplateSaveRequested(
          name: name,
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
        ));
  }

  Future<void> _showTemplateSheet(BuildContext context, NotificationTemplate t) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<NotificationsBloc>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.notificationsTemplateRename),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final nameCtrl = TextEditingController(text: t.name);
                final name = await showDialog<String>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.notificationsTemplateRename),
                    content:
                        AppTextField(label: l10n.notificationsTemplateNameLabel, controller: nameCtrl),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.actionCancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(nameCtrl.text.trim()),
                        child: Text(l10n.actionSave),
                      ),
                    ],
                  ),
                );
                if (name == null || name.isEmpty) return;
                bloc.add(NotificationsTemplateSaveRequested(
                  id: t.id,
                  name: name,
                  title: t.title,
                  body: t.body,
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(l10n.notificationsTemplateDelete,
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                bloc.add(NotificationsTemplateDeleteRequested(t.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _wireAudience(_Audience a) => switch (a) {
      _Audience.customers => 'customers',
      _Audience.owners => 'owners',
      _Audience.couriers => 'couriers',
      _Audience.all => 'all',
      _Audience.specificUser => 'all', // unreachable — specificUser sends via direct
    };

String _audienceLabel(AppLocalizations l10n, _Audience a) => switch (a) {
      _Audience.customers => l10n.notificationsAudienceCustomers,
      _Audience.owners => l10n.notificationsAudienceOwners,
      _Audience.couriers => l10n.notificationsAudienceCouriers,
      _Audience.all => l10n.notificationsAudienceAll,
      _Audience.specificUser => l10n.notificationsAudienceSpecificUser,
    };

class _TargetFoundChip extends StatelessWidget {
  const _TargetFoundChip({required this.user});

  final ManagedUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Chip(
        avatar: const Icon(Icons.person_outline, size: 18),
        label: Text('${user.name} · ${user.email}'),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.15),
              borderRadius: AppRadius.smAll,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.campaign_outlined, color: scheme.secondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.notificationsPreviewLabel,
                    style: text.labelSmall
                        ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
                Text(title.isEmpty ? '—' : title,
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(body.isEmpty ? '—' : body, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// السجل — history
// ─────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        if (state.historyEntries.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.campaign_outlined,
              title: l10n.notificationsHistoryEmptyTitle,
              message: l10n.notificationsHistoryEmptyBody,
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
              context.read<NotificationsBloc>().add(const NotificationsHistoryLoadMoreRequested());
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (state.stats != null) _StatsRow(stats: state.stats!),
              const SizedBox(height: AppSpacing.md),
              for (final entry in state.historyEntries) ...[
                _HistoryRow(entry: entry, busy: state.sendBusy),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (state.historyLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final NotificationStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        StatusChip(
          label: l10n.notificationsStatsSent(stats.sentCount),
          tone: StatusTone.positive,
        ),
        const SizedBox(width: AppSpacing.sm),
        StatusChip(
          label: l10n.notificationsStatsFailed(stats.failedCount),
          tone: StatusTone.caution,
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.busy});

  final NotificationHistoryEntry entry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final when = DateFormat.Md(locale).add_Hm().format(entry.sentAt);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(entry.kind == 'broadcast' ? Icons.campaign_outlined : Icons.person_outline,
              color: muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  entry.kind == 'broadcast'
                      ? _audienceWire(l10n, entry.audience)
                      : entry.targetUid ?? '—',
                  style: text.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _statusChip(l10n, entry.status),
                    const SizedBox(width: AppSpacing.xs),
                    Text(when, style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ],
            ),
          ),
          if (entry.status == 'failed')
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.notificationsResendAction,
              onPressed: busy
                  ? null
                  : () => context.read<NotificationsBloc>().add(NotificationsResendRequested(entry)),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(AppLocalizations l10n, String status) => switch (status) {
        'sent' => StatusChip(label: l10n.notificationsStatusSent, tone: StatusTone.positive),
        'skipped' => StatusChip(label: l10n.notificationsStatusSkipped),
        _ => StatusChip(label: l10n.notificationsStatusFailed, tone: StatusTone.caution),
      };

  String _audienceWire(AppLocalizations l10n, String? audience) => switch (audience) {
        'customers' => l10n.notificationsAudienceCustomers,
        'owners' => l10n.notificationsAudienceOwners,
        'couriers' => l10n.notificationsAudienceCouriers,
        'all' => l10n.notificationsAudienceAll,
        _ => '—',
      };
}
