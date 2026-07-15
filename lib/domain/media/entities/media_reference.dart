import 'package:equatable/equatable.dart';

/// One image URL a Firestore doc points to (`shops.logoUrl`,
/// `products.imageUrl`, `drivers.idDocUrl`, `banners.imageUrl`) — the
/// "referenced" side of the media library's unused/broken finders.
/// [docType]/[docId] let the broken finder deep-link to the owning screen.
///
/// [key] is the R2 key the datasource extracted from [url] (stripping
/// `AppConfig.mediaPublicBaseUrl`) — null for a URL that isn't an R2 object
/// at all (e.g. a bundled `assets/…` demo-seed path), which the finders must
/// then ignore rather than flag as broken.
class MediaReference extends Equatable {
  const MediaReference({
    required this.url,
    required this.key,
    required this.docType,
    required this.docId,
  });

  final String url;
  final String? key;
  final String docType; // 'shop' | 'product' | 'driver' | 'banner'
  final String docId;

  @override
  List<Object?> get props => [url, key, docType, docId];
}
