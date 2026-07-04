import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/usecases/place_order.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/price_tag.dart';
import '../bloc/cart_bloc.dart';

/// Manual-entry checkout (maps deferred past v1) → COD confirm → places the
/// order and clears the cart. The shop id comes from the cart itself — every
/// line already belongs to one shop (v1 lock: one cart per shop).
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(CartState cart) async {
    if (_submitting || cart.isEmpty || cart.shopId == null) return;
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      final items = cart.items
          .map((i) => OrderItem(
                productId: i.productId,
                name: i.name,
                nameAr: i.nameAr,
                priceMinor: i.priceMinor,
                quantity: i.quantity,
              ))
          .toList();
      final notes = _notesController.text.trim();
      final order = await sl<PlaceOrder>()(
        shopId: cart.shopId!,
        customerUid: user.uid,
        items: items,
        totalMinor: cart.totalMinor,
        deliveryAddress: Address(
          line1: _addressController.text.trim(),
          city: _cityController.text.trim(),
          notes: notes.isEmpty ? null : notes,
        ),
      );
      if (!mounted) return;
      context.read<CartBloc>().add(const CartCleared());
      context.go('/order-placed', extra: order);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, AppLocalizations.of(context)!.checkoutErrorBody);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.watch<CartBloc>().state;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Text(l10n.checkoutAddressSection, style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: l10n.fieldAddressLine,
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
            ),
            AppTextField(
              label: l10n.fieldCity,
              controller: _cityController,
              prefixIcon: Icons.location_city_outlined,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.validateRequired : null,
            ),
            AppTextField(
              label: l10n.fieldNotesOptional,
              controller: _notesController,
              prefixIcon: Icons.edit_note_outlined,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.checkoutSummary, style: text.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _SummaryCard(cart: cart),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.actionPlaceOrder,
              loading: _submitting,
              onPressed: cart.isEmpty ? null : () => _submit(cart),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: scheme.surface, borderRadius: AppRadius.lgAll),
      child: Column(
        children: [
          for (final item in cart.items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${isArabic ? item.nameAr : item.name} × ${item.quantity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                ),
                PriceTag(item.subtotalMinor),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(l10n.cartTotal, style: text.titleSmall),
              ),
              PriceTag(
                cart.totalMinor,
                style: text.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.codLabel,
                style: text.bodySmall
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
