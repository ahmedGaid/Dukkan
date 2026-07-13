import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/audit/entities/audit_actions.dart';
import '../../../../domain/audit/entities/audit_entry.dart';
import '../../../../domain/audit/entities/audit_filter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/audit_log_bloc.dart';

/// The Founder Console audit viewer (`/console/audit`). The nav shell supplies
/// the app bar + title; this is the body only — a filter bar over a paginated,
/// newest-first list of immutable `/auditLogs` entries. Every state (loading,
/// empty, error) is designed; a row tap opens the full entry with a
/// before/after diff.
class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuditLogBloc>()..add(const AuditStarted()),
      child: const _AuditView(),
    );
  }
}

class _AuditView extends StatelessWidget {
  const _AuditView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          BlocSelector<AuditLogBloc, AuditLogState, AuditFilter>(
            selector: (s) => s.filter,
            builder: (context, filter) => _FilterBar(filter: filter),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: BlocBuilder<AuditLogBloc, AuditLogState>(
              buildWhen: (a, b) =>
                  a.status != b.status ||
                  a.entries != b.entries ||
                  a.hasMore != b.hasMore ||
                  a.loadingMore != b.loadingMore,
              builder: (context, state) => switch (state.status) {
                AuditLogStatus.loading => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: ListShimmer(),
                  ),
                AuditLogStatus.error => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.auditErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () => context
                        .read<AuditLogBloc>()
                        .add(const AuditRetryRequested()),
                  ),
                AuditLogStatus.loaded => state.entries.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.auditEmptyTitle,
                        message: l10n.auditEmptyBody,
                      )
                    : _AuditList(state: state),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.filter});

  final AuditFilter filter;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late final TextEditingController _targetIdCtrl =
      TextEditingController(text: widget.filter.targetId ?? '');

  @override
  void didUpdateWidget(_FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when the filter is cleared elsewhere.
    final incoming = widget.filter.targetId ?? '';
    if (incoming != _targetIdCtrl.text) _targetIdCtrl.text = incoming;
  }

  @override
  void dispose() {
    _targetIdCtrl.dispose();
    super.dispose();
  }

  void _apply(AuditFilter next) =>
      context.read<AuditLogBloc>().add(AuditFilterChanged(next));

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1),
      initialDateRange: widget.filter.from != null && widget.filter.to != null
          ? DateTimeRange(start: widget.filter.from!, end: widget.filter.to!)
          : null,
    );
    if (picked == null || !mounted) return;
    // Whole selected days, in local time (the datasource converts to UTC ISO).
    final from = DateTime(picked.start.year, picked.start.month, picked.start.day);
    final to = DateTime(
        picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999);
    _apply(widget.filter.copyWith(from: from, to: to));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final filter = widget.filter;
    final hasRange = filter.from != null && filter.to != null;

    final rangeLabel = hasRange
        ? '${DateFormat.MMMd(locale).format(filter.from!)} – '
            '${DateFormat.MMMd(locale).format(filter.to!)}'
        : l10n.auditFilterDateRange;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterDropdown(
            label: l10n.auditFilterAction,
            value: filter.action,
            options: AuditActions.knownActions,
            allLabel: l10n.auditFilterAll,
            onChanged: (v) => _apply(filter.copyWith(action: v)),
          ),
          _FilterDropdown(
            label: l10n.auditFilterType,
            value: filter.targetType,
            options: AuditActions.knownTargetTypes,
            allLabel: l10n.auditFilterAll,
            onChanged: (v) => _apply(filter.copyWith(targetType: v)),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _targetIdCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.auditFilterTargetId,
                prefixIcon: const Icon(Icons.tag, size: 18),
                border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
              ),
              onSubmitted: (v) {
                final trimmed = v.trim();
                _apply(filter.copyWith(
                    targetId: trimmed.isEmpty ? null : trimmed));
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(rangeLabel),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            ),
          ),
          if (!filter.isEmpty)
            TextButton.icon(
              onPressed: () => _apply(const AuditFilter()),
              icon: const Icon(Icons.close, size: 18),
              label: Text(l10n.auditFilterClear),
            ),
        ],
      ),
    );
  }
}

/// A compact "label: value / All" dropdown for one equality filter dimension.
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.md, end: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: text.bodySmall
                ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isDense: true,
              borderRadius: AppRadius.mdAll,
              hint: Text(allLabel, style: text.bodyMedium),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
                for (final o in options)
                  DropdownMenuItem<String?>(value: o, child: Text(o)),
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
// List + rows
// ─────────────────────────────────────────────────────────────────────────

class _AuditList extends StatelessWidget {
  const _AuditList({required this.state});

  final AuditLogState state;

