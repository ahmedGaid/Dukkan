import 'package:equatable/equatable.dart';

/// A line in the customer's cart. Carries a denormalized product snapshot
/// (name/price/image) so the cart screen (C3) never re-fetches the product —
/// prices are re-validated against the live product only at checkout.
class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.shopId,
    required this.name,
    required this.nameAr,
    required this.priceMinor,
    required this.quantity,
    this.imageUrl,
  });

  final String productId;
  final String shopId;
  final String name;
  final String nameAr;
  final String? imageUrl;
  final int priceMinor;
  final int quantity;

  int get subtotalMinor => priceMinor * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        shopId: shopId,
        name: name,
        nameAr: nameAr,
        imageUrl: imageUrl,
        priceMinor: priceMinor,
        quantity: quantity ?? this.quantity,
      );

  @override
  List<Object?> get props =>
      [productId, shopId, name, nameAr, imageUrl, priceMinor, quantity];
}
