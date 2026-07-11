import 'package:equatable/equatable.dart';

/// An owner-curated grouping of products under one shop (M6), e.g. "Offers".
/// Lives at `/shops/{shopId}/collections/{id}` — deleting one does NOT touch
/// products; stale `collectionIds` entries are just ignored at render time.
class ShopCollection extends Equatable {
  const ShopCollection({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.sort,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int sort;

  @override
  List<Object?> get props => [id, nameAr, nameEn, sort];
}
