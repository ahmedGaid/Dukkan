import 'package:equatable/equatable.dart';

/// A delivery coverage district. Seed-managed, fixed for v1 — no owner- or
/// courier-created areas (`/areas`, read-only to clients). Referenced by id
/// from a customer's [Address] and from a [Driver]'s `areaIds`.
class Area extends Equatable {
  const Area({
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
