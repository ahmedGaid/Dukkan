import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/permissions.dart';
import '../../../../domain/shop/entities/shop.dart';
import '../../../../domain/storage/entities/storage_folder.dart';
import '../../../../domain/storage/usecases/upload_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/shimmer_image.dart';
import '../../../widgets/common/status_chip.dart';
import '../bloc/shop_detail_bloc.dart';

/// The Founder Console shop detail page (`/console/shops/:id`, FC7). Always
/// opened from the board row's `extra: Shop` (mirrors `UserDetailPage` — no
/// get-by-id-without-seed on this route).
class ShopDetailPage extends StatelessWidget {
  const ShopDetailPage({super.key, required this.seed});

  final Shop? seed;

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
                Text(l10n.shopDetailMissingSeed, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => context.go('/console/shops'),
                  child: Text(l10n.userDetailBackToList),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final actorUid = context.read<AuthBloc>().state.user?.uid ?? '';
    return BlocProvider(
      create: (_) => sl<ShopDetailBloc>(param1: seed, param2: actorUid),
      child: const _ShopDetailView(),
    );
  }
}

class _ShopDetailView extends StatelessWidget {
  const _ShopDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<ShopDetailBloc, ShopDetailState>(
      listenWhen: (a, b) => a.actionBusy && !b.actionBusy,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.actionError != null) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.userDetailActionFailed)));
        } else {
          messenger.showSnackBar(SnackBar(content: Text(l10n.userDetailActionOk)));
          if (state.transferOldOwnerStillOwnerRole) {
            messenger.showSnackBar(SnackBar(content: Text(l10n.shopTransferOldOwnerHint)));
          }
        }
      },
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _Header(),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: BlocBuilder<ShopDetailBloc, ShopDetailState>(
                builder: (context, state) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _EditableFieldsCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _TransferCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _DangerCard(state: state),
                      const SizedBox(height: AppSpacing.md),
                      _ShortcutsCard(shopId: state.shop.id),
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
    final shop = context.select((ShopDetailBloc b) => b.state.shop);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/console/shops'),
          ),
          Expanded(
            child: Text(
              isArabic ? shop.nameAr : shop.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (context.select((ShopDetailBloc b) => b.state.actionBusy))
            const Padding(
              padding: EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Status + curation
// ─────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final ShopDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = state.shop;
    final busy = state.actionBusy;
    final bloc = context.read<ShopDetailBloc>();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.shopDetailStatusTitle, style: Theme.of(context).textTheme.titleSmall),
              ),
              StatusChip(label: _statusLabel(l10n, shop.status), tone: _statusTone(shop.status)),
              if (shop.deleted) ...[
                const SizedBox(width: AppSpacing.xs),
                StatusChip(label: l10n.shopsStatusDeleted, tone: StatusTone.caution),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (shop.status == 'pending') ...[
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => _confirm(
                            context,
                            l10n.shopDetailConfirmApprove,
                            () => bloc.add(const ShopDetailSetStatusRequested(status: 'active')),
                          ),
                  child: Text(l10n.shopDetailApprove),
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => _rejectDialog(context, bloc),
                  child: Text(l10n.shopDetailReject),
                ),
              ],
              if (shop.status == 'active')
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => _confirm(
                            context,
                            l10n.shopDetailConfirmSuspend,
                            () => bloc.add(const ShopDetailSetStatusRequested(status: 'suspended')),
                          ),
                  child: Text(l10n.shopDetailSuspend),
                ),
              if (shop.status == 'suspended')
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => bloc.add(const ShopDetailSetStatusRequested(status: 'active')),
                  child: Text(l10n.shopDetailUnsuspend),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: shop.isFeatured,
            onChanged: busy ? null : (v) => bloc.add(ShopDetailSetFeaturedRequested(v)),
            title: Text(l10n.shopsFeaturedBadge),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: shop.isVerified,
            onChanged: busy ? null : (v) => bloc.add(ShopDetailSetVerifiedRequested(v)),
            title: Text(l10n.shopsVerifiedBadge),
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

  Future<void> _rejectDialog(BuildContext context, ShopDetailBloc bloc) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.shopDetailReject),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            decoration: InputDecoration(labelText: l10n.shopDetailRejectReasonLabel),
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(ctrl.text.trim());
              }
            },
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (reason != null && reason.isNotEmpty) {
      bloc.add(ShopDetailSetStatusRequested(status: 'suspended', reason: reason));
    }
  }
}

String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
      'pending' => l10n.shopsStatusPending,
      'suspended' => l10n.shopsStatusSuspended,
      _ => l10n.shopsStatusActive,
    };

StatusTone _statusTone(String status) => switch (status) {
      'pending' => StatusTone.caution,
      'suspended' => StatusTone.caution,
      _ => StatusTone.positive,
    };

// ─────────────────────────────────────────────────────────────────────────
// Editable fields
// ─────────────────────────────────────────────────────────────────────────

class _EditableFieldsCard extends StatefulWidget {
  const _EditableFieldsCard({required this.state});

  final ShopDetailState state;

  @override
  State<_EditableFieldsCard> createState() => _EditableFieldsCardState();
}

