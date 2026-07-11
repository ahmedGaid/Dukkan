import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/areas/entities/area.dart';
import '../../../domain/areas/usecases/get_areas.dart';
import '../../../domain/notifications/repositories/notification_repository.dart';
import '../../../domain/notifications/usecases/notify_order_event.dart';
import '../../../domain/order/entities/address.dart';
import '../../../domain/order/entities/order_item.dart';
import '../../../domain/order/usecases/place_order.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/price_tag.dart';
import '../../widgets/common/skeletons.dart';
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
  late Future<List<Area>> _areasFuture = sl<GetAreas>()();
  String? _areaId;
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
          areaId: _areaId,
        ),
      );
      _notifyShopOwner(order.id);
      if (!mounted) return;
      context.read<CartBloc>().add(const CartCleared());
      context.go('/order-placed', extra: order);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, AppLocalizations.of(context)!.checkoutErrorBody);
    }
  }

  /// Fire-and-forget push to the shop owner. Push text is decided at send
  /// time and we don't track each user's language, so every push is
  /// bilingual — see `NotificationRemoteDataSource` doc.
  void _notifyShopOwner(String orderId) {
    final lAr = lookupAppLocalizations(const Locale('ar'));
    final lEn = lookupAppLocalizations(const Locale('en'));
    unawaited(sl<NotifyOrderEvent>()(
      orderId: orderId,
      type: NotificationEventType.newOrder,
      title: '${lAr.notifyNewOrderTitle} / ${lEn.notifyNewOrderTitle}',
      body: '${lAr.notifyNewOrderBody} / ${lEn.notifyNewOrderBody}',
    ));
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
            _AreaField(
              future: _areasFuture,
              areaId: _areaId,
              onChanged: (v) => setState(() => _areaId = v),
              onRetry: () => setState(() => _areasFuture = sl<GetAreas>()()),
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

/// Delivery-area dropdown (M8) — loads the fixed area list once per form open
/// (matches `_TaxonomyFields`'s no-bloc `FutureBuilder` style). Required for
/// every new order so it carries through to a driver's assignment (M9).
class _AreaField extends StatelessWidget {
  const _AreaField({
    required this.future,
    required this.areaId,
    required this.onChanged,
    required this.onRetry,
  });

  final Future<List<Area>> future;
  final String? areaId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return FutureBuilder<List<Area>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: ListShimmer(count: 1, itemHeight: 56),
          );
        }
        if (snapshot.hasError) {
          final scheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: scheme.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.areasErrorBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
                ],
              ),
            ),
          );
        }

        final areas = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: DropdownButtonFormField<String>(
            initialValue: areaId,
            decoration: InputDecoration(
              labelText: l10n.fieldArea,
              prefixIcon: const Icon(Icons.map_outlined),
            ),
            items: [
              for (final a in areas)
                DropdownMenuItem(
                  value: a.id,
                  child: Text(isArabic ? a.nameAr : a.nameEn),
                ),
            ],
            onChanged: onChanged,
            validator: (v) => v == null ? l10n.areaRequired : null,
          ),
        );
      },
    );
  }
}
