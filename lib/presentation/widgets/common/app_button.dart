import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Primary action button. Shows a calm inline spinner while [loading] and
/// blocks re-taps — the standard submit control for the auth forms.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                ),
              )
            : Text(label),
      ),
    );
  }
}
