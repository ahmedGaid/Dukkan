import 'package:flutter/material.dart';

/// Canon: Docs/Brand/BRAND.md — the ONLY place raw hex is allowed.
/// Everywhere else in the app, reference AppColors.* / theme helpers.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF12362A); // deep green — text-strong, CTAs on light, chrome
  static const primaryBright = Color(0xFF4DBB87); // mint/awning green — accents, active, dark primary
  static const awning = Color(0xFF57C793); // lighter mint — highlights, promo chips

  // Semantic
  static const success = Color(0xFF2E9E6B);
  static const warning = Color(0xFFE8A13D);
  static const error = Color(0xFFD9534F);
  static const info = Color(0xFF3D7FA6);

  // Light surfaces
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF4F7F5); // scaffold — green-tinted near-white
  static const outline = Color(0xFFE2EAE5);

  // Dark surfaces
  static const darkBg = Color(0xFF0A0F0D);
  static const darkSurface = Color(0xFF121A16);
  static const darkCard = Color(0xFF18231D);
}
