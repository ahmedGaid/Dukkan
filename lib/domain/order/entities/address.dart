import 'package:equatable/equatable.dart';

/// Manual delivery address (maps deferred past v1 — see roadmap C3). Embedded
/// on the order doc, not its own collection.
class Address extends Equatable {
  const Address({
    required this.line1,
    required this.city,
    this.notes,
    this.areaId,
  });

  final String line1;
  final String city;
  final String? notes;

  /// Delivery district id (M8) — nullable so pre-M8 orders keep parsing;
  /// required by the checkout form for new orders.
  final String? areaId;

  @override
  List<Object?> get props => [line1, city, notes, areaId];
}
