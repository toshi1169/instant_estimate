import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/productivity/application/productivity_controller.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_record.dart';
import 'package:instant_estimate/features/productivity/presentation/productivity_calculation_screen.dart';
import 'package:instant_estimate/features/productivity/presentation/productivity_master_screen.dart';

void main() {
  testWidgets('英語設定で歩掛計算の主要項目を英語表示する', (tester) async {
    await tester.pumpWidget(
      _englishApp(
        ProductivityCalculationScreen(
          controller: ProductivityController(
            store: MemoryProductivityRecordStore(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Productivity calculation'), findsOneWidget);
    expect(find.text('Required labor'), findsOneWidget);
    expect(find.text('Work category'), findsOneWidget);
    expect(
      find.text('Daily output per person (unit/person-day)'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('productivityTrade')));
    await tester.pumpAndSettle();
    expect(find.text('Earthwork'), findsOneWidget);
    expect(find.text('Formwork'), findsOneWidget);
  });

  testWidgets('英語設定で保存実績の工種と歩掛単位を英語表示する', (tester) async {
    final controller = ProductivityController(
      store: MemoryProductivityRecordStore(),
    );
    await controller.load();
    await controller.add(
      ProductivityRecord(
        id: '1',
        createdAt: DateTime(2026, 8, 10),
        trade: '型枠工事',
        taskName: 'Foundation formwork',
        siteName: 'Site A',
        workDate: DateTime(2026, 8, 9),
        quantity: 120,
        unit: 'm²',
        workers: 3,
        workDays: 2,
        actualLabor: 6,
        standardLaborRate: 0.06,
        standardProductivity: 20,
        actualLaborRate: 0.05,
        productivityPerLabor: 20,
      ),
    );

    await tester.pumpWidget(
      _englishApp(ProductivityMasterScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('歩掛：BUGAKARI'), findsOneWidget);
    expect(find.text('Formwork · m² · 1 records'), findsOneWidget);

    await tester.tap(find.text('Foundation formwork'));
    await tester.pumpAndSettle();
    expect(find.text('20.00 m²/person-day'), findsNWidgets(2));
    expect(find.text('0.050 labor-days/m²'), findsOneWidget);
    expect(find.textContaining('3.0 workers × 2.0 days'), findsOneWidget);
  });

  test('歩掛保存上限の案内を英語表示する', () {
    const strings = AppLocalizations(AppLanguage.english);
    expect(
      strings.productivityLimitMessage(5),
      'The current plan can save up to 5 records. The full plan can save up to 100 records.',
    );
  });

  testWidgets('簡体字中国語で歩掛計算の主要項目と単位を表示する', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ProductivityCalculationScreen(
          controller: ProductivityController(
            store: MemoryProductivityRecordStore(),
          ),
        ),
        const Locale('zh', 'CN'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('步挂・生产率计算'), findsOneWidget);
    expect(find.text('所需人工'), findsOneWidget);
    expect(find.text('工种'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '施工数量'), '120');
    await tester.enterText(
      find.widgetWithText(TextField, '每人每日施工量（单位/人日）'),
      '20',
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('6.00 人工'), findsOneWidget);
  });

  testWidgets('簡体字中国語で保存実績の動的単位を表示する', (tester) async {
    final controller = ProductivityController(
      store: MemoryProductivityRecordStore(),
    );
    await controller.load();
    await controller.add(
      ProductivityRecord(
        id: 'zh-1',
        createdAt: DateTime(2026, 8, 11),
        trade: '型枠工事',
        taskName: '基础模板',
        siteName: '现场A',
        workDate: DateTime(2026, 8, 10),
        quantity: 120,
        unit: '枚',
        workers: 3,
        workDays: 2,
        actualLabor: 6,
        standardLaborRate: 0.06,
        standardProductivity: 20,
        actualLaborRate: 0.05,
        productivityPerLabor: 20,
      ),
    );

    await tester.pumpWidget(
      _localizedApp(
        ProductivityMasterScreen(controller: controller),
        const Locale('zh', 'CN'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('模板工程・张・1条记录'), findsOneWidget);
    await tester.tap(find.text('基础模板'));
    await tester.pumpAndSettle();
    expect(find.text('20.00 张/人日'), findsNWidgets(2));
    expect(find.text('0.050 人工/张'), findsOneWidget);
    expect(find.textContaining('3.0人 × 2.0天'), findsOneWidget);
  });

  testWidgets('繁体字中国語で歩掛計算の主要項目と単位を表示する', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ProductivityCalculationScreen(
          controller: ProductivityController(
            store: MemoryProductivityRecordStore(),
          ),
        ),
        const Locale('zh', 'TW'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('步掛・生產率計算'), findsOneWidget);
    expect(find.text('所需人工'), findsOneWidget);
    expect(find.text('工種'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '施工數量'), '120');
    await tester.enterText(
      find.widgetWithText(TextField, '每人每日施工量（單位/人日）'),
      '20',
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('6.00 人工'), findsOneWidget);
  });

  testWidgets('繁体字中国語で保存実績の動的単位を表示する', (tester) async {
    final controller = ProductivityController(
      store: MemoryProductivityRecordStore(),
    );
    await controller.load();
    await controller.add(
      ProductivityRecord(
        id: 'tw-1',
        createdAt: DateTime(2026, 8, 11),
        trade: '型枠工事',
        taskName: '基礎模板',
        siteName: '現場A',
        workDate: DateTime(2026, 8, 10),
        quantity: 120,
        unit: '枚',
        workers: 3,
        workDays: 2,
        actualLabor: 6,
        standardLaborRate: 0.06,
        standardProductivity: 20,
        actualLaborRate: 0.05,
        productivityPerLabor: 20,
      ),
    );

    await tester.pumpWidget(
      _localizedApp(
        ProductivityMasterScreen(controller: controller),
        const Locale('zh', 'TW'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('模板工程・張・1筆實績'), findsOneWidget);
    await tester.tap(find.text('基礎模板'));
    await tester.pumpAndSettle();
    expect(find.text('20.00 張/人日'), findsNWidgets(2));
    expect(find.text('0.050 人工/張'), findsOneWidget);
    expect(find.textContaining('3.0人 × 2.0天'), findsOneWidget);
  });
}

Widget _englishApp(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: const [Locale('ja'), Locale('en')],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

Widget _localizedApp(Widget home, Locale locale) => MaterialApp(
  locale: locale,
  supportedLocales: const [
    Locale('ja'),
    Locale('en'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);
