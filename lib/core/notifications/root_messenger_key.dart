import 'package:flutter/material.dart';

/// Lets [NotificationService] show a foreground-push banner without a
/// `BuildContext` (FCM's `onMessage` fires outside the widget tree). Wired
/// into `MaterialApp.router` in `main.dart`.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
