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
  test('主要UI・見積・歩掛用語をミャンマー語で返す', () {
    const strings = AppLocalizations(AppLanguage.myanmar);

    expect(strings.text('新しい見積'), 'ခန့်မှန်းချက်အသစ် ဖန်တီးရန်');
    expect(strings.text('単価マスタ'), 'တစ်ယူနစ်ဈေးနှုန်းစာရင်း');
    expect(strings.text('施工数量'), 'ဆောက်လုပ်ရေးပမာဏ');
    expect(
      strings.text('歩掛・生産性計算'),
      'လုပ်သားစံနှုန်း (BUGAKARI)・ကုန်ထုတ်စွမ်းအား',
    );
    expect(strings.text('基準生産性'), 'စံကုန်ထုတ်စွမ်းအား');
    expect(strings.text('延べ人工時間'), 'စုစုပေါင်း လူ-နာရီ');
    expect(strings.text('角度単位'), 'ထောင့်ယူနစ်');
    expect(strings.specializedUnitExplanation('ken'), contains('ဂျပန်'));
  });

  testWidgets('課金画面をミャンマー語で表示する', (tester) async {
    await tester.pumpWidget(
      _myanmarApp(const AccessPlanScreen(plan: AppAccessPlan.full)),
    );
    await tester.pumpAndSettle();

    expect(find.text('အပြည့်အစုံဗားရှင်း'), findsWidgets);
    expect(find.text('ကြော်ငြာအားလုံးကို ဝှက်ပါ။'), findsOneWidget);
    expect(find.textContaining('ခန့်မှန်း'), findsWidgets);
    expect(find.textContaining('Purchases will be enabled'), findsNothing);
  });

  testWidgets('ヘルプ本文をミャンマー語で表示する', (tester) async {
    await tester.pumpWidget(_myanmarApp(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(
      find.text('ဂဏန်းပေါင်းစက်၏ အခြေခံလုပ်ဆောင်ချက်များ'),
      findsOneWidget,
    );
    await tester.tap(find.text('ဂဏန်းပေါင်းစက်၏ အခြေခံလုပ်ဆောင်ချက်များ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ဘယ်ဘက်မီနူး'), findsOneWidget);
    expect(find.textContaining('「…」をタップ'), findsNothing);
  });

  testWidgets('ミャンマー文字とSI単位を描画する', (tester) async {
    await tester.pumpWidget(
      _myanmarApp(
        const Scaffold(
          body: Text('မြေထုထည် 100 m³・ဧရိယာ 25 m²・အလေးချိန် 50 kg'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('မြေထုထည် 100 m³・ဧရိယာ 25 m²・အလေးချိန် 50 kg'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('VoiceOver名称をミャンマー語で表示する', (tester) async {
    await tester.pumpWidget(
      _myanmarApp(
        const CalculatorScreen(
          settings: AppSettings(language: AppLanguage.myanmar),
          accessPlan: AppAccessPlan.full,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('မီနူး'), findsOneWidget);
    expect(find.bySemanticsLabel('ဆက်တင်များ'), findsOneWidget);
  });

  test('既存7言語の代表翻訳を維持する', () {
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
    expect(
      const AppLocalizations(AppLanguage.filipino).settings,
      'Mga Setting',
    );
  });
}

Widget _myanmarApp(Widget home) => MaterialApp(
  locale: const Locale('my'),
  supportedLocales: const [Locale('my')],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
