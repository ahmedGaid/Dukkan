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
  });

  final String id;
  final String ownerUid;
  final String name;
  final String nameAr;
  final String? logoUrl;
  final String address;
  final bool isOpen;
  final List<String> categories;

  @override
  List<Object?> get props =>
      [id, ownerUid, name, nameAr, logoUrl, address, isOpen, categories];
}
