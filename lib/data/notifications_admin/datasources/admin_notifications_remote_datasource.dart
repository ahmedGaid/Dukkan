import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/notifications_admin/entities/notification_history_page.dart';
import '../../../domain/notifications_admin/entities/notification_stats.dart';
import '../models/notification_history_entry_model.dart';
import '../models/notification_template_model.dart';

/// Firestore-direct reads for the notification center (FC13): history
/// (Worker-written, read-only here) + stats (aggregate `count()`, M13 lesson)
/// + template CRUD (console-owned, no Worker route — same shape as
/// `AdminTaxonomyRemoteDataSource`).
class AdminNotificationsRemoteDataSource {
  AdminNotificationsRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const pageSize = 30;

  CollectionReference<Map<String, dynamic>> get _history =>
      _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _templates =>
      _firestore.collection('notificationTemplates');

  Future<NotificationHistoryPage> getHistory({String? cursor}) async {
    try {
      Query<Map<String, dynamic>> q = _history.orderBy('sentAt', descending: true);
      if (cursor != null) {
        q = q.startAfter([Timestamp.fromDate(DateTime.parse(cursor))]);
      }
      q = q.limit(pageSize);

      final snap = await q.get();
      final entries = snap.docs
          .map((d) => NotificationHistoryEntryModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
      return NotificationHistoryPage(entries: entries, hasMore: entries.length == pageSize);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<NotificationStats> getStats() async {
    try {
      final results = await Future.wait([
        _history.where('status', isEqualTo: 'sent').count().get(),
        _history.where('status', isEqualTo: 'failed').count().get(),
      ]);
      return NotificationStats(
        sentCount: results[0].count ?? 0,
        failedCount: results[1].count ?? 0,
      );
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<List<NotificationTemplateModel>> getTemplates() async {
    try {
      final snap = await _templates.orderBy('name').get();
      return snap.docs
          .map((d) => NotificationTemplateModel.fromFirestore(d.id, d.data()))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> createTemplate(Map<String, dynamic> fields) async {
    try {
      await _templates.add(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> patchTemplate(String id, Map<String, dynamic> fields) async {
    try {
      await _templates.doc(id).update(fields);
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _templates.doc(id).delete();
    } on FirebaseException catch (e) {
      throw ServerFailure(e.message ?? e.code);
    }
  }
}
