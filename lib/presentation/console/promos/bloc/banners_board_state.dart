part of 'banners_board_bloc.dart';

enum BannersBoardStatus { loading, loaded, error }

class BannersBoardState extends Equatable {
  const BannersBoardState({
    this.status = BannersBoardStatus.loading,
    this.banners = const [],
    this.actionBusy = false,
    this.actionError = false,
  });

  final BannersBoardStatus status;

  /// Sorted by `sort` ascending.
  final List<PromoBanner> banners;

  final bool actionBusy;
  final bool actionError;

  BannersBoardState copyWith({
    BannersBoardStatus? status,
    List<PromoBanner>? banners,
    bool? actionBusy,
    bool? actionError,
  }) {
    return BannersBoardState(
      status: status ?? this.status,
      banners: banners ?? this.banners,
      actionBusy: actionBusy ?? this.actionBusy,
      actionError: actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [status, banners, actionBusy, actionError];
}
