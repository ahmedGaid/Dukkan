import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/collections/entities/shop_collection.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeletons.dart';
import '../bloc/collections_bloc.dart';

/// Owner's collections manager (M6) — reached from `catalog_manager_page.dart`.
/// One [CollectionsBloc] per open (shop id is the factory param); the
/// create/rename sheet and delete dialog both close optimistically and rely
/// on the realtime list to reflect the result, snackbar-ing only on failure.
class CollectionsManagerPage extends StatelessWidget {
  const CollectionsManagerPage({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CollectionsBloc>(param1: shopId)
        ..add(const CollectionsStarted()),
      child: const _CollectionsView(),
    );
  }
}

class _CollectionsView extends StatelessWidget {
  const _CollectionsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.catalogCollectionsEntry)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCollectionSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<CollectionsBloc, CollectionsState>(
        listenWhen: (previous, current) =>
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == CollectionsActionStatus.failure) {
            AppSnackBar.error(context, l10n.collectionsActionErrorBody);
          }
        },
        builder: (context, state) => switch (state.status) {
          CollectionsStatus.loading => const _CollectionsLoading(),
          CollectionsStatus.error => EmptyState(
              icon: Icons.wifi_off_rounded,
              title: l10n.errorTitle,
              message: l10n.collectionsErrorBody,
              actionLabel: l10n.actionRetry,
              onAction: () => context
                  .read<CollectionsBloc>()
                  .add(const CollectionsRetryRequested()),
            ),
          CollectionsStatus.loaded => state.collections.isEmpty
              ? EmptyState(
                  icon: Icons.collections_bookmark_outlined,
                  title: l10n.collectionsEmptyTitle,
                  actionLabel: l10n.collectionsEmptyAction,
                  onAction: () => _openCollectionSheet(context),
                )
              : _CollectionsList(collections: state.collections),
        },
      ),
    );
  }
}

class _CollectionsLoading extends StatelessWidget {
  const _CollectionsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: ListShimmer(count: 4, itemHeight: 56),
    );
  }
}

class _CollectionsList extends StatelessWidget {
  const _CollectionsList({required this.collections});

  final List<ShopCollection> collections;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: collections.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final collection = collections[i];
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.mdAll,
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            title: Text(isArabic ? collection.nameAr : collection.nameEn),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      _openCollectionSheet(context, collection: collection),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, collection),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  ShopCollection collection,
) async {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<CollectionsBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.collectionsDeleteConfirmTitle),
      content: Text(l10n.collectionsDeleteConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    bloc.add(CollectionsDeleteRequested(collection.id));
  }
}

Future<void> _openCollectionSheet(
  BuildContext context, {
  ShopCollection? collection,
}) {
  final bloc = context.read<CollectionsBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _CollectionSheet(collection: collection),
    ),
  );
}

/// Create/rename form — same sheet, pre-filled in edit mode. Submitting is
/// optimistic: the sheet pops immediately and the bloc's action-failure state
/// (listened to by [_CollectionsView]) snackbars if the write didn't land.
class _CollectionSheet extends StatefulWidget {
  const _CollectionSheet({this.collection});

  final ShopCollection? collection;

  @override
  State<_CollectionSheet> createState() => _CollectionSheetState();
}

class _CollectionSheetState extends State<_CollectionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameAr =
      TextEditingController(text: widget.collection?.nameAr ?? '');
  late final _nameEn =
      TextEditingController(text: widget.collection?.nameEn ?? '');

  bool get _isEdit => widget.collection != null;

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<CollectionsBloc>();
    final nameAr = _nameAr.text.trim();
    final nameEn = _nameEn.text.trim();
    if (_isEdit) {
      bloc.add(CollectionsRenameRequested(
        collectionId: widget.collection!.id,
        nameAr: nameAr,
        nameEn: nameEn,
      ));
    } else {
      bloc.add(CollectionsCreateRequested(nameAr: nameAr, nameEn: nameEn));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? l10n.collectionsRenameTitle : l10n.collectionsCreateTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.fieldCollectionNameAr,
              controller: _nameAr,
              textInputAction: TextInputAction.next,
              hintText: _isEdit ? null : l10n.collectionNameArHint,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
            ),
            AppTextField(
              label: l10n.fieldCollectionNameEn,
              controller: _nameEn,
              textInputAction: TextInputAction.done,
              hintText: _isEdit ? null : l10n.collectionNameEnHint,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: _isEdit ? l10n.actionSave : l10n.actionCreate,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
