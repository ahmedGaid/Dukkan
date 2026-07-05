import 'package:equatable/equatable.dart';

/// A دكان (shop) listed in the marketplace. `categories` drives the home
/// category grid filter; `isOpen` is toggled by the owner (S1) and gates
/// checkout in C3 (no orders to a closed shop).
class Shop extends Equatable {
  const Shop({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.nameAr,
    required this.address,
    required this.isOpen,
    required this.categories,
    this.logoUrl,
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String nameAr;
  final String? logoUrl;
  final String address;
  final bool isOpen;
  final List<String> categories;

  /// Sum of every 1-5 star rating ever submitted (P3). Stored as an int sum
  /// rather than a running double average — same "no float money" discipline
  /// applied to ratings, average is derived at read time.
  final int ratingSum;
  final int ratingCount;

  /// Null until the first rating lands — callers show nothing rather than
  /// "0.0" for an unrated shop.
  double? get averageRating => ratingCount == 0 ? null : ratingSum / ratingCount;

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        name,
        nameAr,
        logoUrl,
        address,
        isOpen,
        categories,
        ratingSum,
        ratingCount,
      ];
}
