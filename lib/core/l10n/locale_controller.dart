import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active app locale so any widget can switch it (settings page,
/// P2a) and the choice survives restarts. Arabic-first: `ar` is the default,
/// per BRAND.md. Reads its saved value synchronously from the prefs instance
/// resolved once in `initDependencies`.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const _key = 'locale';

  static const supportedLocales = [Locale('ar'), Locale('en')];

  static Locale _read(SharedPreferences prefs) =>
      prefs.getString(_key) == 'en' ? const Locale('en') : const Locale('ar');

  void setLocale(Locale locale) {
    assert(supportedLocales.contains(locale));
    if (locale == value) return;
    value = locale;
    _prefs.setString(_key, locale.languageCode);
  }
}
