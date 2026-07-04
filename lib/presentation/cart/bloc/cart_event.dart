part of 'cart_bloc.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Adds [quantity] of [product]. If the cart already holds items from a
/// different shop, the caller (`cart_actions.dart`) must confirm with the
/// customer BEFORE dispatching this — the bloc trusts that decision and
/// simply replaces the basket.
class CartItemAdded extends CartEvent {
  const CartItemAdded({required this.product, this.quantity = 1});

  final Product product;
  final int quantity;

  @override
  List<Object?> get props => [product, quantity];
}

class CartItemIncremented extends CartEvent {
  const CartItemIncremented(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

/// Decrementing a line at quantity 1 removes it (never lets quantity hit 0).
class CartItemDecremented extends CartEvent {
  const CartItemDecremented(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class CartCleared extends CartEvent {
  const CartCleared();
}
