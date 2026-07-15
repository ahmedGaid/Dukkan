import 'package:equatable/equatable.dart';

/// A saved `/notificationTemplates/{id}` doc — a named title/body pair the
/// compose tab's template chip row fills in on tap (FC13, Task C).
class NotificationTemplate extends Equatable {
  const NotificationTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.body,
  });

  final String id;
  final String name;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, name, title, body];
}
