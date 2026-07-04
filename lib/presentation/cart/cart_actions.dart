import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/product/entities/product.dart';
import '../../l10n/app_localizations.dart';
import 'bloc/cart_bloc.dart';

/// Adds [product] to the cart. If the cart already holds items from a
/// different shop, confirms with the customer first — the v1 "one cart per
/// shop" rule (roadmap lock) means adding here would otherwise silently wipe
/// the other shop's items. Returns whether the add happened (false if the
/// customer cancelled the switch), so callers can decide whether to show
/// further feedback.
Future<bool> addToCart(
  BuildContext context,
  Product product, {
  int quantity = 1,
}) async {
  final cartBloc = context.read<CartBloc>();
  final current = cartBloc.state;
  final switchingShop =
      current.shopId != null && current.shopId != product.shopId;

  if (switchingShop) {
    final confirmed = await _confirmSwitchShop(context);
    if (confirmed != true) return false;
  }

  cartBloc.add(CartItemAdded(product: product, quantity: quantity));
  return true;
}

Future<bool?> _confirmSwitchShop(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.cartSwitchShopTitle),
      content: Text(l10n.cartSwitchShopBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.actionClearAndAdd),
        ),
      ],
    ),
  );
}
