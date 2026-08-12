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
  test('見積・設定・単位解説の主要文言を繁体字で返す', () {
    const strings = AppLocalizations(AppLanguage.traditionalChinese);

    expect(strings.text('新しい見積'), '新增估算');
    expect(strings.text('単価を登録'), '登錄單價');
    expect(strings.text('見積基本情報'), '估算基本資料');
    expect(strings.text('広告のプライバシー設定'), '廣告隱私權設定');
    expect(strings.text('角度単位'), '角度單位');
    expect(strings.specializedUnitExplanation('ken'), contains('日本傳統長度單位'));
    expect(
      strings.specializedUnitExplanation('ken'),
      isNot(contains('traditional Japanese')),
    );
  });

  testWidgets('課金画面の説明を繁体字で表示する', (tester) async {
    await tester.pumpWidget(
      _traditionalApp(const AccessPlanScreen(plan: AppAccessPlan.full)),
    );
    await tester.pumpAndSettle();

    expect(find.text('完整版'), findsWidgets);
    expect(find.text('移除所有廣告'), findsOneWidget);
    expect(find.text('無限制儲存估算'), findsOneWidget);
    expect(find.text('首次使用可免費試用7天'), findsOneWidget);
    expect(find.textContaining('Purchases will be enabled'), findsNothing);
  });

  testWidgets('ヘルプ本文を繁体字で表示する', (tester) async {
    await tester.pumpWidget(_traditionalApp(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('計算機基本操作'), findsOneWidget);
    await tester.tap(find.text('計算機基本操作'));
    await tester.pumpAndSettle();
    expect(find.textContaining('側邊選單'), findsOneWidget);
    expect(find.textContaining('Tap “…”'), findsNothing);
  });

  testWidgets('電卓のVoiceOver名称を繁体字で表示する', (tester) async {
    await tester.pumpWidget(
      _traditionalApp(
        const CalculatorScreen(
          settings: AppSettings(language: AppLanguage.traditionalChinese),
          accessPlan: AppAccessPlan.full,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('選單'), findsOneWidget);
    expect(find.bySemanticsLabel('設定'), findsOneWidget);
  });
}

Widget _traditionalApp(Widget home) => MaterialApp(
  locale: const Locale('zh', 'TW'),
  supportedLocales: const [Locale('zh', 'TW')],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
