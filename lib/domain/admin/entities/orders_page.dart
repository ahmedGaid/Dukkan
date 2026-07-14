import 'package:equatable/equatable.dart';

import '../../order/entities/order.dart';

/// One page of the console order board (FC10). Mirrors `UsersPage` —
/// value-based pagination (the cursor is the last row's `createdAt`, not a
/// `DocumentSnapshot`), so no Firestore type crosses into `domain/`.
class OrdersPage extends Equatable {
  const OrdersPage({required this.orders, required this.hasMore});

  final List<Order> orders;
  final bool hasMore;

  @override
  List<Object?> get props => [orders, hasMore];
}
