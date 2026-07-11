import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injector.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/collections/entities/shop_collection.dart';
import '../../../domain/collections/usecases/get_collections.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';
import '../../../domain/product/usecases/create_product.dart';
import '../../../domain/product/usecases/update_product.dart';
import '../../../domain/storage/entities/storage_folder.dart';
import '../../../domain/storage/usecases/upload_image.dart';
import '../../../domain/taxonomy/entities/category.dart';
import '../../../domain/taxonomy/usecases/get_taxonomy.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/shimmer_image.dart';
import '../../widgets/common/skeletons.dart';

/// Navigation payload for `/catalog/product-form` — [product] null means
/// create, non-null means edit (S2).
class ProductFormArgs {
  const ProductFormArgs({required this.shopId, this.product});

  final String shopId;
  final Product? product;
}

String _initialPriceText(Product? product) {
  if (product == null) return '';
  final pounds = product.priceMinor / 100;
  return product.priceMinor % 100 == 0
      ? pounds.toStringAsFixed(0)
      : pounds.toStringAsFixed(2);
}

String _stockLabel(AppLocalizations l10n, StockStatus status) => switch (status) {
      StockStatus.inStock => l10n.productStockIn,
      StockStatus.lowStock => l10n.productStockLow,
      StockStatus.outOfStock => l10n.productStockOut,
    };

