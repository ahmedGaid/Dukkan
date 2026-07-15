import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../domain/auth/repositories/auth_repository.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'root_messenger_key.dart';

/// Push notifications (P2b): permission + token lifecycle, foreground
/// display, and tap-to-navigate. The Worker decides *whether* and *what* to
/// send (see `worker/src/index.js`) — this class only handles the
/// already-arrived message on the device.
///
/// Token save is driven off [AuthBloc] rather than called once at startup:
/// the token is available before login (device-level), but it can only be
/// written once we know *which* user's `/users` doc to write it to, and it
/// must be re-saved on every fresh sign-in (a shared device can change users).
class NotificationService {
  NotificationService({
    required FirebaseMessaging messaging,
    required AuthRepository authRepository,
    required AuthBloc authBloc,
    required AppRouter appRouter,
  })  : _messaging = messaging,
        _authRepository = authRepository,
        _authBloc = authBloc,
        _appRouter = appRouter;

  final FirebaseMessaging _messaging;
  final AuthRepository _authRepository;
  final AuthBloc _authBloc;
  final AppRouter _appRouter;
  StreamSubscription<AuthState>? _authSub;

  Future<void> init() async {
    await _messaging.requestPermission();
    _messaging.onTokenRefresh.listen(_saveToken);
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_navigateFor);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _navigateFor(initial);

    _authSub = _authBloc.stream.listen(_onAuthChanged);
    if (_authBloc.state.session == SessionStatus.authenticated) {
      unawaited(_onAuthChanged(_authBloc.state));
    }
  }

  /// The three persona push topics (FC13, Task A) — broadcast content is
  /// Arabic-only v1 (per-locale topics deferred), so there is exactly one
  /// topic per role, not per role+locale.
  static const _roleTopics = ['role-customer', 'role-owner', 'role-courier'];

  Future<void> _onAuthChanged(AuthState state) async {
    if (state.session != SessionStatus.authenticated) {
      // Sign-out: leave every role topic. A shared device switching users
      // must never keep hearing the previous user's role broadcasts.
      if (state.session == SessionStatus.unauthenticated) {
        for (final topic in _roleTopics) {
          unawaited(_messaging.unsubscribeFromTopic(topic));
        }
      }
      return;
    }
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
    final role = state.user?.role;
    if (role != null) await _messaging.subscribeToTopic('role-${role.wire}');
  }

  Future<void> _saveToken(String token) async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) return;
    await _authRepository.saveFcmToken(uid, token);
  }

  /// FCM suppresses the system tray for "notification"-type messages while
  /// the app is foregrounded (by design, on both platforms) — this is the
  /// only place a foreground push becomes visible at all.
  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.info,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          content: Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  color: AppColors.surface, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${notification.title}\n${notification.body}',
                  style: const TextStyle(color: AppColors.surface),
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// Tap on a background/terminated push. `statusUpdate` (customer) has a
  /// tracking page to land on directly; `newOrder` (owner) doesn't have a
  /// standalone route yet, so it lands on home — the order desk tab is one
  /// tap away and shows it realtime already.
  void _navigateFor(RemoteMessage message) {
    final type = message.data['type'];
    final orderId = message.data['orderId'];
    if (type == 'statusUpdate' && orderId is String) {
      _appRouter.router.go('/order/$orderId');
    } else if (type == 'newOrder') {
      _appRouter.router.go('/home');
    }
  }

  void dispose() {
    _authSub?.cancel();
  }
}
