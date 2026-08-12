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
  test('主要UI・見積・歩掛用語をベトナム語で返す', () {
    const strings = AppLocalizations(AppLanguage.vietnamese);

    expect(strings.text('新しい見積'), 'Tạo dự toán mới');
    expect(strings.text('単価マスタ'), 'Danh mục đơn giá');
    expect(strings.text('施工数量'), 'Khối lượng thi công');
    expect(strings.text('歩掛・生産性計算'), 'Định mức lao động (BUGAKARI)・Năng suất');
    expect(strings.text('基準生産性'), 'Năng suất chuẩn');
    expect(strings.text('延べ人工時間'), 'Tổng giờ công');
    expect(strings.text('角度単位'), 'Đơn vị góc');
    expect(strings.specializedUnitExplanation('ken'), contains('Nhật Bản'));
  });

  testWidgets('課金画面をベトナム語で表示する', (tester) async {
    await tester.pumpWidget(
      _vietnameseApp(const AccessPlanScreen(plan: AppAccessPlan.full)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bản đầy đủ'), findsWidgets);
    expect(find.text('Ẩn tất cả quảng cáo'), findsOneWidget);
    expect(
      find.text('Không giới hạn số lượng dự toán được lưu'),
      findsOneWidget,
    );
    expect(find.textContaining('Purchases will be enabled'), findsNothing);
  });

  testWidgets('ヘルプ本文をベトナム語で表示する', (tester) async {
    await tester.pumpWidget(_vietnameseApp(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Các thao tác cơ bản của máy tính'), findsOneWidget);
    await tester.tap(find.text('Các thao tác cơ bản của máy tính'));
    await tester.pumpAndSettle();
    expect(find.textContaining('menu bên trái'), findsOneWidget);
    expect(find.textContaining('「…」をタップ'), findsNothing);
  });

  testWidgets('VoiceOver名称をベトナム語で表示する', (tester) async {
    await tester.pumpWidget(
      _vietnameseApp(
        const CalculatorScreen(
          settings: AppSettings(language: AppLanguage.vietnamese),
          accessPlan: AppAccessPlan.full,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Menu'), findsOneWidget);
    expect(find.bySemanticsLabel('Cài đặt'), findsOneWidget);
  });

  test('既存4言語の代表翻訳を維持する', () {
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
  });
}

Widget _vietnameseApp(Widget home) => MaterialApp(
  locale: const Locale('vi'),
  supportedLocales: const [Locale('vi')],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
