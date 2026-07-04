import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dukkan/main.dart';
import 'package:dukkan/presentation/splash/splash_page.dart';

void main() {
  testWidgets('App boots to the splash page', (WidgetTester tester) async {
    await tester.pumpWidget(const DukkanApp());
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
