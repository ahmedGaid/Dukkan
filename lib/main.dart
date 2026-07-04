import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/splash/splash_page.dart';

void main() {
  runApp(const DukkanApp());
}

class DukkanApp extends StatelessWidget {
  const DukkanApp({super.key});

  // Real locale switching + l10n delegates land in F2. Arabic-first default
  // per BRAND.md — forced visually here via Directionality until then.
  static const _locale = Locale('ar');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dukkan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(_locale),
      darkTheme: AppTheme.dark(_locale),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SplashPage(),
      ),
    );
  }
}
