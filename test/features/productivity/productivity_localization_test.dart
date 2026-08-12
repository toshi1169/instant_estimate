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
  testWidgets('日数内訳は正の標準作業時間がある場合だけ表示する', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ProductivityCalculationScreen(
          controller: ProductivityController(
            store: MemoryProductivityRecordStore(),
          ),
        ),
        const Locale('ja'),
      ),
    );
    await tester.tap(find.text('必要日数'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '施工数量'), '100');
    await tester.enterText(
      find.widgetWithText(TextField, '1人1日の施工量（単位/人日）'),
      '10',
    );
    await tester.enterText(find.widgetWithText(TextField, '作業人数'), '4');
    await tester.enterText(
      find.widgetWithText(TextField, '1日の標準作業時間（任意）'),
      '0',
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.textContaining('＋0.0時間'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, '1日の標準作業時間（任意）'),
      '8',
    );
    await tester.pumpAndSettle();

    expect(find.text('目安：2日＋4.0時間'), findsOneWidget);
  });

  testWidgets('基準生産性が未入力または0でも基準比較以外を表示する', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ProductivityCalculationScreen(
          controller: ProductivityController(
            store: MemoryProductivityRecordStore(),
          ),
        ),
        const Locale('ja'),
      ),
    );
    await tester.tap(find.text('生産性・実績'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '施工数量'), '100');
    await tester.enterText(find.widgetWithText(TextField, '作業人数'), '2');
    await tester.enterText(find.widgetWithText(TextField, '作業日数（小数可）'), '2');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('実人工'), findsOneWidget);
    expect(find.text('実績生産性'), findsOneWidget);
    expect(find.text('実績歩掛'), findsOneWidget);
    expect(find.textContaining('内部値'), findsNothing);
    expect(find.text('生産性差'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, '基準生産性（任意・単位/人日）'),
      '0',
    );
    await tester.pumpAndSettle();
    expect(find.text('実人工'), findsOneWidget);
    expect(find.text('生産性差'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, '基準生産性（任意・単位/人日）'),
      '10',
    );
    await tester.pumpAndSettle();
    expect(find.text('生産性差'), findsOneWidget);
    expect(find.text('+150.0 %'), findsOneWidget);
  });

  testWidgets('歩掛集計の単位と人数・日数を販売向けに整形する', (tester) async {
    final controller = ProductivityController(
      store: MemoryProductivityRecordStore(),
    );
    await controller.load();
    await controller.add(
      _displayRecord(id: 'display-1', workDays: 2, rate: 0.045),
    );
    await controller.add(
      _displayRecord(id: 'display-2', workDays: 2.5, rate: 0.05),
    );

    await tester.pumpWidget(
      _localizedApp(
        ProductivityMasterScreen(controller: controller),
        const Locale('ja'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('クロス張'));
    await tester.pumpAndSettle();

    expect(find.text('平均実績歩掛'), findsOneWidget);
    expect(find.textContaining('内部値'), findsNothing);
    expect(find.text('0.045 人工/m²'), findsOneWidget);
    expect(find.text('0.050 人工/m²'), findsOneWidget);
    expect(find.textContaining('2人 × 2日'), findsOneWidget);
    expect(find.textContaining('2人 × 2.5日'), findsOneWidget);
  });

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
    expect(find.text('0.050 labor-days/m²'), findsNWidgets(3));
    expect(find.textContaining('3 workers × 2 days'), findsOneWidget);
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

  testWidgets('ベトナム語で歩掛計算の主要項目と単位を表示する', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ProductivityCalculationScreen(
          controller: ProductivityController(
            store: MemoryProductivityRecordStore(),
          ),
        ),
        const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Định mức lao động (BUGAKARI)・Năng suất'), findsOneWidget);
    expect(find.text('Nhân công cần thiết'), findsOneWidget);
    expect(find.text('Hạng mục công việc'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Khối lượng thi công'),
      '120',
    );
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Khối lượng thi công của 1 người/ngày (đơn vị/người-ngày)',
      ),
      '20',
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('6.00 ngày công'), findsOneWidget);
  });

  testWidgets('インドネシア語で歩掛計算の主要項目と単位を表示する', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        ProductivityCalculationScreen(
          controller: ProductivityController(
            store: MemoryProductivityRecordStore(),
          ),
        ),
        const Locale('id'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Norma tenaga kerja (BUGAKARI)・Produktivitas'),
      findsOneWidget,
    );
    expect(find.text('Tenaga kerja yang dibutuhkan'), findsOneWidget);
    expect(find.text('Jenis pekerjaan'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Volume pekerjaan'),
      '120',
    );
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Volume konstruksi per orang per hari (unit/orang-hari)',
      ),
      '20',
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('6.00 hari-orang'), findsOneWidget);
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
    expect(find.text('0.050 人工/张'), findsNWidgets(3));
    expect(find.textContaining('3人 × 2天'), findsOneWidget);
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
    expect(find.text('0.050 人工/張'), findsNWidgets(3));
    expect(find.textContaining('3人 × 2天'), findsOneWidget);
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
    Locale('vi'),
    Locale('id'),
  ],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: home,
);

ProductivityRecord _displayRecord({
  required String id,
  required double workDays,
  required double rate,
}) {
  return ProductivityRecord(
    id: id,
    createdAt: DateTime(2026, 8, 12),
    trade: '内装工事',
    taskName: 'クロス張',
    siteName: '松本邸',
    workDate: DateTime(2026, 8, 11),
    quantity: 100,
    unit: 'm²',
    workers: 2,
    workDays: workDays,
    actualLabor: 2 * workDays,
    actualLaborRate: rate,
    productivityPerLabor: 1 / rate,
  );
}
