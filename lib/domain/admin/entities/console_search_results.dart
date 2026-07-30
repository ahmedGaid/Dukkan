import 'package:equatable/equatable.dart';

import '../../areas/entities/area.dart';
import '../../driver/entities/driver.dart';
import '../../order/entities/order.dart';
import '../../product/entities/product.dart';
import '../../shop/entities/shop.dart';
import '../../taxonomy/entities/category.dart';
import 'managed_user.dart';

/// Grouped hits for the console global search (FC17, Ctrl+K). Each group is
/// independently populated — a permission the caller lacks stays an empty
/// list rather than throwing, so one denied group never blanks the rest (the
/// parallel lookups in `ConsoleSearchBloc` already collapse per-group
/// failures to empty the same way).
class ConsoleSearchResults extends Equatable {
  const ConsoleSearchResults({
    this.order,
    this.users = const [],
    this.shops = const [],
    this.products = const [],
    this.drivers = const [],
    this.areas = const [],
    this.categories = const [],
  });

  final Order? order;
  final List<ManagedUser> users;
  final List<Shop> shops;
  final List<Product> products;
  final List<Driver> drivers;
  final List<Area> areas;
  final List<Category> categories;

  bool get isEmpty =>
      order == null &&
      users.isEmpty &&
      shops.isEmpty &&
      products.isEmpty &&
      drivers.isEmpty &&
      areas.isEmpty &&
      categories.isEmpty;

  @override
  List<Object?> get props => [order, users, shops, products, drivers, areas, categories];
}
