import '../../../domain/notifications_admin/entities/notification_template.dart';

class NotificationTemplateModel extends NotificationTemplate {
  const NotificationTemplateModel({
    required super.id,
    required super.name,
    required super.title,
    required super.body,
  });

  factory NotificationTemplateModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return NotificationTemplateModel(
      id: id,
      name: data['name'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
    );
  }
}
