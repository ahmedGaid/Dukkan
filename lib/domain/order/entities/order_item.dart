import 'package:equatable/equatable.dart';

/// A snapshot of one product as it was ordered — decoupled from the live
/// `Product` so later price/name changes never alter past orders.
class OrderItem extends Equatable {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.nameAr,
    required this.priceMinor,
    required this.quantity,
  });

  final String productId;
  final String name;
  final String nameAr;
  final int priceMinor;
  final int quantity;

  int get subtotalMinor => priceMinor * quantity;

  @override
  List<Object?> get props =>
      [productId, name, nameAr, priceMinor, quantity];
}
