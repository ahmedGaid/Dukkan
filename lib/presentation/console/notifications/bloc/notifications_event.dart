part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

class NotificationsRetryRequested extends NotificationsEvent {
  const NotificationsRetryRequested();
}

class NotificationsHistoryLoadMoreRequested extends NotificationsEvent {
  const NotificationsHistoryLoadMoreRequested();
}

/// Exact email/phone lookup for the "مستخدم محدد" compose target — same
/// heuristic as `UsersBloc`'s search field.
class NotificationsTargetSearchRequested extends NotificationsEvent {
  const NotificationsTargetSearchRequested(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

class NotificationsTargetCleared extends NotificationsEvent {
  const NotificationsTargetCleared();
}

class NotificationsBroadcastSendRequested extends NotificationsEvent {
  const NotificationsBroadcastSendRequested({
    required this.audience,
    required this.title,
    required this.body,
  });
  final String audience;
  final String title;
  final String body;

  @override
  List<Object?> get props => [audience, title, body];
}

/// Sends to [state.targetUser] — the compose page only enables this once a
/// target has been resolved via [NotificationsTargetSearchRequested].
class NotificationsDirectSendRequested extends NotificationsEvent {
  const NotificationsDirectSendRequested({required this.title, required this.body});
  final String title;
  final String body;

  @override
  List<Object?> get props => [title, body];
}

/// Retry = re-submit the same content as a brand-new send (FILE_13: "no
/// in-place retry state machine").
class NotificationsResendRequested extends NotificationsEvent {
  const NotificationsResendRequested(this.entry);
  final NotificationHistoryEntry entry;

  @override
  List<Object?> get props => [entry];
}

class NotificationsTemplateSaveRequested extends NotificationsEvent {
  const NotificationsTemplateSaveRequested({
    this.id,
    required this.name,
    required this.title,
    required this.body,
  });
  final String? id;
  final String name;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, name, title, body];
}

class NotificationsTemplateDeleteRequested extends NotificationsEvent {
  const NotificationsTemplateDeleteRequested(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
