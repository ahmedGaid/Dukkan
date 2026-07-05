import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../core/di/injector.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../domain/auth/entities/app_user.dart';
import '../../../domain/auth/entities/user_role.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/common/app_card.dart';

/// The account tab (P2a) — shared by the customer and owner shells. Profile
/// header, the two persisted preferences (language + appearance), an about
/// row, and the single logout entry (with a confirm dialog). Nav after logout
/// is handled by the auth-guarded router, not here.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (user != null) _ProfileHeader(user: user),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(l10n.settingsPreferences),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _LanguageSetting(),
                  _SettingDivider(),
                  _ThemeSetting(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(l10n.settingsAbout),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.settingsVersion,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    AppConfig.version,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _LogoutButton(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final name = user.name.trim();
    final initial =
        name.isEmpty ? '؟' : String.fromCharCode(name.runes.first).toUpperCase();
    final roleLabel = user.role == UserRole.owner
        ? l10n.roleBadgeOwner
        : l10n.roleBadgeCustomer;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.16),
              borderRadius: AppRadius.roundAll,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: text.titleLarge?.copyWith(color: scheme.secondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? user.email : name,
                  style: text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _RoleBadge(label: roleLabel),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.16),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  const _SettingDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Divider(height: 1),
      );
}

/// Label above a full-width control — the shared shape for each preference row.
class _SettingBlock extends StatelessWidget {
  const _SettingBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = sl<LocaleController>();
    return _SettingBlock(
      label: l10n.settingsLanguage,
      child: ValueListenableBuilder<Locale>(
        valueListenable: controller,
        builder: (context, locale, _) => SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 'ar', label: Text(l10n.settingsLangArabic)),
            ButtonSegment(value: 'en', label: Text(l10n.settingsLangEnglish)),
          ],
          selected: {locale.languageCode},
          onSelectionChanged: (s) => controller.setLocale(Locale(s.first)),
        ),
      ),
    );
  }
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = sl<ThemeController>();
    return _SettingBlock(
      label: l10n.settingsAppearance,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: controller,
        builder: (context, mode, _) => SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(l10n.settingsThemeLight),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(l10n.settingsThemeDark),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(l10n.settingsThemeSystem),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (s) => controller.setMode(s.first),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context),
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: Text(l10n.actionLogout),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLogoutConfirmTitle),
        content: Text(l10n.settingsLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionLogout),
          ),
        ],
      ),
    );
    if (confirmed == true) authBloc.add(const AuthLogoutRequested());
  }
}
