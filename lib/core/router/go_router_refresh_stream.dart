import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] (the AuthBloc's state stream) into a [Listenable] so
/// go_router re-runs its redirect whenever the session status changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
