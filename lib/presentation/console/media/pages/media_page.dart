import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/media/entities/media_object.dart';
import '../../../../domain/media/entities/media_reference.dart';
import '../../../../domain/media/entities/media_stats.dart';
import '../../../../domain/storage/entities/storage_folder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/shimmer_image.dart';
import '../../../widgets/common/skeletons.dart';
import '../bloc/media_bloc.dart';

/// The Founder Console media library (`/console/media`, FC14). Three tabs:
/// تصفح (browse, folder-filtered, bulk delete) / غير مستخدم (unused finder)
/// / روابط معطلة (broken finder). Crop/compress is NOT built here — it needs
/// a new dependency (locked deferral); uploads pass bytes straight through.
class MediaPage extends StatelessWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MediaBloc>(),
      child: const _MediaView(),
    );
  }
}

class _MediaView extends StatefulWidget {
  const _MediaView();

  @override
  State<_MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<_MediaView> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      child: SafeArea(
        top: false,
        child: BlocConsumer<MediaBloc, MediaState>(
          listenWhen: (a, b) => a.uploadError != b.uploadError && b.uploadError != null,
          listener: (context, state) => AppSnackBar.error(context, l10n.mediaUploadErrorBody),
          builder: (context, state) => switch (state.status) {
            MediaStatus.loading => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: GridShimmer(count: 9, columns: 3),
              ),
            MediaStatus.error => Center(
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: l10n.errorTitle,
                  message: l10n.mediaLoadError,
                  actionLabel: l10n.actionRetry,
                  onAction: () => context.read<MediaBloc>().add(const MediaRetryRequested()),
                ),
              ),
            MediaStatus.loaded => Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: l10n.mediaTabBrowse),
                      Tab(text: l10n.mediaTabUnused),
                      Tab(text: l10n.mediaTabBroken),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [_BrowseTab(), _UnusedTab(), _BrokenTab()],
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

String _folderLabel(AppLocalizations l10n, String? folder) => switch (folder) {
      null => l10n.mediaFolderAll,
      StorageFolder.shopLogos => l10n.mediaFolderShopLogos,
      StorageFolder.productImages => l10n.mediaFolderProductImages,
      StorageFolder.driverDocs => l10n.mediaFolderDriverDocs,
      StorageFolder.banners => l10n.mediaFolderBanners,
      String f => f,
    };

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ─────────────────────────────────────────────────────────────────────────
// تصفح — browse
// ─────────────────────────────────────────────────────────────────────────

class _BrowseTab extends StatelessWidget {
  const _BrowseTab();

  Future<void> _pickAndUpload(BuildContext context) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    if (!context.mounted) return;
    context.read<MediaBloc>().add(MediaUploadRequested(bytes: bytes, contentType: contentType));
  }

  Future<void> _confirmDelete(BuildContext context, int count) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.mediaDeleteConfirmTitle),
        content: Text(l10n.mediaDeleteConfirmBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.mediaDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<MediaBloc>().add(const MediaDeleteSelectedRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                  context.read<MediaBloc>().add(const MediaLoadMoreRequested());
                }
                return false;
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  state.selectedKeys.isEmpty ? AppSpacing.md : 72,
                ),
                children: [
                  if (state.stats != null) _StatsCard(stats: state.stats!),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final f in [null, ...StorageFolder.values])
                              ChoiceChip(
                                label: Text(_folderLabel(l10n, f)),
                                selected: state.folder == f,
                                onSelected: (_) =>
                                    context.read<MediaBloc>().add(MediaFolderChanged(f)),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: state.uploadBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              )
                            : const Icon(Icons.upload_outlined),
                        tooltip: l10n.mediaUploadAction,
                        onPressed: state.folder == null || state.uploadBusy
                            ? null
                            : () => _pickAndUpload(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.objects.isEmpty)
                    EmptyState(
                      icon: Icons.photo_library_outlined,
                      title: l10n.mediaEmptyTitle,
                      message: l10n.mediaEmptyBody,
                    )
                  else ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: state.objects.length,
                      itemBuilder: (context, i) {
                        final o = state.objects[i];
                        return _MediaTile(
                          object: o,
                          selected: state.selectedKeys.contains(o.key),
                          onTap: () =>
                              context.read<MediaBloc>().add(MediaSelectionToggled(o.key)),
                        );
                      },
                    ),
                    if (state.loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(
                          child: SizedBox(
                              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (state.selectedKeys.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SelectionBar(
                  count: state.selectedKeys.length,
                  busy: state.deleteBusy,
                  onClear: () => context.read<MediaBloc>().add(const MediaSelectionCleared()),
                  onDelete: () => _confirmDelete(context, state.selectedKeys.length),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final MediaStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${stats.count}', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.mediaStatsCountLabel, style: text.bodyMedium),
              const SizedBox(width: AppSpacing.lg),
              Text(_formatBytes(stats.totalBytes),
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.mediaStatsSizeLabel, style: text.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in stats.byFolder.entries)
                Text(
                  '${_folderLabel(l10n, entry.key)}: ${entry.value.count}',
                  style: text.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.busy,
    required this.onClear,
    required this.onDelete,
  });

  final int count;
  final bool busy;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.close), onPressed: busy ? null : onClear),
            Expanded(child: Text(l10n.mediaSelectedCount(count))),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: busy ? null : onDelete,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                    )
                  : const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.mediaDeleteAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.object, required this.selected, required this.onTap});

  final MediaObject object;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdAll,
                    border: selected ? Border.all(color: scheme.primary, width: 3) : null,
                  ),
                  child: ShimmerImage(
                    url: object.url,
                    fit: BoxFit.cover,
                    fallbackIcon: Icons.image_outlined,
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.check, size: 14, color: AppColors.surface),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatBytes(object.size),
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// غير مستخدم — unused finder
// ─────────────────────────────────────────────────────────────────────────

