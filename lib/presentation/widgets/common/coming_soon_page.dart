import 'package:flutter/material.dart';

import 'empty_state.dart';

/// A designed "not built yet" screen — reused for placeholder bottom-nav tabs
/// and for pushed routes (shop page, search) until their real build lands. Never
/// a blank page (designed states everywhere).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.appBarTitle,
  });

  final IconData icon;
  final String title;
  final String message;

  /// When set, an app bar (with a back button) shows — used for pushed routes.
  /// Tab pages leave it null (the shell owns navigation).
  final String? appBarTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarTitle == null ? null : AppBar(title: Text(appBarTitle!)),
      body: SafeArea(
        child: EmptyState(icon: icon, title: title, message: message),
      ),
    );
  }
}
