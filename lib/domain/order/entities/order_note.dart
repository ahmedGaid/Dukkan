import 'package:equatable/equatable.dart';

/// One internal staff note on an order (`/orders/{orderId}/notes/{noteId}`,
/// FC10). Append-only — `firestore.rules` denies update/delete — so there is
/// no edit/remove path anywhere in the app, staff console included.
class OrderNote extends Equatable {
  const OrderNote({
    required this.id,
    required this.text,
    required this.byUid,
    required this.byName,
    required this.at,
  });

  final String id;
  final String text;
  final String byUid;
  final String byName;
  final DateTime at;

  @override
  List<Object?> get props => [id, text, byUid, byName, at];
}
