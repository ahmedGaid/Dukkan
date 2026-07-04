part of 'cart_bloc.dart';

/// One shop's basket (v1 lock: one cart per shop). `shopId` is null only when
/// the cart is empty.
class CartState extends Equatable {
  const CartState({this.shopId, this.items = const []});

  final String? shopId;
  final List<CartItem> items;

  int get totalMinor =>
      items.fold(0, (sum, item) => sum + item.subtotalMinor);

  /// Distinct products in the cart — the badge count (Shoppy lesson: never
  /// sum quantities).
  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;

  int quantityOf(String productId) {
    for (final item in items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  CartState copyWith({String? shopId, List<CartItem>? items}) => CartState(
        shopId: shopId ?? this.shopId,
        items: items ?? this.items,
      );

  @override
  List<Object?> get props => [shopId, items];
}
