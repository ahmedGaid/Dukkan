import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/cart/entities/cart_item.dart';
import '../../../domain/product/entities/product.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// App-lifetime basket (registered as a lazy singleton — one cart survives
/// across Home/Shop/Search/Cart/Checkout navigation). Pure in-memory state;
/// no repository, since there is nothing to sync until [PlaceOrder] runs at
/// checkout. Shop-switch confirmation is a UI concern (`cart_actions.dart`)
/// — by the time [CartItemAdded] reaches this bloc, the switch is approved.
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemIncremented>(_onItemIncremented);
    on<CartItemDecremented>(_onItemDecremented);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final product = event.product;
    final sameShop = state.shopId == null || state.shopId == product.shopId;
    final items = sameShop ? [...state.items] : <CartItem>[];

    final index = items.indexWhere((i) => i.productId == product.id);
    if (index == -1) {
      items.add(CartItem(
        productId: product.id,
        shopId: product.shopId,
        name: product.name,
        nameAr: product.nameAr,
        imageUrl: product.imageUrl,
        priceMinor: product.priceMinor,
        quantity: event.quantity,
      ));
    } else {
      items[index] =
          items[index].copyWith(quantity: items[index].quantity + event.quantity);
    }

    emit(CartState(shopId: product.shopId, items: items));
  }

  void _onItemIncremented(CartItemIncremented event, Emitter<CartState> emit) {
    emit(state.copyWith(items: _mapQuantity(event.productId, 1)));
  }

  void _onItemDecremented(CartItemDecremented event, Emitter<CartState> emit) {
    if (state.quantityOf(event.productId) <= 1) {
      _remove(event.productId, emit);
      return;
    }
    emit(state.copyWith(items: _mapQuantity(event.productId, -1)));
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    _remove(event.productId, emit);
  }

  void _onCleared(CartCleared event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  List<CartItem> _mapQuantity(String productId, int delta) => state.items
      .map((i) => i.productId == productId
          ? i.copyWith(quantity: i.quantity + delta)
          : i)
      .toList();

  void _remove(String productId, Emitter<CartState> emit) {
    final items = state.items.where((i) => i.productId != productId).toList();
    emit(items.isEmpty ? const CartState() : state.copyWith(items: items));
  }
}
