import '../../promos/entities/promo_banner.dart';
import '../repositories/admin_promos_repository.dart';

class CreateBanner {
  const CreateBanner(this._repository);

  final AdminPromosRepository _repository;

  Future<void> call({
    required String imageUrl,
    required BannerTargetType targetType,
    String? targetId,
    String? targetShopId,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      _repository.createBanner(
        imageUrl: imageUrl,
        targetType: targetType,
        targetId: targetId,
        targetShopId: targetShopId,
        startsAt: startsAt,
        endsAt: endsAt,
      );
}
