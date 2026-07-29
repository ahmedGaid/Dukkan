part of 'banners_board_bloc.dart';

sealed class BannersBoardEvent extends Equatable {
  const BannersBoardEvent();

  @override
  List<Object?> get props => [];
}

class BannersBoardStarted extends BannersBoardEvent {
  const BannersBoardStarted();
}

class BannersBoardRetryRequested extends BannersBoardEvent {
  const BannersBoardRetryRequested();
}

class BannersBoardActiveToggled extends BannersBoardEvent {
  const BannersBoardActiveToggled(this.id, this.value);

  final String id;
  final bool value;

  @override
  List<Object?> get props => [id, value];
}

/// An up/down tap — swaps the tapped banner's `sort` with its neighbour's.
class BannersBoardMoveRequested extends BannersBoardEvent {
  const BannersBoardMoveRequested(this.bannerId, {required this.up});

  final String bannerId;
  final bool up;

  @override
  List<Object?> get props => [bannerId, up];
}

class BannersBoardCreateRequested extends BannersBoardEvent {
  const BannersBoardCreateRequested({
    required this.imageUrl,
    required this.targetType,
    this.targetId,
    this.targetShopId,
    this.startsAt,
    this.endsAt,
  });

  final String imageUrl;
  final BannerTargetType targetType;
  final String? targetId;
  final String? targetShopId;
  final DateTime? startsAt;
  final DateTime? endsAt;

  @override
  List<Object?> get props =>
      [imageUrl, targetType, targetId, targetShopId, startsAt, endsAt];
}

class BannersBoardUpdateRequested extends BannersBoardEvent {
  const BannersBoardUpdateRequested(this.banner);

  final PromoBanner banner;

  @override
  List<Object?> get props => [banner];
}

class BannersBoardDeleteRequested extends BannersBoardEvent {
  const BannersBoardDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