class _EditableFieldsCardState extends State<_EditableFieldsCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nameAr;
  late final TextEditingController _address;
  late final TextEditingController _hoursNote;
  late bool _isOpen;
  Uint8List? _newLogoBytes;
  String? _newLogoPath;
  bool _uploadingLogo = false;
  String? _shopIdForControllers;

  @override
  void initState() {
    super.initState();
    _resetControllers(widget.state.shop);
  }

  @override
  void didUpdateWidget(covariant _EditableFieldsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset the fields when a mutation reloaded a DIFFERENT shop id (it
    // never does here) or on the very first build — never clobber in-progress
    // typing when this same shop's state updates for an unrelated reason
    // (e.g. a status change while the owner edits the address).
    if (_shopIdForControllers != widget.state.shop.id) {
      _resetControllers(widget.state.shop);
    }
  }

  void _resetControllers(Shop shop) {
    _shopIdForControllers = shop.id;
    _name = TextEditingController(text: shop.name);
    _nameAr = TextEditingController(text: shop.nameAr);
    _address = TextEditingController(text: shop.address);
    _hoursNote = TextEditingController(text: shop.hoursNote ?? '');
    _isOpen = shop.isOpen;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _address.dispose();
    _hoursNote.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newLogoBytes = bytes;
      _newLogoPath = file.path;
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    String? logoUrl = widget.state.shop.logoUrl;
    final bytes = _newLogoBytes;
    if (bytes != null) {
      setState(() => _uploadingLogo = true);
      try {
        logoUrl = await sl<UploadImage>()(
          bytes: bytes,
          contentType: _mimeTypeFor(_newLogoPath!),
          folder: StorageFolder.shopLogos,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _uploadingLogo = false);
        AppSnackBar.error(context, l10n.shopOnboardingLogoErrorBody);
        return;
      }
      if (!mounted) return;
      setState(() => _uploadingLogo = false);
    }
    context.read<ShopDetailBloc>().add(ShopDetailUpdateDetailsRequested(
          name: _name.text.trim(),
          nameAr: _nameAr.text.trim(),
          address: _address.text.trim(),
          isOpen: _isOpen,
          logoUrl: logoUrl,
          hoursNote: _hoursNote.text.trim().isEmpty ? null : _hoursNote.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = widget.state.actionBusy || _uploadingLogo;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shopDetailFieldsTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _pickLogo,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _newLogoBytes != null
                        ? Image.memory(_newLogoBytes!, width: 64, height: 64, fit: BoxFit.cover)
                        : ShimmerImage(url: widget.state.shop.logoUrl, width: 64, height: 64),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: l10n.fieldShopName,
                        controller: _name,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                      ),
                      AppTextField(
                        label: l10n.fieldShopNameAr,
                        controller: _nameAr,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppTextField(
              label: l10n.fieldShopAddress,
              controller: _address,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
            ),
            AppTextField(label: l10n.shopDetailHoursNoteLabel, controller: _hoursNote),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isOpen,
              onChanged: (v) => setState(() => _isOpen = v),
              title: Text(l10n.shopOnboardingOpenLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: busy ? null : _save,
              child: busy
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Transfer + danger zone
// ─────────────────────────────────────────────────────────────────────────

class _TransferCard extends StatefulWidget {
  const _TransferCard({required this.state});

  final ShopDetailState state;

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canTransfer = context.select((AuthBloc b) => b.state.can(Permissions.shopsTransfer));
    if (!canTransfer) return const SizedBox.shrink();

    final busy = widget.state.actionBusy;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shopDetailTransferTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.shopDetailTransferHint,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(label: l10n.shopDetailNewOwnerUidLabel, controller: _ctrl),
          OutlinedButton(
            onPressed: busy || _ctrl.text.trim().isEmpty
                ? null
                : () => _confirmTransfer(context),
            child: Text(l10n.shopDetailTransferAction),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmTransfer(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final newOwnerUid = _ctrl.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.shopDetailConfirmTransfer(newOwnerUid)),
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
    if (confirmed == true && context.mounted) {
      context.read<ShopDetailBloc>().add(ShopDetailTransferRequested(newOwnerUid));
    }
  }
}

class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.state});

  final ShopDetailState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = state.shop;
    final busy = state.actionBusy;
    final bloc = context.read<ShopDetailBloc>();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(l10n.shopDetailDangerTitle, style: Theme.of(context).textTheme.titleSmall),
          ),
          if (!shop.deleted)
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => _confirm(
                        context,
                        l10n.shopDetailConfirmSoftDelete,
                        () => bloc.add(const ShopDetailSoftDeleteRequested()),
                      ),
              child: Text(l10n.userDetailSoftDelete),
            )
          else
            FilledButton(
              onPressed: busy ? null : () => bloc.add(const ShopDetailRestoreRequested()),
              child: Text(l10n.userDetailRestore),
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
}

// ─────────────────────────────────────────────────────────────────────────
// Shortcuts
// ─────────────────────────────────────────────────────────────────────────

class _ShortcutsCard extends StatelessWidget {
  const _ShortcutsCard({required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shopDetailShortcutsTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: Text(l10n.catalogCollectionsEntry),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/catalog/collections', extra: shopId),
          ),
          // Products management route lands in Session 8 (FILE_08) — hidden
          // until then rather than linking somewhere that doesn't exist yet.
        ],
      ),
    );
  }
}
