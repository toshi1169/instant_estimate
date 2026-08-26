import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('設定最下部から共通の免責全文画面を開ける', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja')],
        locale: const Locale('ja'),
        home: SettingsScreen(
          settings: const AppSettings(),
          onSettingsChanged: (_) {},
          onClearHistory: () async {},
        ),
      ),
    );

    final setting = find.byKey(const Key('disclaimerSetting'));
    await tester.scrollUntilVisible(setting, 300);
    await tester.tap(setting);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('disclaimerScreen')), findsOneWidget);
    expect(find.byKey(const Key('disclaimerBody')), findsOneWidget);
    expect(find.text('免責・利用上の注意'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Help画面と免責画面に日本語本文を直接埋め込まない', () {
    final help = File(
      'lib/features/help/presentation/help_screen.dart',
    ).readAsStringSync();
    final disclaimer = File(
      'lib/features/help/presentation/disclaimer_screen.dart',
    ).readAsStringSync();
    final japaneseCharacters = RegExp(r'[ぁ-んァ-ン一-龯]');

    expect(japaneseCharacters.hasMatch(help), isFalse);
    expect(japaneseCharacters.hasMatch(disclaimer), isFalse);
  });
}
