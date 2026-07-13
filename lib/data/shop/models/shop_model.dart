import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/shop/entities/shop.dart';

class ShopModel extends Shop {
  const ShopModel({
    required super.id,
    required super.ownerUid,
    required super.name,
    required super.nameAr,
    required super.address,
    required super.isOpen,
    required super.categories,
    super.logoUrl,
    super.ratingSum,
    super.ratingCount,
    super.status,
    super.isFeatured,
    super.isVerified,
    super.deleted,
    super.deletedAt,
    super.deletedBy,
    super.hoursNote,
  });

  /// `deletedAt` is a real Firestore `Timestamp` (client `serverTimestamp()`
  /// and the Worker's `fsTimestamp` both write the same wire type — see
  /// `ManagedUserModel`). Every other new field is missing on any doc
  /// created before FC7, defaulting to the pre-FC7 behavior (active,
  /// not featured/verified, not deleted).
  factory ShopModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ShopModel(
      id: id,
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      nameAr: data['nameAr'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      address: data['address'] as String? ?? '',
      isOpen: data['isOpen'] as bool? ?? false,
      categories: List<String>.from(data['categories'] as List? ?? const []),
      ratingSum: (data['ratingSum'] as num?)?.toInt() ?? 0,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      status: (data['status'] as String?) ?? 'active',
      isFeatured: data['isFeatured'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      deleted: data['deleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
      hoursNote: data['hoursNote'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerUid': ownerUid,
        'name': name,
        'nameAr': nameAr,
        if (logoUrl != null) 'logoUrl': logoUrl,
        'address': address,
        'isOpen': isOpen,
        'categories': categories,
        'ratingSum': ratingSum,
        'ratingCount': ratingCount,
        'status': status,
        'isFeatured': isFeatured,
        'isVerified': isVerified,
        'deleted': deleted,
        if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
        if (deletedBy != null) 'deletedBy': deletedBy,
        if (hoursNote != null) 'hoursNote': hoursNote,
      };

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        id: json['id'] as String,
        ownerUid: json['ownerUid'] as String,
        name: json['name'] as String,
        nameAr: json['nameAr'] as String,
        logoUrl: json['logoUrl'] as String?,
        address: json['address'] as String,
        isOpen: json['isOpen'] as bool,
        categories: List<String>.from(json['categories'] as List),
        ratingSum: (json['ratingSum'] as num?)?.toInt() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        status: (json['status'] as String?) ?? 'active',
        isFeatured: json['isFeatured'] as bool? ?? false,
        isVerified: json['isVerified'] as bool? ?? false,
        deleted: json['deleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String),
        deletedBy: json['deletedBy'] as String?,
        hoursNote: json['hoursNote'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'name': name,
        'nameAr': nameAr,
        if (logoUrl != null) 'logoUrl': logoUrl,
        'address': address,
        'isOpen': isOpen,
        'categories': categories,
        'ratingSum': ratingSum,
        'ratingCount': ratingCount,
        'status': status,
        'isFeatured': isFeatured,
        'isVerified': isVerified,
        'deleted': deleted,
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
        if (deletedBy != null) 'deletedBy': deletedBy,
        if (hoursNote != null) 'hoursNote': hoursNote,
      };
}
