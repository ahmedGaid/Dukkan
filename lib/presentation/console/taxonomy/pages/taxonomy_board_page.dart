import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/usecases/count_products_in_category.dart';
import '../../../../domain/taxonomy/entities/category.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/widgets/category_grid.dart' show categoryIcon;
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/skeletons.dart';
import '../bloc/taxonomy_board_bloc.dart';
import '../category_icons.dart';

/// The Founder Console taxonomy board (`/console/taxonomy`, FC9). The tree is
/// small (~7 categories) so the whole thing loads at once — no search/
/// pagination, unlike the shops/products boards. Reorder is two adjacent
/// `sort` swaps (no drag dependency); hide/show and delete both act on the
/// category only, never its embedded subcategories (session scope — see
/// `FILE_09_TAXONOMY_GEO.md` Task B).
class TaxonomyBoardPage extends StatelessWidget {
  const TaxonomyBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaxonomyBoardBloc>()..add(const TaxonomyBoardStarted()),
      child: const _TaxonomyBoardView(),
    );
  }
}

class _TaxonomyBoardView extends StatelessWidget {
  const _TaxonomyBoardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: BlocConsumer<TaxonomyBoardBloc, TaxonomyBoardState>(
        listenWhen: (a, b) => a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError) {
            AppSnackBar.error(context, l10n.taxonomyBoardActionFailed);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.taxonomyBoardHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => _openCategorySheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.taxonomyBoardAddAction),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: switch (state.status) {
                  TaxonomyBoardStatus.loading => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: ListShimmer(),
                    ),
                  TaxonomyBoardStatus.error => EmptyState(
                      icon: Icons.error_outline,
                      title: l10n.errorTitle,
                      message: l10n.taxonomyBoardErrorBody,
                      actionLabel: l10n.actionRetry,
                      onAction: () => context
                          .read<TaxonomyBoardBloc>()
                          .add(const TaxonomyBoardRetryRequested()),
                    ),
                  TaxonomyBoardStatus.loaded => state.categories.isEmpty
                      ? EmptyState(
                          icon: Icons.category_outlined,
                          title: l10n.taxonomyBoardEmptyTitle,
                          actionLabel: l10n.taxonomyBoardAddAction,
                          onAction: () => _openCategorySheet(context),
                        )
                      : _CategoryList(categories: state.categories),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _CategoryRow(
        category: categories[i],
        canMoveUp: i > 0,
        canMoveDown: i < categories.length - 1,
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  final Category category;
  final bool canMoveUp;
  final bool canMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bloc = context.read<TaxonomyBoardBloc>();
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: scheme.surface,
      borderRadius: AppRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  onPressed: canMoveUp
                      ? () => bloc.add(TaxonomyBoardMoveRequested(category.id, up: true))
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: canMoveDown
                      ? () => bloc.add(TaxonomyBoardMoveRequested(category.id, up: false))
                      : null,
                ),
              ],
            ),
            Icon(
              resolveCategoryIcon(category.iconName, categoryIcon(category.id)),
              color: category.isVisible ? scheme.primary : muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                isArabic ? category.nameAr : category.nameEn,
                style: text.titleSmall?.copyWith(
                  color: category.isVisible ? null : muted,
                  decoration: category.isVisible ? null : TextDecoration.lineThrough,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(category.isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              tooltip: category.isVisible ? l10n.taxonomyBoardHide : l10n.taxonomyBoardShow,
              onPressed: () => bloc.add(
                TaxonomyBoardVisibilityToggled(category.id, !category.isVisible),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openCategorySheet(context, category: category),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, category),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, Category category) async {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<TaxonomyBoardBloc>();
  final count = await sl<CountProductsInCategory>()(category.id);
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.taxonomyBoardDeleteConfirmTitle),
      content: Text(
        count > 0
            ? l10n.taxonomyBoardDeleteConfirmBodyWithProducts(count)
            : l10n.taxonomyBoardDeleteConfirmBody,
      ),
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
    bloc.add(TaxonomyBoardDeleteRequested(category.id));
  }
}

Future<void> _openCategorySheet(BuildContext context, {Category? category}) {
  final bloc = context.read<TaxonomyBoardBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _CategorySheet(category: category),
    ),
  );
}

/// Create/edit form — same sheet, pre-filled in edit mode. Submitting is
/// optimistic: the sheet pops immediately and the bloc's action-failure
/// state (listened to by [_TaxonomyBoardView]) snackbars if the write didn't
/// land (mirrors `_CollectionSheet`).
class _CategorySheet extends StatefulWidget {
  const _CategorySheet({this.category});

  final Category? category;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameAr = TextEditingController(text: widget.category?.nameAr ?? '');
  late final _nameEn = TextEditingController(text: widget.category?.nameEn ?? '');
  late String? _iconName = widget.category?.iconName;

  bool get _isEdit => widget.category != null;

  @override
  void dispose() {
    _nameAr.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<TaxonomyBoardBloc>();
    final nameAr = _nameAr.text.trim();
    final nameEn = _nameEn.text.trim();
    if (_isEdit) {
      bloc.add(TaxonomyBoardUpdateRequested(
        categoryId: widget.category!.id,
        nameAr: nameAr,
        nameEn: nameEn,
        iconName: _iconName,
      ));
    } else {
      bloc.add(TaxonomyBoardCreateRequested(nameAr: nameAr, nameEn: nameEn, iconName: _iconName));
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? l10n.taxonomyBoardEditTitle : l10n.taxonomyBoardAddAction,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.fieldCategoryNameAr,
                controller: _nameAr,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
              ),
              AppTextField(
                label: l10n.fieldCategoryNameEn,
                controller: _nameEn,
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.taxonomyBoardIconLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              _IconPicker(
                selected: _iconName,
                onSelect: (name) => setState(() => _iconName = name),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _isEdit ? l10n.actionSave : l10n.actionCreate,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final entry in categoryIconOptions.entries)
          InkWell(
            onTap: () => onSelect(entry.key),
            borderRadius: AppRadius.mdAll,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                color: selected == entry.key ? scheme.secondary.withValues(alpha: 0.16) : null,
                border: Border.all(
                  color: selected == entry.key ? scheme.secondary : scheme.outline,
                  width: selected == entry.key ? 1.5 : 1,
                ),
              ),
              child: Icon(entry.value, size: 20),
            ),
          ),
      ],
    );
  }
}
