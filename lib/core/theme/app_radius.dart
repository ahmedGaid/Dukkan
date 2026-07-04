import 'package:flutter/material.dart';

/// Canon: Docs/Brand/BRAND.md — rounder than default; logo is round.
abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const round = 100.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get roundAll => BorderRadius.circular(round);
}
