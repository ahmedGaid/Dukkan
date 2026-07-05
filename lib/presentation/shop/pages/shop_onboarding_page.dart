import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/shop/usecases/create_shop.dart';
import '../../../domain/storage/entities/storage_folder.dart';
import '../../../domain/storage/usecases/upload_image.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';

/// Owner-only, one-time setup — the router (S1b gate in `AppRouter._redirect`)
/// sends any owner without a `/shops` doc here before `/home`. A single
/// one-shot write, so this calls the use cases directly with no bloc (matches
/// `CheckoutPage`'s submit pattern).
class ShopOnboardingPage extends StatefulWidget {
  const ShopOnboardingPage({super.key});

  @override
  State<ShopOnboardingPage> createState() => _ShopOnboardingPageState();
}

class _ShopOnboardingPageState extends State<ShopOnboardingPage> {
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
    _name.dispose();
    _nameAr.dispose();
    _address.dispose();
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
      _logoBytes = bytes;
      _logoPath = file.path;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    final l10n = AppLocalizations.of(context)!;
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
      await sl<CreateShop>()(
        ownerUid: user.uid,
        name: _name.text.trim(),
        nameAr: _nameAr.text.trim(),
        address: _address.text.trim(),
        logoUrl: logoUrl,
        isOpen: _isOpen,
      );
      if (!mounted) return;
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, l10n.shopOnboardingErrorBody);
    }
  }

  String _mimeTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopOnboardingTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.shopOnboardingSubtitle,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium
                      ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: _LogoPicker(
                    bytes: _logoBytes,
                    onTap: _pickLogo,
                    label: l10n.shopOnboardingLogoLabel,
                    hint: l10n.shopOnboardingLogoHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.fieldShopName,
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.storefront_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                ),
                AppTextField(
                  label: l10n.fieldShopNameAr,
                  controller: _nameAr,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.storefront_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                ),
                AppTextField(
                  label: l10n.fieldShopAddress,
                  controller: _address,
                  textInputAction: TextInputAction.done,
                  prefixIcon: Icons.location_on_outlined,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isOpen,
                  onChanged: (v) => setState(() => _isOpen = v),
                  title: Text(l10n.shopOnboardingOpenLabel, style: text.bodyMedium),
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
        ),
      ),
    );
  }
}

/// Round logo picker — mint-tinted placeholder with a camera icon until a
/// photo is chosen, then shows the picked image. Optional (a shop can launch
/// logo-less; S2's catalog manager doesn't block on it either).
class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.bytes,
    required this.onTap,
    required this.label,
    required this.hint,
  });

  final Uint8List? bytes;
  final VoidCallback onTap;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundAll,
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outline),
              image: bytes == null
                  ? null
                  : DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover),
            ),
            child: bytes == null
                ? Icon(Icons.add_a_photo_outlined, color: scheme.secondary, size: 28)
                : null,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(bytes == null ? hint : label, style: text.labelLarge),
        ],
      ),
    );
  }
}
