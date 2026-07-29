import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/search/arabic_fold.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/repositories/admin_products_repository.dart';
import '../../../../domain/admin/repositories/admin_shops_repository.dart';
import '../../../../domain/product/entities/product.dart';
import '../../../../domain/promos/entities/promo_banner.dart';
import '../../../../domain/shop/entities/shop.dart';
import '../../../../domain/storage/entities/storage_folder.dart';
import '../../../../domain/storage/usecases/upload_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/shimmer_image.dart';
import '../../../widgets/common/skeletons.dart';
import '../bloc/banners_board_bloc.dart';

class BannersTab extends StatelessWidget {
  const BannersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<BannersBoardBloc, BannersBoardState>(
      listenWhen: (a, b) => a.actionError != b.actionError,
      listener: (context, state) {
        if (state.actionError) {
          AppSnackBar.error(context, l10n.promosActionFailed);
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
                      l10n.promosBannersHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => _openBannerSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.promosBannersAddAction),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: switch (state.status) {
                BannersBoardStatus.loading =>
                  const Padding(padding: EdgeInsets.all(AppSpacing.md), child: ListShimmer()),
                BannersBoardStatus.error => EmptyState(
                    icon: Icons.error_outline,
                    title: l10n.errorTitle,
                    message: l10n.promosBannersErrorBody,
                    actionLabel: l10n.actionRetry,
                    onAction: () => context
                        .read<BannersBoardBloc>()
                        .add(const BannersBoardRetryRequested()),
                  ),
                BannersBoardStatus.loaded => state.banners.isEmpty
                    ? EmptyState(
                        icon: Icons.campaign_outlined,
                        title: l10n.promosBannersEmptyTitle,
                        actionLabel: l10n.promosBannersAddAction,
                        onAction: () => _openBannerSheet(context),
                      )
                    : _BannerList(banners: state.banners),
              },
            ),
          ],
        );
      },
    );
  }
}

class _BannerList extends StatelessWidget {
  const _BannerList({required this.banners});

  final List<PromoBanner> banners;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: banners.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _BannerRow(
        banner: banners[i],
        canMoveUp: i > 0,
        canMoveDown: i < banners.length - 1,
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.banner,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  final PromoBanner banner;
  final bool canMoveUp;
  final bool canMoveDown;

  String _targetLabel(AppLocalizations l10n) => switch (banner.targetType) {
        BannerTargetType.shop => l10n.promosBannerTargetShop,
        BannerTargetType.product => l10n.promosBannerTargetProduct,
        BannerTargetType.none => l10n.promosBannerTargetNone,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bloc = context.read<BannersBoardBloc>();
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
                      ? () => bloc.add(BannersBoardMoveRequested(banner.id, up: true))
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  onPressed: canMoveDown
                      ? () => bloc.add(BannersBoardMoveRequested(banner.id, up: false))
                      : null,
                ),
              ],
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: ShimmerImage(
                url: banner.imageUrl,
                width: 56,
                height: 56,
                fallbackIcon: Icons.campaign_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _targetLabel(l10n),
                    style: text.titleSmall?.copyWith(
                      color: banner.isActive ? null : muted,
                      decoration: banner.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  if (banner.startsAt != null || banner.endsAt != null)
                    Text(
                      l10n.promosBannerWindow(
                        banner.startsAt == null
                            ? '—'
                            : DateFormat.yMMMd().format(banner.startsAt!),
                        banner.endsAt == null ? '—' : DateFormat.yMMMd().format(banner.endsAt!),
                      ),
                      style: text.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(banner.isActive ? Icons.toggle_on : Icons.toggle_off_outlined),
              color: banner.isActive ? scheme.primary : muted,
              tooltip: banner.isActive ? l10n.actionDeactivate : l10n.actionActivate,
              onPressed: () => bloc.add(
                BannersBoardActiveToggled(banner.id, !banner.isActive),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openBannerSheet(context, banner: banner),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteBanner(context, banner),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteBanner(BuildContext context, PromoBanner banner) async {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<BannersBoardBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.promosBannerDeleteConfirmTitle),
      content: Text(l10n.promosBannerDeleteConfirmBody),
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
    bloc.add(BannersBoardDeleteRequested(banner.id));
  }
}

Future<void> _openBannerSheet(BuildContext context, {PromoBanner? banner}) {
  final bloc = context.read<BannersBoardBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: _BannerSheet(banner: banner),
    ),
  );
}

class _BannerSheet extends StatefulWidget {
  const _BannerSheet({this.banner});

