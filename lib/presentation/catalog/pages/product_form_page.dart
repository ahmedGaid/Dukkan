import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injector.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/product/entities/product.dart';
import '../../../domain/product/entities/stock_status.dart';
import '../../../domain/product/usecases/create_product.dart';
import '../../../domain/product/usecases/update_product.dart';
import '../../../domain/storage/entities/storage_folder.dart';
import '../../../domain/storage/usecases/upload_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/shimmer_image.dart';

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
  late final _category =
      TextEditingController(text: widget.product?.category ?? '');
  late final _price =
      TextEditingController(text: _initialPriceText(widget.product));
  late StockStatus _stockStatus =
      widget.product?.stockStatus ?? StockStatus.inStock;
  late bool _isPromo = widget.product?.isPromo ?? false;
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _submitting = false;

  bool get _isEdit => widget.product != null;

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _category.dispose();
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
      if (existing == null) {
        await sl<CreateProduct>()(
          shopId: widget.shopId,
          name: _name.text.trim(),
          nameAr: _nameAr.text.trim(),
          priceMinor: priceMinor,
          category: _category.text.trim(),
          stockStatus: _stockStatus,
          isPromo: _isPromo,
          imageUrl: imageUrl,
        );
      } else {
        await sl<UpdateProduct>()(Product(
          id: existing.id,
          shopId: existing.shopId,
          name: _name.text.trim(),
          nameAr: _nameAr.text.trim(),
          priceMinor: priceMinor,
          category: _category.text.trim(),
          stockStatus: _stockStatus,
          isPromo: _isPromo,
          imageUrl: imageUrl,
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
                AppTextField(
                  label: l10n.fieldProductCategory,
                  controller: _category,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.category_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
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
