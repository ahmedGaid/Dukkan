import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/order/entities/order.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/price_tag.dart';

/// The COD confirmation screen after [PlaceOrder] succeeds — a designed
/// celebratory state, not a bare pop back to the cart. Live order tracking
/// lands in C4; today this confirms the order and sends the customer back
/// to browsing.
class OrderPlacedPage extends StatelessWidget {
  const OrderPlacedPage({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: AppRadius.roundAll,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.orderPlacedTitle,
                style: text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.orderPlacedBody,
                style: text.bodyMedium
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.64)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              PriceTag(
                order.totalMinor,
                style: text.titleLarge
                    ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l10n.actionBackHome,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
