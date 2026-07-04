import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/auth/entities/user_role.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shell/home_shell.dart';

/// Post-auth landing, split by role: a customer gets the marketplace shell
/// (C2a); an owner still gets a warm placeholder until the owner desk (S3).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isOwner =
        context.watch<AuthBloc>().state.user?.role == UserRole.owner;
    return isOwner ? const _OwnerPlaceholder() : const HomeShell();
  }
}

/// Kept from the F3 landing — the owner desk (order management) replaces this
/// in S3. A designed "coming soon", never a blank screen.
class _OwnerPlaceholder extends StatelessWidget {
  const _OwnerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    final user = state.user;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? l10n.appName : l10n.homeGreeting(user.name)),
        actions: [
          IconButton(
            tooltip: l10n.actionLogout,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.roundAll,
                ),
                child: Text(
                  l10n.roleBadgeOwner,
                  style: text.labelLarge?.copyWith(color: scheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Icon(
                Icons.storefront_outlined,
                size: 56,
                color: scheme.secondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.homeOwnerPlaceholder,
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
