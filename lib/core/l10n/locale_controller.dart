import 'package:flutter/material.dart';

/// Holds the active app locale so any widget can switch it (settings page,
/// P2). Arabic-first: `ar` is the default, per BRAND.md.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController() : super(const Locale('ar'));

  static const supportedLocales = [Locale('ar'), Locale('en')];

  void setLocale(Locale locale) {
    assert(supportedLocales.contains(locale));
    value = locale;
  }
}
