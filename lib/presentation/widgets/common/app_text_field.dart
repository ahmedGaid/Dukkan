import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Themed form field. Label + optional helper come pre-localized from the
/// caller — no strings live here. RTL-safe (uses the theme's directional
/// input decoration).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.prefixIcon,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        ),
      ),
    );
  }
}