  @override
  Widget build(BuildContext context) {
    final entries = state.entries;
    final showFooter = state.hasMore;

    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<AuditLogBloc>();
        bloc.add(const AuditStarted());
        await bloc.stream
            .firstWhere((s) => s.status != AuditLogStatus.loading);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
            context.read<AuditLogBloc>().add(const AuditLoadMoreRequested());
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: entries.length + (showFooter ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            if (i >= entries.length) {
              return _LoadMoreFooter(loading: state.loadingMore);
            }
            return _AuditRow(entry: entries[i]);
          },
        ),
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
                onPressed: () => context
                    .read<AuditLogBloc>()
                    .add(const AuditLoadMoreRequested()),
                child: Text(l10n.auditLoadMore),
              ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _showAuditDetail(context, entry),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TargetAvatar(type: entry.targetType),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.action.isEmpty ? '—' : entry.action,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.reported) ...[
                      const SizedBox(width: AppSpacing.sm),
                      StatusChip(
                        label: l10n.auditReported,
                        tone: StatusTone.caution,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${entry.targetType} · ${entry.targetId}',
                  style: text.bodySmall?.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: muted),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        _shortUid(entry.actorUid),
                        style: text.bodySmall?.copyWith(color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.schedule, size: 13, color: muted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _relativeTime(l10n, locale, entry.createdAt),
                      style: text.bodySmall?.copyWith(color: muted),
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

class _TargetAvatar extends StatelessWidget {
  const _TargetAvatar({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
      ),
      alignment: Alignment.center,
      child: Icon(_targetIcon(type), size: 20, color: scheme.secondary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Detail sheet
// ─────────────────────────────────────────────────────────────────────────

Future<void> _showAuditDetail(BuildContext context, AuditEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _AuditDetailSheet(entry: entry),
  );
}

class _AuditDetailSheet extends StatelessWidget {
  const _AuditDetailSheet({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final text = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final when =
        DateFormat.yMMMd(locale).add_Hm().format(entry.createdAt);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.action.isEmpty ? '—' : entry.action,
                    style: text.titleLarge,
                  ),
                ),
                if (entry.reported) ...[
                  const SizedBox(width: AppSpacing.sm),
                  StatusChip(
                      label: l10n.auditReported, tone: StatusTone.caution),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              label: l10n.auditDetailTarget,
              value: '${entry.targetType} · ${entry.targetId}',
            ),
            _DetailRow(
                label: l10n.auditDetailActor, value: entry.actorUid),
            _DetailRow(label: l10n.auditDetailWhen, value: when),
            if (entry.reason != null && entry.reason!.isNotEmpty)
              _DetailRow(
                  label: l10n.auditDetailReason, value: entry.reason!),
            if (entry.ip != null && entry.ip!.isNotEmpty)
              _DetailRow(label: l10n.auditDetailIp, value: entry.ip!),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.auditDetailChanges, style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _DiffTable(before: entry.before, after: entry.after),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: text.bodyMedium
                  ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SelectableText(value, style: text.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Aligned key → before → after table, only for keys that actually changed.
class _DiffTable extends StatelessWidget {
  const _DiffTable({required this.before, required this.after});

  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final b = before ?? const {};
    final a = after ?? const {};
    final keys = <String>{...b.keys, ...a.keys}
        .where((k) => _valueString(b[k]) != _valueString(a[k]))
        .toList()
      ..sort();

    if (keys.isEmpty) {
      return Text(
        l10n.auditDetailNoChanges,
        style: text.bodyMedium
            ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
      );
    }

    final muted = scheme.onSurface.withValues(alpha: 0.6);
    Widget cell(String s, {Color? color}) =>
        Text(s, style: text.bodySmall?.copyWith(color: color));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(flex: 3, child: cell(l10n.auditDetailField, color: muted)),
              Expanded(flex: 4, child: cell(l10n.auditDetailBefore, color: muted)),
              Expanded(flex: 4, child: cell(l10n.auditDetailAfter, color: muted)),
            ],
          ),
        ),
        const Divider(height: 1),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(k,
                      style:
                          text.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(flex: 4, child: cell(_valueString(b[k]))),
                Expanded(
                  flex: 4,
                  child: cell(_valueString(a[k]), color: scheme.primary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────

String _shortUid(String uid) {
  if (uid.isEmpty) return '—';
  if (uid.length <= 12) return uid;
  return '${uid.substring(0, 6)}…${uid.substring(uid.length - 4)}';
}

String _valueString(dynamic v) {
  if (v == null) return '—';
  if (v is String) return v.isEmpty ? '—' : v;
  try {
    return jsonEncode(v);
  } catch (_) {
    return v.toString();
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
