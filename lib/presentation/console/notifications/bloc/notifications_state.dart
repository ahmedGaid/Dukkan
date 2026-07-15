part of 'notifications_bloc.dart';

enum NotificationsStatus { loading, loaded, error }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.templates = const [],
    this.stats,
    this.historyEntries = const [],
    this.historyHasMore = false,
    this.historyLoadingMore = false,
    this.sendBusy = false,
    this.sendError,
    this.targetUser,
    this.targetSearching = false,
    this.targetNotFound = false,
    this.templateBusy = false,
  });

  final NotificationsStatus status;
  final List<NotificationTemplate> templates;
  final NotificationStats? stats;
  final List<NotificationHistoryEntry> historyEntries;
  final bool historyHasMore;
  final bool historyLoadingMore;

  /// True while a broadcast/direct send (or a resend) is in flight — the
  /// compose send button and the history resend buttons disable together.
  final bool sendBusy;
  final String? sendError;

  /// The resolved "مستخدم محدد" target for a direct send — null until an
  /// exact email/phone search finds one.
  final ManagedUser? targetUser;
  final bool targetSearching;
  final bool targetNotFound;

  final bool templateBusy;

  static const _unset = Object();

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationTemplate>? templates,
    Object? stats = _unset,
    List<NotificationHistoryEntry>? historyEntries,
    bool? historyHasMore,
    bool? historyLoadingMore,
    bool? sendBusy,
    Object? sendError = _unset,
    Object? targetUser = _unset,
    bool? targetSearching,
    bool? targetNotFound,
    bool? templateBusy,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      templates: templates ?? this.templates,
      stats: stats == _unset ? this.stats : stats as NotificationStats?,
      historyEntries: historyEntries ?? this.historyEntries,
      historyHasMore: historyHasMore ?? this.historyHasMore,
      historyLoadingMore: historyLoadingMore ?? this.historyLoadingMore,
      sendBusy: sendBusy ?? this.sendBusy,
      sendError: sendError == _unset ? this.sendError : sendError as String?,
      targetUser: targetUser == _unset ? this.targetUser : targetUser as ManagedUser?,
      targetSearching: targetSearching ?? this.targetSearching,
      targetNotFound: targetNotFound ?? this.targetNotFound,
      templateBusy: templateBusy ?? this.templateBusy,
    );
  }

  @override
  List<Object?> get props => [
        status,
        templates,
        stats,
        historyEntries,
        historyHasMore,
        historyLoadingMore,
        sendBusy,
        sendError,
        targetUser,
        targetSearching,
        targetNotFound,
        templateBusy,
      ];
}
