import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// One place for transient messages. Semantic color always pairs with an icon
/// (brand rule: color never carries meaning alone). Callers pass an already
/// localized message.
abstract final class AppSnackBar {
  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_outline);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.error, Icons.error_outline);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info_outline);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          content: Row(
            children: [
              Icon(icon, color: AppColors.surface, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.surface),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