  final PromoBanner? banner;

  @override
  State<_BannerSheet> createState() => _BannerSheetState();
}

class _BannerSheetState extends State<_BannerSheet> {
  Uint8List? _imageBytes;
  String? _imagePath;
  late BannerTargetType _targetType = widget.banner?.targetType ?? BannerTargetType.none;
  late String? _targetId = widget.banner?.targetId;
  late String? _targetShopId = widget.banner?.targetShopId;

  /// Display-only — null until a target is freshly picked THIS session. An
  /// existing banner's target has no denormalized name to show without an
  /// extra fetch, so the button falls back to a neutral "already set" label
  /// instead (see [_targetButtonLabel]).
  String? _targetLabel;
  late DateTime? _startsAt = widget.banner?.startsAt;
  late DateTime? _endsAt = widget.banner?.endsAt;
  bool _submitting = false;

  bool get _isEdit => widget.banner != null;

  String _targetButtonLabel(AppLocalizations l10n) =>
      _targetLabel ?? (_targetId != null ? l10n.promosBannerTargetAlreadySet : l10n.promosBannerPickTarget);

  String _mimeTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imagePath = file.path;
    });
  }

  Future<void> _pickShopTarget() async {
    final shop = await showModalBottomSheet<Shop>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ShopSearchSheet(),
    );
    if (shop == null) return;
    setState(() {
      _targetId = shop.id;
      _targetShopId = null;
      _targetLabel = shop.nameAr;
    });
  }

  Future<void> _pickProductTarget() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ProductSearchSheet(),
    );
    if (product == null) return;
    setState(() {
      _targetId = product.id;
      _targetShopId = product.shopId;
      _targetLabel = product.nameAr;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final current = isStart ? _startsAt : _endsAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startsAt = picked;
      } else {
        _endsAt = picked;
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_targetType != BannerTargetType.none && _targetId == null) {
      AppSnackBar.error(context, l10n.promosBannerTargetRequired);
      return;
    }
    if (!_isEdit && _imageBytes == null) {
      AppSnackBar.error(context, l10n.promosBannerImageRequired);
      return;
    }
    setState(() => _submitting = true);
    final bloc = context.read<BannersBoardBloc>();

    String? imageUrl = widget.banner?.imageUrl;
    final bytes = _imageBytes;
    if (bytes != null) {
      try {
        imageUrl = await sl<UploadImage>()(
          bytes: bytes,
          contentType: _mimeTypeFor(_imagePath!),
          folder: StorageFolder.banners,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _submitting = false);
        AppSnackBar.error(context, l10n.promosBannerUploadErrorBody);
        return;
      }
    }
    if (imageUrl == null) return;

    if (_isEdit) {
      bloc.add(BannersBoardUpdateRequested(PromoBanner(
        id: widget.banner!.id,
        imageUrl: imageUrl,
        targetType: _targetType,
        targetId: _targetType == BannerTargetType.none ? null : _targetId,
        targetShopId: _targetType == BannerTargetType.product ? _targetShopId : null,
        sort: widget.banner!.sort,
        isActive: widget.banner!.isActive,
        startsAt: _startsAt,
        endsAt: _endsAt,
      )));
    } else {
      bloc.add(BannersBoardCreateRequested(
        imageUrl: imageUrl,
        targetType: _targetType,
        targetId: _targetType == BannerTargetType.none ? null : _targetId,
        targetShopId: _targetType == BannerTargetType.product ? _targetShopId : null,
        startsAt: _startsAt,
        endsAt: _endsAt,
      ));
    }
    if (!mounted) return;
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? l10n.promosBannerEditTitle : l10n.promosBannersAddAction,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                height: 120,
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: AppRadius.mdAll,
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : ShimmerImage(
                        url: widget.banner?.imageUrl,
                        height: 120,
                        fallbackIcon: Icons.add_photo_alternate_outlined,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(l10n.promosBannerPickImage),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.promosBannerTargetLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<BannerTargetType>(
              segments: [
                ButtonSegment(
                  value: BannerTargetType.none,
                  label: Text(l10n.promosBannerTargetNone),
                ),
                ButtonSegment(
                  value: BannerTargetType.shop,
                  label: Text(l10n.promosBannerTargetShop),
                ),
                ButtonSegment(
                  value: BannerTargetType.product,
                  label: Text(l10n.promosBannerTargetProduct),
                ),
              ],
              selected: {_targetType},
              onSelectionChanged: (v) => setState(() {
                _targetType = v.first;
                _targetId = null;
                _targetShopId = null;
                _targetLabel = null;
              }),
            ),
            if (_targetType != BannerTargetType.none) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: _targetType == BannerTargetType.shop
                    ? _pickShopTarget
                    : _pickProductTarget,
                child: Text(_targetButtonLabel(l10n)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(l10n.promosBannerWindowLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(
                      _startsAt == null
                          ? l10n.promosBannerStartsAt
                          : DateFormat.yMMMd().format(_startsAt!),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(
                      _endsAt == null ? l10n.promosBannerEndsAt : DateFormat.yMMMd().format(_endsAt!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: _isEdit ? l10n.actionSave : l10n.actionCreate,
              loading: _submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small "small marketplace" search sheet — one unpaginated load, client-side
/// Arabic-folded filter, same tradeoff as the assign-driver sheet.
class _ShopSearchSheet extends StatefulWidget {
  const _ShopSearchSheet();

  @override
  State<_ShopSearchSheet> createState() => _ShopSearchSheetState();
}

class _ShopSearchSheetState extends State<_ShopSearchSheet> {
  late final _future = sl<AdminShopsRepository>().getAllShops();
  String _query = '';

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
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: l10n.promosSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = normalizeSearch(v)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<Shop>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const ListShimmer();
                  }
                  final shops = (snapshot.data ?? const [])
                      .where((s) =>
                          _query.isEmpty ||
                          normalizeSearch(s.nameAr).contains(_query) ||
                          normalizeSearch(s.name).contains(_query))
                      .toList();
                  if (shops.isEmpty) {
                    return EmptyState(icon: Icons.storefront_outlined, title: l10n.promosSearchEmpty);
                  }
                  return ListView.builder(
                    itemCount: shops.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(shops[i].nameAr),
                      onTap: () => Navigator.of(context).pop(shops[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSearchSheet extends StatefulWidget {
  const _ProductSearchSheet();

  @override
  State<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<_ProductSearchSheet> {
  late final _future = sl<AdminProductsRepository>().getAllMatching();
  String _query = '';

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
      child: SizedBox(
        height: 420,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: l10n.promosSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = normalizeSearch(v)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const ListShimmer();
                  }
                  final products = (snapshot.data ?? const [])
                      .where((p) =>
                          _query.isEmpty ||
                          normalizeSearch(p.nameAr).contains(_query) ||
                          normalizeSearch(p.name).contains(_query))
                      .toList();
                  if (products.isEmpty) {
                    return EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.promosSearchEmpty,
                    );
                  }
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(products[i].nameAr),
                      onTap: () => Navigator.of(context).pop(products[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