class _UnusedTab extends StatefulWidget {
  const _UnusedTab();

  @override
  State<_UnusedTab> createState() => _UnusedTabState();
}

class _UnusedTabState extends State<_UnusedTab> {
  @override
  void initState() {
    super.initState();
    context.read<MediaBloc>().add(const MediaFindersRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        return switch (state.findersStatus) {
          MediaFindersStatus.idle || MediaFindersStatus.loading => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.mediaFindersScanningBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          MediaFindersStatus.error => Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: l10n.errorTitle,
                message: l10n.mediaFindersErrorBody,
                actionLabel: l10n.actionRetry,
                onAction: () => context.read<MediaBloc>().add(const MediaFindersRequested()),
              ),
            ),
          MediaFindersStatus.loaded when state.orphans.isEmpty => Center(
              child: EmptyState(
                icon: Icons.check_circle_outline,
                title: l10n.mediaUnusedEmptyTitle,
                message: l10n.mediaUnusedEmptyBody,
              ),
            ),
          MediaFindersStatus.loaded => Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    state.orphanSelectedKeys.isEmpty ? AppSpacing.md : 72,
                  ),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () =>
                            context.read<MediaBloc>().add(const MediaOrphanSelectAllRequested()),
                        child: Text(l10n.mediaUnusedSelectAllAction),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: state.orphans.length,
                      itemBuilder: (context, i) {
                        final o = state.orphans[i];
                        return _MediaTile(
                          object: o,
                          selected: state.orphanSelectedKeys.contains(o.key),
                          onTap: () =>
                              context.read<MediaBloc>().add(MediaOrphanSelectionToggled(o.key)),
                        );
                      },
                    ),
                  ],
                ),
                if (state.orphanSelectedKeys.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _SelectionBar(
                      count: state.orphanSelectedKeys.length,
                      busy: state.findersDeleteBusy,
                      onClear: () =>
                          context.read<MediaBloc>().add(const MediaOrphanSelectionCleared()),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(l10n.mediaDeleteConfirmTitle),
                            content: Text(l10n.mediaDeleteConfirmBody(state.orphanSelectedKeys.length)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(false),
                                child: Text(l10n.actionCancel),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                onPressed: () => Navigator.of(dialogContext).pop(true),
                                child: Text(l10n.mediaDeleteAction),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          context.read<MediaBloc>().add(const MediaOrphanDeleteSelectedRequested());
                        }
                      },
                    ),
                  ),
              ],
            ),
        };
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// روابط معطلة — broken finder
// ─────────────────────────────────────────────────────────────────────────

class _BrokenTab extends StatefulWidget {
  const _BrokenTab();

  @override
  State<_BrokenTab> createState() => _BrokenTabState();
}

class _BrokenTabState extends State<_BrokenTab> {
  @override
  void initState() {
    super.initState();
    context.read<MediaBloc>().add(const MediaFindersRequested());
  }

  String _docTypeLabel(AppLocalizations l10n, String docType) => switch (docType) {
        'shop' => l10n.mediaDocTypeShop,
        'product' => l10n.mediaDocTypeProduct,
        'driver' => l10n.mediaDocTypeDriver,
        _ => l10n.mediaDocTypeBanner,
      };

  String? _boardRouteFor(String docType) => switch (docType) {
        'shop' => '/console/shops',
        'product' => '/console/products',
        'driver' => '/console/drivers',
        _ => null, // banners board doesn't exist yet (Session 16)
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        return switch (state.findersStatus) {
          MediaFindersStatus.idle || MediaFindersStatus.loading => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.mediaFindersScanningBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          MediaFindersStatus.error => Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: l10n.errorTitle,
                message: l10n.mediaFindersErrorBody,
                actionLabel: l10n.actionRetry,
                onAction: () => context.read<MediaBloc>().add(const MediaFindersRequested()),
              ),
            ),
          MediaFindersStatus.loaded when state.broken.isEmpty => Center(
              child: EmptyState(
                icon: Icons.check_circle_outline,
                title: l10n.mediaBrokenEmptyTitle,
                message: l10n.mediaBrokenEmptyBody,
              ),
            ),
          MediaFindersStatus.loaded => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.broken.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final MediaReference ref = state.broken[i];
                final route = _boardRouteFor(ref.docType);
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.broken_image_outlined, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_docTypeLabel(l10n, ref.docType),
                                style: Theme.of(context).textTheme.titleSmall),
                            Text(ref.docId,
                                style: Theme.of(context).textTheme.bodySmall, maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (route != null)
                        TextButton(
                          onPressed: () => context.push(route),
                          child: Text(l10n.mediaBrokenFixAction),
                        ),
                    ],
                  ),
                );
              },
            ),
        };
      },
    );
  }
}
