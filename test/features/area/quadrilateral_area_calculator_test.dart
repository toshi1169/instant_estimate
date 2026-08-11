import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/area/domain/quadrilateral_area_calculator.dart';
import 'package:instant_estimate/features/area/presentation/quadrilateral_area_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  test('対角線で分けた2つの三角形の面積を合計する', () {
    final result = QuadrilateralAreaCalculator.calculate(
      sideA: 3,
      sideB: 4,
      sideC: 3,
      sideD: 4,
      diagonal: 5,
    );

    expect(result.firstTriangleArea, closeTo(6, 0.000001));
    expect(result.secondTriangleArea, closeTo(6, 0.000001));
    expect(result.totalArea, closeTo(12, 0.000001));
  });

  test('三角形を作れない長さはエラーにする', () {
    expect(
      () => QuadrilateralAreaCalculator.calculate(
        sideA: 1,
        sideB: 2,
        sideC: 3,
        sideD: 4,
        diagonal: 5,
      ),
      throwsFormatException,
    );
  });

  test('0以下の長さはエラーにする', () {
    expect(
      () => QuadrilateralAreaCalculator.calculate(
        sideA: 0,
        sideB: 4,
        sideC: 3,
        sideD: 4,
        diagonal: 5,
      ),
      throwsFormatException,
    );
  });

  testWidgets('4辺と対角線を入力すると合計面積を表示する', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: QuadrilateralAreaScreen(
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    for (final (index, value) in ['3', '4', '3', '4', '5'].indexed) {
      await tester.enterText(
        find.byKey(Key('quadrilateralLength$index')),
        value,
      );
    }
    await tester.tap(find.byKey(const Key('calculateQuadrilateralArea')));
    await tester.pump();

    expect(find.byKey(const Key('quadrilateralAreaResult')), findsOneWidget);
    expect(find.text('12 m²'), findsOneWidget);
    expect(find.textContaining('三角形① 6 m²'), findsOneWidget);

    final sendButton = find.byKey(const Key('sendQuadrilateralAreaToEstimate'));
    await tester.scrollUntilVisible(
      sendButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(sendButton);
    await tester.pump();
    expect(sentDraft?.name, '面積');
    expect(sentDraft?.quantity, 12);
    expect(sentDraft?.unit, 'm²');
    expect(sentDraft?.specification, contains('対角線=5m'));
    expect(sentDraft?.calculationBasis, contains('＝ 12m²'));
  });

  testWidgets('見積数量には設定の丸めを適用し元の面積を保持する', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: QuadrilateralAreaScreen(
          settings: const AppSettings(
            decimalPlaces: 2,
            roundingMode: CalculatorRoundingMode.floor,
          ),
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    for (final (index, value) in ['1', '1', '1', '1', '1'].indexed) {
      await tester.enterText(
        find.byKey(Key('quadrilateralLength$index')),
        value,
      );
    }
    await tester.tap(find.byKey(const Key('calculateQuadrilateralArea')));
    await tester.pump();

    final sendButton = find.byKey(const Key('sendQuadrilateralAreaToEstimate'));
    await tester.scrollUntilVisible(
      sendButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(sendButton);
    await tester.pump();

    expect(sentDraft?.quantity, 0.86);
    expect(sentDraft?.originalQuantity, closeTo(0.8660254038, 0.000000001));
  });

  testWidgets('英語設定で三角形を作れないエラーを英語表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: QuadrilateralAreaScreen(onSendToEstimate: (_) async {}),
      ),
    );

    for (final (index, value) in ['1', '2', '3', '4', '5'].indexed) {
      await tester.enterText(
        find.byKey(Key('quadrilateralLength$index')),
        value,
      );
    }
    await tester.tap(find.byKey(const Key('calculateQuadrilateralArea')));
    await tester.pump();

    expect(
      find.text('The entered lengths cannot form a triangle'),
      findsOneWidget,
    );
    expect(find.text('入力した長さでは三角形を作れません'), findsNothing);
  });

  testWidgets('簡体字設定で4辺面積を中国語で見積へ送る', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [
          Locale('ja'),
          Locale('en'),
          Locale('zh', 'CN'),
        ],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: QuadrilateralAreaScreen(
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    for (final (index, value) in ['3', '4', '3', '4', '5'].indexed) {
      await tester.enterText(
        find.byKey(Key('quadrilateralLength$index')),
        value,
      );
    }
    await tester.tap(find.byKey(const Key('calculateQuadrilateralArea')));
    await tester.pump();

    expect(find.textContaining('三角形① 6 m²'), findsOneWidget);
    final sendButton = find.byKey(const Key('sendQuadrilateralAreaToEstimate'));
    await tester.scrollUntilVisible(
      sendButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(sendButton);
    await tester.pump();

    expect(sentDraft?.name, '面积');
    expect(sentDraft?.specification, contains('对角线=5m'));
    expect(sentDraft?.calculationBasis, contains('三角形'));
  });
}
