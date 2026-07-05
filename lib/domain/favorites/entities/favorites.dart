import 'package:equatable/equatable.dart';

/// The signed-in customer's saved shops/products. One doc per user
/// (`/users/{uid}` array fields) — small enough for v1 that no pagination or
/// separate collection is needed.
class Favorites extends Equatable {
  const Favorites({required this.shopIds, required this.productIds});

  const Favorites.empty()
      : shopIds = const {},
        productIds = const {};

  final Set<String> shopIds;
  final Set<String> productIds;

  bool hasShop(String shopId) => shopIds.contains(shopId);
  bool hasProduct(String productId) => productIds.contains(productId);

  @override
  List<Object?> get props => [shopIds, productIds];
}
