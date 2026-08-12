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
  test('主要UI・見積・歩掛用語をインドネシア語で返す', () {
    const strings = AppLocalizations(AppLanguage.indonesian);

    expect(strings.text('新しい見積'), 'Buat estimasi baru');
    expect(strings.text('単価マスタ'), 'Daftar harga satuan');
    expect(strings.text('施工数量'), 'Volume pekerjaan');
    expect(
      strings.text('歩掛・生産性計算'),
      'Norma tenaga kerja (BUGAKARI)・Produktivitas',
    );
    expect(strings.text('基準生産性'), 'Produktivitas standar');
    expect(strings.text('延べ人工時間'), 'Total jam-orang');
    expect(strings.text('角度単位'), 'Satuan sudut');
    expect(strings.specializedUnitExplanation('ken'), contains('Jepang'));
  });

  testWidgets('課金画面をインドネシア語で表示する', (tester) async {
    await tester.pumpWidget(
      _indonesianApp(const AccessPlanScreen(plan: AppAccessPlan.full)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Versi lengkap'), findsWidgets);
    expect(find.text('Sembunyikan semua iklan'), findsOneWidget);
    expect(
      find.text('Jumlah estimasi yang disimpan tidak terbatas'),
      findsOneWidget,
    );
    expect(find.textContaining('Purchases will be enabled'), findsNothing);
  });

  testWidgets('ヘルプ本文をインドネシア語で表示する', (tester) async {
    await tester.pumpWidget(_indonesianApp(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Operasi dasar kalkulator'), findsOneWidget);
    await tester.tap(find.text('Operasi dasar kalkulator'));
    await tester.pumpAndSettle();
    expect(find.textContaining('menu sebelah kiri'), findsOneWidget);
    expect(find.textContaining('「…」をタップ'), findsNothing);
  });

  testWidgets('VoiceOver名称をインドネシア語で表示する', (tester) async {
    await tester.pumpWidget(
      _indonesianApp(
        const CalculatorScreen(
          settings: AppSettings(language: AppLanguage.indonesian),
          accessPlan: AppAccessPlan.full,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Pengaturan'), findsOneWidget);
  });

  test('既存5言語の代表翻訳を維持する', () {
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
  });
}

Widget _indonesianApp(Widget home) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: const [Locale('id')],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
