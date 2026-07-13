import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/admin/usecases/create_shop_as_staff.dart';
import '../../../../domain/admin/usecases/get_user_by_email.dart';
import '../../../../domain/auth/entities/user_role.dart';
import '../../../../domain/storage/entities/storage_folder.dart';
import '../../../../domain/storage/usecases/upload_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_snackbar.dart';
import '../../../widgets/common/app_text_field.dart';
import '../../../widgets/common/status_chip.dart';

/// Console "create shop for owner" form (`/console/shops/new`, FC7, perm
/// `shops.update`). An owner picker (exact-email lookup, must be role
/// `owner`) followed by the same fields as self-serve onboarding — the
/// console-created shop lands `active` immediately (staff already vetted the
/// owner), unlike onboarding which always lands `pending`.
class CreateShopPage extends StatefulWidget {
  const CreateShopPage({super.key});

  @override
  State<CreateShopPage> createState() => _CreateShopPageState();
}

class _CreateShopPageState extends State<CreateShopPage> {
  final _ownerEmailCtrl = TextEditingController();
  ManagedUser? _owner;
  bool _searchingOwner = false;
  String? _ownerError;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameAr = TextEditingController();
  final _address = TextEditingController();
  bool _isOpen = true;
  Uint8List? _logoBytes;
  String? _logoPath;
  bool _submitting = false;

  @override
  void dispose() {
    _ownerEmailCtrl.dispose();
    _name.dispose();
    _nameAr.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _searchOwner() async {
    final email = _ownerEmailCtrl.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (email.isEmpty) return;
    setState(() {
      _searchingOwner = true;
      _owner = null;
      _ownerError = null;
    });
    try {
      final user = await sl<GetUserByEmail>()(email);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _searchingOwner = false;
          _ownerError = l10n.shopCreateOwnerNotFound;
        });
      } else if (user.role != UserRole.owner) {
        setState(() {
          _searchingOwner = false;
          _ownerError = l10n.shopCreateOwnerNotOwnerRole;
        });
      } else {
        setState(() {
          _searchingOwner = false;
          _owner = user;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchingOwner = false;
        _ownerError = l10n.shopCreateOwnerNotFound;
      });
    }
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
      _logoBytes = bytes;
      _logoPath = file.path;
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
    final owner = _owner;
    final l10n = AppLocalizations.of(context)!;
    if (owner == null) {
      AppSnackBar.error(context, l10n.shopCreateOwnerRequired);
      return;
    }
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    String? logoUrl;
    final bytes = _logoBytes;
    if (bytes != null) {
      try {
        logoUrl = await sl<UploadImage>()(
          bytes: bytes,
          contentType: _mimeTypeFor(_logoPath!),
          folder: StorageFolder.shopLogos,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _submitting = false);
        AppSnackBar.error(context, l10n.shopOnboardingLogoErrorBody);
        return;
      }
    }

    try {
      await sl<CreateShopAsStaff>()(
        ownerUid: owner.uid,
        name: _name.text.trim(),
        nameAr: _nameAr.text.trim(),
        address: _address.text.trim(),
        logoUrl: logoUrl,
        isOpen: _isOpen,
      );
      if (!mounted) return;
      context.go('/console/shops');
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, l10n.shopOnboardingErrorBody);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/console/shops'),
                ),
                Text(l10n.shopsBoardCreateAction, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.shopCreateOwnerTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ownerEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.shopCreateOwnerEmailLabel,
                            border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
                          ),
                          onSubmitted: (_) => _searchOwner(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: _searchingOwner ? null : _searchOwner,
                        child: _searchingOwner
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(l10n.usersSearchLabel),
                      ),
                    ],
                  ),
                  if (_owner != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    StatusChip(label: '${_owner!.name} — ${_owner!.email}', tone: StatusTone.positive),
                  ],
                  if (_ownerError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_ownerError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: l10n.fieldShopName,
                          controller: _name,
                          prefixIcon: Icons.storefront_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                        ),
                        AppTextField(
                          label: l10n.fieldShopNameAr,
                          controller: _nameAr,
                          prefixIcon: Icons.storefront_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                        ),
                        AppTextField(
                          label: l10n.fieldShopAddress,
                          controller: _address,
                          prefixIcon: Icons.location_on_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _isOpen,
                          onChanged: (v) => setState(() => _isOpen = v),
                          title: Text(l10n.shopOnboardingOpenLabel),
                        ),
                        OutlinedButton(
                          onPressed: _pickLogo,
                          child: Text(_logoBytes == null
                              ? l10n.shopOnboardingLogoHint
                              : l10n.shopOnboardingLogoLabel),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: l10n.actionCreateShop,
                          loading: _submitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
