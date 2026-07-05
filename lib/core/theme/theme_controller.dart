import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active theme mode so the settings page (P2a) can switch it and
/// the choice survives restarts. Defaults to [ThemeMode.system] — the app
/// follows the device until the user picks explicitly. Mirrors
/// [LocaleController]; both read their saved value synchronously from the
/// prefs instance resolved once in `initDependencies`.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static const _key = 'theme_mode';

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setMode(ThemeMode mode) {
    if (mode == value) return;
    value = mode;
    _prefs.setString(_key, mode.name);
  }
}
