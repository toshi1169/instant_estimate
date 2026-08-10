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
    expect(find.text('Standard BUGAKARI (labor/unit)'), findsOneWidget);

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
    expect(find.text('0.060 labor-days/m²'), findsOneWidget);
    expect(find.text('20.00 m²/labor-day'), findsOneWidget);
    expect(find.textContaining('3.0 workers × 2.0 days'), findsOneWidget);
  });

  test('歩掛保存上限の案内を英語表示する', () {
    const strings = AppLocalizations(AppLanguage.english);
    expect(
      strings.productivityLimitMessage(5),
      'The current plan can save up to 5 records. The full plan can save up to 100 records.',
    );
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
