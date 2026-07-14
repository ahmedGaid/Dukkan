import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/order/entities/order_note.dart';

class OrderNoteModel extends OrderNote {
  const OrderNoteModel({
    required super.id,
    required super.text,
    required super.byUid,
    required super.byName,
    required super.at,
  });

  factory OrderNoteModel.fromFirestore(String id, Map<String, dynamic> data) {
    final at = data['at'];
    return OrderNoteModel(
      id: id,
      text: data['text'] as String? ?? '',
      byUid: data['byUid'] as String? ?? '',
      byName: data['byName'] as String? ?? '',
      at: at is Timestamp ? at.toDate() : DateTime.now(),
    );
  }
}
