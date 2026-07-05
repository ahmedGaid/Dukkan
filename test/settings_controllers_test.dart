import 'package:dukkan/core/l10n/locale_controller.dart';
import 'package:dukkan/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two persisted settings controllers (P2a): each reads its saved value
/// on construction and writes back on change, so the choice survives restarts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController', () {
    test('defaults to system when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(ThemeController(prefs).value, ThemeMode.system);
    });

    test('reads the saved mode on construction', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();
      expect(ThemeController(prefs).value, ThemeMode.dark);
    });

    test('persists the mode on change', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ThemeController(prefs).setMode(ThemeMode.light);
      expect(prefs.getString('theme_mode'), 'light');
    });
  });

  group('LocaleController', () {
    test('defaults to Arabic when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(LocaleController(prefs).value, const Locale('ar'));
    });

    test('reads the saved locale on construction', () async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      expect(LocaleController(prefs).value, const Locale('en'));
    });

    test('persists the locale on change', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      LocaleController(prefs).setLocale(const Locale('en'));
      expect(prefs.getString('locale'), 'en');
    });
  });
}
