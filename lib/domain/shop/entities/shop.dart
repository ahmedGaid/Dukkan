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
    this.status = 'active',
    this.isFeatured = false,
    this.isVerified = false,
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
    this.hoursNote,
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

  /// `pending` | `active` | `suspended` (Founder Console FC7). Missing on any
  /// doc created before this field existed → treated as `active` at parse
  /// time, so every live shop stays valid without a migration.
  final String status;

  /// Founder Console curation flags (FC7) — customer-facing badges only, no
  /// behavior gate.
  final bool isFeatured;
  final bool isVerified;

  /// Soft delete (FC7) — reversible, never a real Firestore delete.
  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// Optional free-text working-hours note (ar), shown under the open/closed
  /// chip. A full per-day schedule is deliberately deferred past FC7.
  final String? hoursNote;

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
        status,
        isFeatured,
        isVerified,
        deleted,
        deletedAt,
        deletedBy,
        hoursNote,
      ];
}
