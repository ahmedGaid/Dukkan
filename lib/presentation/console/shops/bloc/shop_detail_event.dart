part of 'shop_detail_bloc.dart';

sealed class ShopDetailEvent extends Equatable {
  const ShopDetailEvent();

  @override
  List<Object?> get props => [];
}

/// `pending` → `active` (approve) | `pending`/`active` → `suspended`
/// (reject/suspend, [reason] required by the confirm dialog for reject) |
/// `suspended` → `active` (unsuspend).
class ShopDetailSetStatusRequested extends ShopDetailEvent {
  const ShopDetailSetStatusRequested({required this.status, this.reason});

  final String status;
  final String? reason;

  @override
  List<Object?> get props => [status, reason];
}

class ShopDetailSetFeaturedRequested extends ShopDetailEvent {
  const ShopDetailSetFeaturedRequested(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

class ShopDetailSetVerifiedRequested extends ShopDetailEvent {
  const ShopDetailSetVerifiedRequested(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

class ShopDetailUpdateDetailsRequested extends ShopDetailEvent {
  const ShopDetailUpdateDetailsRequested({
    required this.name,
    required this.nameAr,
    required this.address,
    required this.isOpen,
    this.logoUrl,
    this.hoursNote,
  });

  final String name;
  final String nameAr;
  final String address;
  final bool isOpen;
  final String? logoUrl;
  final String? hoursNote;

  @override
  List<Object?> get props => [name, nameAr, address, isOpen, logoUrl, hoursNote];
}

class ShopDetailSoftDeleteRequested extends ShopDetailEvent {
  const ShopDetailSoftDeleteRequested();
}

class ShopDetailRestoreRequested extends ShopDetailEvent {
  const ShopDetailRestoreRequested();
}

class ShopDetailTransferRequested extends ShopDetailEvent {
  const ShopDetailTransferRequested(this.newOwnerUid);

  final String newOwnerUid;

  @override
  List<Object?> get props => [newOwnerUid];
}
