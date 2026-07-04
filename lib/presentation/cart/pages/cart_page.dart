import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/cart/entities/cart_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/quantity_stepper.dart';
import '../../widgets/common/shimmer_image.dart';
import '../bloc/cart_bloc.dart';

/// The single-shop basket: a line per product, a stepper on each, and a
/// pinned total + checkout bar. Every state (empty / stocked) is designed.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cartTitle),
        actions: [
          BlocSelector<CartBloc, CartState, bool>(
            selector: (state) => state.isEmpty,
            builder: (context, isEmpty) => isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.cartClearAll,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmClear(context),
                  ),
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) =>
            state.isEmpty ? const _CartEmpty() : _CartContent(state: state),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cartClearConfirmTitle),
        content: Text(l10n.cartClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionClear),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CartBloc>().add(const CartCleared());
    }
  }
}

class _CartEmpty extends StatelessWidget {
  const _CartEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: l10n.cartEmptyTitle,
      message: l10n.cartEmptyBody,
      actionLabel: l10n.cartEmptyAction,
      onAction: () => Navigator.of(context).maybePop(),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _CartLine(item: state.items[i]),
          ),
        ),
        _CartSummaryBar(totalMinor: state.totalMinor),
      ],
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? item.nameAr : item.name;
    final bloc = context.read<CartBloc>();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          ShimmerImage(
            url: item.imageUrl,
            width: 60,
            height: 60,
            radius: AppRadius.mdAll,
            fallbackIcon: Icons.shopping_basket_outlined,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                PriceTag(item.subtotalMinor),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          QuantityStepper(
            qty: item.quantity,
            onIncrement: () =>
                bloc.add(CartItemIncremented(item.productId)),
            onDecrement: () =>
                bloc.add(CartItemDecremented(item.productId)),
          ),
        ],
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar({required this.totalMinor});

  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.cartTotal, style: Theme.of(context).textTheme.bodySmall),
                    PriceTag(
                      totalMinor,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 160,
                child: AppButton(
                  label: l10n.actionCheckout,
                  onPressed: () => context.push('/checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