/// Owner's add/edit product form (S2). One-shot write, no bloc — matches
/// `ShopOnboardingPage`'s direct usecase-call pattern. The catalog list
/// refreshes itself via `ProductsBloc`'s realtime Firestore snapshot, so this
/// page just pops back on success.
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, required this.shopId, this.product});

  final String shopId;
  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _nameAr =
      TextEditingController(text: widget.product?.nameAr ?? '');
  late final _price =
      TextEditingController(text: _initialPriceText(widget.product));
  late StockStatus _stockStatus =
      widget.product?.stockStatus ?? StockStatus.inStock;
  late bool _isPromo = widget.product?.isPromo ?? false;
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _submitting = false;

  // Taxonomy (M3/M4) — `category` on a product IS the parent category's id
  // (Task B/D: written automatically from the selected subcategory), so an
  // edited product's own `category` field already gives us the pre-selected
  // category without scanning the tree for it.
  late Future<List<Category>> _taxonomyFuture = sl<GetTaxonomy>()();
  String? _categoryId;
  String? _subcategoryId;

  // Collections (M7) — one-shot load per form open, same style as taxonomy.
  late final Future<List<ShopCollection>> _collectionsFuture =
      sl<GetCollections>()(widget.shopId);
  late Set<String> _selectedCollectionIds =
      Set.of(widget.product?.collectionIds ?? const []);

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.category;
    _subcategoryId = widget.product?.subcategoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imagePath = file.path;
    });
  }

  String _mimeTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final priceMinor = Money.parseToMinor(_price.text);
    if (priceMinor == null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);

    var imageUrl = widget.product?.imageUrl;
    final bytes = _imageBytes;
    if (bytes != null) {
      try {
        imageUrl = await sl<UploadImage>()(
          bytes: bytes,
          contentType: _mimeTypeFor(_imagePath!),
          folder: StorageFolder.productImages,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _submitting = false);
        AppSnackBar.error(context, l10n.productImageErrorBody);
        return;
      }
    }

    try {
      final existing = widget.product;
      // Both selections are validator-enforced above, so `!` is safe here.
      final categoryId = _categoryId!;
      final subcategoryId = _subcategoryId!;
      final collectionIds = _selectedCollectionIds.toList();
      if (existing == null) {
        await sl<CreateProduct>()(
          shopId: widget.shopId,
          name: _name.text.trim(),
          nameAr: _nameAr.text.trim(),
          priceMinor: priceMinor,
          category: categoryId,
          subcategoryId: subcategoryId,
          stockStatus: _stockStatus,
          isPromo: _isPromo,
          imageUrl: imageUrl,
          collectionIds: collectionIds,
        );
      } else {
        await sl<UpdateProduct>()(Product(
          id: existing.id,
          shopId: existing.shopId,
          name: _name.text.trim(),
          nameAr: _nameAr.text.trim(),
          priceMinor: priceMinor,
          category: categoryId,
          subcategoryId: subcategoryId,
          stockStatus: _stockStatus,
          isPromo: _isPromo,
          imageUrl: imageUrl,
          collectionIds: collectionIds,
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, l10n.productFormErrorBody);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editProductTitle : l10n.addProductTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _ProductImagePicker(
                    bytes: _imageBytes,
                    existingUrl: widget.product?.imageUrl,
                    onTap: _pickImage,
                    label: l10n.productImageLabel,
                    hint: l10n.shopOnboardingLogoHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.fieldProductName,
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.shopping_basket_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                ),
                AppTextField(
                  label: l10n.fieldProductNameAr,
                  controller: _nameAr,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.shopping_basket_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                ),
                _TaxonomyFields(
                  future: _taxonomyFuture,
                  categoryId: _categoryId,
                  subcategoryId: _subcategoryId,
                  onCategoryChanged: (id) => setState(() {
                    _categoryId = id;
                    _subcategoryId = null;
                  }),
                  onSubcategoryChanged: (id) =>
                      setState(() => _subcategoryId = id),
                  onRetry: () =>
                      setState(() => _taxonomyFuture = sl<GetTaxonomy>()()),
                ),
                _CollectionsPicker(
                  future: _collectionsFuture,
                  selected: _selectedCollectionIds,
                  onChanged: (ids) =>
                      setState(() => _selectedCollectionIds = ids),
                ),
                AppTextField(
                  label: l10n.fieldProductPrice,
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.payments_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.validateRequired;
                    return Money.parseToMinor(v) == null
                        ? l10n.validatePriceInvalid
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.fieldProductStock, style: text.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: StockStatus.values.map((status) {
                    final selected = _stockStatus == status;
                    final scheme = Theme.of(context).colorScheme;
                    return ChoiceChip(
                      label: Text(_stockLabel(l10n, status)),
                      selected: selected,
                      onSelected: (_) => setState(() => _stockStatus = status),
                      selectedColor: scheme.primary,
                      backgroundColor: scheme.surfaceContainerHighest,
                      showCheckmark: false,
                      labelStyle: text.bodySmall?.copyWith(
                        color: selected ? scheme.onPrimary : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected ? scheme.primary : scheme.outline,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isPromo,
                  onChanged: (v) => setState(() => _isPromo = v),
                  title: Text(l10n.fieldProductPromoLabel, style: text.bodyMedium),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _isEdit ? l10n.actionSave : l10n.actionAddProduct,
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Category → subcategory dropdowns (M4). Loads the fixed ~5-category tree
/// once per form open (a `FutureBuilder` over a single small read, matching
/// this page's no-bloc style); the second dropdown is empty/disabled until a
/// category is picked. Taxonomy is small enough that a search UI inside the
/// dropdowns isn't needed yet — `DropdownMenu(enableFilter: true)` is the
/// upgrade path if the tree grows.
class _TaxonomyFields extends StatelessWidget {
  const _TaxonomyFields({
    required this.future,
    required this.categoryId,
    required this.subcategoryId,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.onRetry,
  });

  final Future<List<Category>> future;
  final String? categoryId;
  final String? subcategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onSubcategoryChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return FutureBuilder<List<Category>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: ListShimmer(count: 2, itemHeight: 56),
          );
        }
        if (snapshot.hasError) {
          final scheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: scheme.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.taxonomyErrorBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
                ],
              ),
            ),
          );
        }

        final categories = snapshot.data!;
        Category? selected;
        for (final c in categories) {
          if (c.id == categoryId) {
            selected = c;
            break;
          }
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DropdownButtonFormField<String>(
                initialValue: selected?.id,
                decoration: InputDecoration(
                  labelText: l10n.fieldProductCategory,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(isArabic ? c.nameAr : c.nameEn),
                    ),
                ],
                onChanged: onCategoryChanged,
                validator: (v) => v == null ? l10n.categoryRequired : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DropdownButtonFormField<String>(
                key: ValueKey(selected?.id),
                initialValue: subcategoryId,
                decoration: InputDecoration(
                  labelText: l10n.fieldProductSubcategory,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: [
                  for (final s in selected?.subcategories ?? const [])
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(isArabic ? s.nameAr : s.nameEn),
                    ),
                ],
                onChanged: selected == null ? null : onSubcategoryChanged,
                validator: (v) =>
                    v == null ? l10n.subcategoryRequired : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Multi-select collection chips (M7) — below the taxonomy dropdowns,
/// optional (zero selected is valid). A shop with no collections yet hides
/// the whole block rather than showing an empty shell; a load error does the
/// same (this is a secondary, optional field — never worth blocking the rest
/// of the form over).
class _CollectionsPicker extends StatelessWidget {
  const _CollectionsPicker({
    required this.future,
    required this.selected,
    required this.onChanged,
  });

  final Future<List<ShopCollection>> future;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return FutureBuilder<List<ShopCollection>>(
      future: future,
      builder: (context, snapshot) {
        final collections = snapshot.data ?? const <ShopCollection>[];
        if (snapshot.connectionState != ConnectionState.done ||
            collections.isEmpty) {
          return const SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.productCollections, style: text.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final collection in collections)
                    FilterChip(
                      label: Text(
                        isArabic ? collection.nameAr : collection.nameEn,
                      ),
                      selected: selected.contains(collection.id),
                      onSelected: (isSelected) {
                        final next = Set.of(selected);
                        if (isSelected) {
                          next.add(collection.id);
                        } else {
                          next.remove(collection.id);
                        }
                        onChanged(next);
                      },
                      selectedColor: scheme.primary,
                      backgroundColor: scheme.surfaceContainerHighest,
                      showCheckmark: false,
                      labelStyle: text.bodySmall?.copyWith(
                        color: selected.contains(collection.id)
                            ? scheme.onPrimary
                            : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected.contains(collection.id)
                            ? scheme.primary
                            : scheme.outline,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Square photo picker — mirrors `ShopOnboardingPage`'s round `_LogoPicker`
/// but square (products aren't logos), and shows the existing network image
/// in edit mode until a new one is picked.
class _ProductImagePicker extends StatelessWidget {
  const _ProductImagePicker({
    required this.bytes,
    required this.existingUrl,
    required this.onTap,
    required this.label,
    required this.hint,
  });

  final Uint8List? bytes;
  final String? existingUrl;
  final VoidCallback onTap;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final hasImage =
        bytes != null || (existingUrl != null && existingUrl!.isNotEmpty);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.10),
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: scheme.outline),
            ),
            child: bytes != null
                ? Image.memory(bytes!, fit: BoxFit.cover)
                : hasImage
                    ? ShimmerImage(
                        url: existingUrl,
                        fit: BoxFit.cover,
                        radius: BorderRadius.zero,
                      )
                    : Icon(
                        Icons.add_a_photo_outlined,
                        color: scheme.secondary,
                        size: 28,
                      ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(hasImage ? label : hint, style: text.labelLarge),
        ],
      ),
    );
  }
}
