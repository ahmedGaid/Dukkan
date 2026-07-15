import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/admin/entities/managed_user.dart';
import '../../../../domain/admin/usecases/get_user_by_email.dart';
import '../../../../domain/admin/usecases/get_user_by_phone.dart';
import '../../../../domain/notifications_admin/entities/notification_history_entry.dart';
import '../../../../domain/notifications_admin/entities/notification_stats.dart';
import '../../../../domain/notifications_admin/entities/notification_template.dart';
import '../../../../domain/notifications_admin/usecases/delete_notification_template.dart';
import '../../../../domain/notifications_admin/usecases/get_notification_history.dart';
import '../../../../domain/notifications_admin/usecases/get_notification_stats.dart';
import '../../../../domain/notifications_admin/usecases/get_notification_templates.dart';
import '../../../../domain/notifications_admin/usecases/save_notification_template.dart';
import '../../../../domain/notifications_admin/usecases/send_broadcast_notification.dart';
import '../../../../domain/notifications_admin/usecases/send_direct_notification.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Drives the console notification center (`/console/notifications`, FC13):
/// templates + stats + the first history page load together (Shoppy
/// parallel-load lesson, one emit); every send (broadcast, direct, resend)
/// refreshes stats + the first history page afterward so the السجل tab never
/// goes stale mid-session.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required GetNotificationTemplates getTemplates,
    required GetNotificationStats getStats,
    required GetNotificationHistory getHistory,
    required SendBroadcastNotification sendBroadcast,
    required SendDirectNotification sendDirect,
    required SaveNotificationTemplate saveTemplate,
    required DeleteNotificationTemplate deleteTemplate,
    required GetUserByEmail getUserByEmail,
    required GetUserByPhone getUserByPhone,
  })  : _getTemplates = getTemplates,
        _getStats = getStats,
        _getHistory = getHistory,
        _sendBroadcast = sendBroadcast,
        _sendDirect = sendDirect,
        _saveTemplate = saveTemplate,
        _deleteTemplate = deleteTemplate,
        _getUserByEmail = getUserByEmail,
        _getUserByPhone = getUserByPhone,
        super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsRetryRequested>(_onStarted);
    on<NotificationsHistoryLoadMoreRequested>(_onLoadMore);
    on<NotificationsTargetSearchRequested>(_onTargetSearch);
    on<NotificationsTargetCleared>((_, emit) => emit(state.copyWith(
          targetUser: null,
          targetNotFound: false,
        )));
    on<NotificationsBroadcastSendRequested>(_onBroadcastSend);
    on<NotificationsDirectSendRequested>(_onDirectSend);
    on<NotificationsResendRequested>(_onResend);
    on<NotificationsTemplateSaveRequested>(_onTemplateSave);
    on<NotificationsTemplateDeleteRequested>(_onTemplateDelete);

    add(const NotificationsStarted());
  }

  final GetNotificationTemplates _getTemplates;
  final GetNotificationStats _getStats;
  final GetNotificationHistory _getHistory;
  final SendBroadcastNotification _sendBroadcast;
  final SendDirectNotification _sendDirect;
  final SaveNotificationTemplate _saveTemplate;
  final DeleteNotificationTemplate _deleteTemplate;
  final GetUserByEmail _getUserByEmail;
  final GetUserByPhone _getUserByPhone;

  static final _phonePattern = RegExp(r'^[0-9+ ]{4,}$');

  Future<void> _onStarted(
    NotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      final templatesFuture = _getTemplates();
      final statsFuture = _getStats();
      final historyFuture = _getHistory();
      final templates = await templatesFuture;
      final stats = await statsFuture;
      final history = await historyFuture;
      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        templates: templates,
        stats: stats,
        historyEntries: history.entries,
        historyHasMore: history.hasMore,
      ));
    } catch (_) {
      emit(state.copyWith(status: NotificationsStatus.error));
    }
  }

  Future<void> _onLoadMore(
    NotificationsHistoryLoadMoreRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.historyLoadingMore || !state.historyHasMore || state.historyEntries.isEmpty) {
      return;
    }
    emit(state.copyWith(historyLoadingMore: true));
    try {
      final page = await _getHistory(
        cursor: state.historyEntries.last.sentAt.toUtc().toIso8601String(),
      );
      emit(state.copyWith(
        historyEntries: [...state.historyEntries, ...page.entries],
        historyHasMore: page.hasMore,
        historyLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(historyLoadingMore: false, historyHasMore: false));
    }
  }

  Future<void> _onTargetSearch(
    NotificationsTargetSearchRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(targetUser: null, targetNotFound: false));
      return;
    }
    emit(state.copyWith(targetSearching: true, targetNotFound: false));
    try {
      final ManagedUser? user = query.contains('@')
          ? await _getUserByEmail(query)
          : _phonePattern.hasMatch(query)
              ? await _getUserByPhone(query)
              : null;
      emit(state.copyWith(
        targetSearching: false,
        targetUser: user,
        targetNotFound: user == null,
      ));
    } catch (_) {
      emit(state.copyWith(targetSearching: false, targetUser: null, targetNotFound: true));
    }
  }

  Future<void> _refreshAfterSend(Emitter<NotificationsState> emit) async {
    try {
      final statsFuture = _getStats();
      final historyFuture = _getHistory();
      final stats = await statsFuture;
      final history = await historyFuture;
      emit(state.copyWith(
        stats: stats,
        historyEntries: history.entries,
        historyHasMore: history.hasMore,
      ));
    } catch (_) {
      // Send already reported ok/error to the caller; a stats refresh miss
      // just leaves the previous numbers on screen until the next action.
    }
  }

  Future<void> _onBroadcastSend(
    NotificationsBroadcastSendRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(sendBusy: true, sendError: null));
    try {
      await _sendBroadcast(audience: event.audience, title: event.title, body: event.body);
      emit(state.copyWith(sendBusy: false));
      await _refreshAfterSend(emit);
    } catch (e) {
      emit(state.copyWith(sendBusy: false, sendError: e.toString()));
    }
  }

  Future<void> _onDirectSend(
    NotificationsDirectSendRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final uid = state.targetUser?.uid;
    if (uid == null) return;
    emit(state.copyWith(sendBusy: true, sendError: null));
    try {
      await _sendDirect(uid: uid, title: event.title, body: event.body);
      emit(state.copyWith(sendBusy: false, targetUser: null));
      await _refreshAfterSend(emit);
    } catch (e) {
      emit(state.copyWith(sendBusy: false, sendError: e.toString()));
    }
  }

  Future<void> _onResend(
    NotificationsResendRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final entry = event.entry;
    emit(state.copyWith(sendBusy: true, sendError: null));
    try {
      if (entry.kind == 'broadcast' && entry.audience != null) {
        await _sendBroadcast(audience: entry.audience!, title: entry.title, body: entry.body);
      } else if (entry.targetUid != null) {
        await _sendDirect(uid: entry.targetUid!, title: entry.title, body: entry.body);
      }
      emit(state.copyWith(sendBusy: false));
      await _refreshAfterSend(emit);
    } catch (e) {
      emit(state.copyWith(sendBusy: false, sendError: e.toString()));
    }
  }

  Future<void> _onTemplateSave(
    NotificationsTemplateSaveRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(templateBusy: true));
    try {
      await _saveTemplate(
        id: event.id,
        name: event.name,
        title: event.title,
        body: event.body,
      );
      final templates = await _getTemplates();
      emit(state.copyWith(templateBusy: false, templates: templates));
    } catch (_) {
      emit(state.copyWith(templateBusy: false));
    }
  }

  Future<void> _onTemplateDelete(
    NotificationsTemplateDeleteRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(templateBusy: true));
    try {
      await _deleteTemplate(event.id);
      final templates = await _getTemplates();
      emit(state.copyWith(templateBusy: false, templates: templates));
    } catch (_) {
      emit(state.copyWith(templateBusy: false));
    }
  }
}
