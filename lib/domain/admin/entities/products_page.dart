import 'package:equatable/equatable.dart';

import '../../product/entities/product.dart';

/// One page of the console product board. Mirrors `UsersPage` — value-based
/// pagination (the cursor is the last row's `id`, not a `DocumentSnapshot`),
/// so no Firestore type crosses into `domain/`.
class ProductsPage extends Equatable {
  const ProductsPage({required this.products, required this.hasMore});

  final List<Product> products;
  final bool hasMore;

  @override
  List<Object?> get props => [products, hasMore];
}
