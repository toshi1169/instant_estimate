import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/help/presentation/help_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/subscription/presentation/access_plan_screen.dart';

void main() {
  test('主要UI・見積・歩掛用語をフィリピノ語で返す', () {
    const strings = AppLocalizations(AppLanguage.filipino);

    expect(strings.text('新しい見積'), 'Gumawa ng bagong estimasyon');
    expect(strings.text('単価マスタ'), 'Listahan ng presyo kada yunit');
    expect(strings.text('施工数量'), 'Dami ng konstruksyon');
    expect(
      strings.text('歩掛・生産性計算'),
      'Pamantayan sa paggawa (BUGAKARI)・Produktibidad',
    );
    expect(strings.text('基準生産性'), 'Pamantayang produktibidad');
    expect(strings.text('延べ人工時間'), 'Kabuuang tao-oras');
    expect(strings.text('角度単位'), 'Yunit ng anggulo');
    expect(strings.specializedUnitExplanation('ken'), contains('Japan'));
  });

  testWidgets('課金画面をフィリピノ語で表示する', (tester) async {
    await tester.pumpWidget(
      _filipinoApp(const AccessPlanScreen(plan: AppAccessPlan.full)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kumpletong bersyon'), findsWidgets);
    expect(find.text('Itago ang lahat ng ad'), findsOneWidget);
    expect(find.textContaining('estimasyon'), findsWidgets);
    expect(find.textContaining('Purchases will be enabled'), findsNothing);
  });

  testWidgets('ヘルプ本文をフィリピノ語で表示する', (tester) async {
    await tester.pumpWidget(_filipinoApp(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('Mga pangunahing operasyon ng calculator'),
      findsOneWidget,
    );
    await tester.tap(find.text('Mga pangunahing operasyon ng calculator'));
    await tester.pumpAndSettle();
    expect(find.textContaining('kaliwang menu'), findsOneWidget);
    expect(find.textContaining('「…」をタップ'), findsNothing);
  });

  testWidgets('VoiceOver名称をフィリピノ語で表示する', (tester) async {
    await tester.pumpWidget(
      _filipinoApp(
        const CalculatorScreen(
          settings: AppSettings(language: AppLanguage.filipino),
          accessPlan: AppAccessPlan.full,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Mga Setting'), findsOneWidget);
  });

  test('既存6言語の代表翻訳を維持する', () {
    expect(const AppLocalizations(AppLanguage.japanese).settings, '設定');
    expect(const AppLocalizations(AppLanguage.english).settings, 'Settings');
    expect(
      const AppLocalizations(AppLanguage.simplifiedChinese).settings,
      '设置',
    );
    expect(
      const AppLocalizations(AppLanguage.traditionalChinese).settings,
      '設定',
    );
    expect(const AppLocalizations(AppLanguage.vietnamese).settings, 'Cài đặt');
    expect(
      const AppLocalizations(AppLanguage.indonesian).settings,
      'Pengaturan',
    );
  });
}

Widget _filipinoApp(Widget home) => MaterialApp(
  locale: const Locale('fil'),
  supportedLocales: const [Locale('fil')],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
