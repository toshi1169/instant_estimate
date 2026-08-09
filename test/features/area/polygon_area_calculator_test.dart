import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/area/domain/polygon_area_calculator.dart';
import 'package:instant_estimate/features/area/presentation/polygon_area_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  test('5辺形を3つの三角形へ分割して面積を合計する', () {
    final result = PolygonAreaCalculator.calculate(
      outerSides: const [3, 4, 6, 4, 3],
      diagonals: const [5, 5],
    );

    expect(result.triangleAreas, hasLength(3));
    expect(result.triangleAreas[0], closeTo(6, 0.000001));
    expect(result.triangleAreas[1], closeTo(12, 0.000001));
    expect(result.triangleAreas[2], closeTo(6, 0.000001));
    expect(result.totalArea, closeTo(24, 0.000001));
  });

  test('辺数に対角線数が対応しない場合はエラーにする', () {
    expect(
      () => PolygonAreaCalculator.calculate(
        outerSides: const [3, 4, 4, 4, 3],
        diagonals: const [5],
      ),
      throwsFormatException,
    );
  });

  test('分割後に三角形を作れない場合はエラーにする', () {
    expect(
      () => PolygonAreaCalculator.calculate(
        outerSides: const [1, 1, 4, 4, 3],
        diagonals: const [5, 5],
      ),
      throwsFormatException,
    );
  });

  testWidgets('5辺と対角線を入力して面積を見積へ送れる', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: PolygonAreaScreen(
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    for (final (index, value) in ['3', '4', '6', '4', '3'].indexed) {
      await tester.enterText(find.byKey(Key('polygonOuterSide$index')), value);
    }
    for (final (index, value) in ['5', '5'].indexed) {
      await tester.enterText(find.byKey(Key('polygonDiagonal$index')), value);
    }
    final calculateButton = find.byKey(const Key('calculatePolygonArea'));
    await tester.scrollUntilVisible(
      calculateButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(calculateButton);
    await tester.pump();

    expect(find.byKey(const Key('polygonAreaResult')), findsOneWidget);
    expect(find.text('24 m²'), findsOneWidget);

    final sendButton = find.byKey(const Key('sendPolygonAreaToEstimate'));
    await tester.scrollUntilVisible(
      sendButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    await tester.tap(sendButton);
    await tester.pump();
    expect(sentDraft?.quantity, 24);
    expect(sentDraft?.calculationBasis, contains('三角形3'));
  });

  testWidgets('辺を追加すると外周と対角線の入力欄が増える', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PolygonAreaScreen(onSendToEstimate: (_) async {})),
    );

    await tester.tap(find.byKey(const Key('addPolygonSide')));
    await tester.pump();

    expect(find.text('6辺'), findsOneWidget);
    expect(find.byKey(const Key('polygonOuterSide5')), findsOneWidget);
    expect(find.byKey(const Key('polygonDiagonal2')), findsOneWidget);
  });

  testWidgets('見積数量には設定の丸めを適用し元の面積を保持する', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: PolygonAreaScreen(
          settings: const AppSettings(
            decimalPlaces: 2,
            roundingMode: CalculatorRoundingMode.floor,
          ),
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    for (final (index, value) in ['1', '1', '1', '1', '1'].indexed) {
      await tester.enterText(find.byKey(Key('polygonOuterSide$index')), value);
    }
    for (final (index, value) in ['1', '1'].indexed) {
      await tester.enterText(find.byKey(Key('polygonDiagonal$index')), value);
    }
    final calculateButton = find.byKey(const Key('calculatePolygonArea'));
    await tester.scrollUntilVisible(
      calculateButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(calculateButton);
    await tester.pump();

    final sendButton = find.byKey(const Key('sendPolygonAreaToEstimate'));
    await tester.scrollUntilVisible(
      sendButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    await tester.tap(sendButton);
    await tester.pump();

    expect(sentDraft?.quantity, 1.29);
    expect(sentDraft?.originalQuantity, closeTo(1.2990381057, 0.000000001));
  });
}
