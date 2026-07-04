import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/auth/entities/user_role.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';

/// Post-auth landing. A real customer home (C2) / owner desk (S3) replaces the
/// body later — for now it confirms who's signed in, their role, and shows a
/// warm "coming soon" placeholder instead of a blank screen.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<AuthBloc>().state;
    final user = state.user;
    final isOwner = user?.role == UserRole.owner;
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
                  isOwner ? l10n.roleBadgeOwner : l10n.roleBadgeCustomer,
                  style: text.labelLarge?.copyWith(color: scheme.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Icon(
                isOwner
                    ? Icons.storefront_outlined
                    : Icons.shopping_basket_outlined,
                size: 56,
                color: scheme.secondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isOwner
                    ? l10n.homeOwnerPlaceholder
                    : l10n.homeCustomerPlaceholder,
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
