import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/slope/domain/slope_calculator.dart';
import 'package:instant_estimate/features/slope/presentation/slope_calculation_screen.dart';

void main() {
  group('SlopeCalculator', () {
    test('高低差から各勾配値と斜距離を計算する', () {
      final result = SlopeCalculator.calculate(
        horizontalDistanceMeters: 100,
        inputType: SlopeInputType.heightDifference,
        inputValue: 1,
      );

      expect(result.gradientPercent, closeTo(1, 0.000001));
      expect(result.gradientRatioDenominator, closeTo(100, 0.000001));
      expect(result.angleDegrees, closeTo(0.572939, 0.000001));
      expect(result.slopeLengthMeters, closeTo(100.005, 0.00001));
    });

    test('勾配比・百分率・角度から同じ高低差を求める', () {
      final fromRatio = SlopeCalculator.calculate(
        horizontalDistanceMeters: 10,
        inputType: SlopeInputType.gradientRatio,
        inputValue: 100,
      );
      final fromPercent = SlopeCalculator.calculate(
        horizontalDistanceMeters: 10,
        inputType: SlopeInputType.gradientPercent,
        inputValue: 1,
      );
      final fromAngle = SlopeCalculator.calculate(
        horizontalDistanceMeters: 10,
        inputType: SlopeInputType.angleDegrees,
        inputValue: fromRatio.angleDegrees,
      );

      expect(fromRatio.heightDifferenceMeters, closeTo(0.1, 0.000001));
      expect(fromPercent.heightDifferenceMeters, closeTo(0.1, 0.000001));
      expect(fromAngle.heightDifferenceMeters, closeTo(0.1, 0.000001));
    });

    test('水平勾配を計算できる', () {
      final result = SlopeCalculator.calculate(
        horizontalDistanceMeters: 10,
        inputType: SlopeInputType.gradientPercent,
        inputValue: 0,
      );

      expect(result.heightDifferenceMeters, 0);
      expect(result.gradientRatioDenominator, isNull);
      expect(result.slopeLengthMeters, 10);
    });

    test('範囲外の入力を拒否する', () {
      expect(
        () => SlopeCalculator.calculate(
          horizontalDistanceMeters: 0,
          inputType: SlopeInputType.heightDifference,
          inputValue: 1,
        ),
        throwsFormatException,
      );
      expect(
        () => SlopeCalculator.calculate(
          horizontalDistanceMeters: 1,
          inputType: SlopeInputType.gradientRatio,
          inputValue: 0,
        ),
        throwsFormatException,
      );
      expect(
        () => SlopeCalculator.calculate(
          horizontalDistanceMeters: 1,
          inputType: SlopeInputType.angleDegrees,
          inputValue: 90,
        ),
        throwsFormatException,
      );
    });

    test('高さ3mと法長5mから水平距離4mを計算する', () {
      final result = SlopeCalculator.fromHeightAndSlopeLength(
        heightDifferenceMeters: 3,
        slopeLengthMeters: 5,
      );

      expect(result.horizontalDistanceMeters, closeTo(4, 0.000001));
      expect(result.gradientPercent, closeTo(75, 0.000001));
      expect(result.gradientRatioDenominator, closeTo(4 / 3, 0.000001));
      expect(result.angleDegrees, closeTo(36.869897, 0.000001));
    });

    test('法長5mと法勾配1:1.333から高さと水平距離を計算する', () {
      final result = SlopeCalculator.fromSlopeLengthAndGradientRatio(
        slopeLengthMeters: 5,
        gradientRatioDenominator: 4 / 3,
      );

      expect(result.horizontalDistanceMeters, closeTo(4, 0.000001));
      expect(result.heightDifferenceMeters, closeTo(3, 0.000001));
    });

    test('法長が高さ以下の場合は拒否する', () {
      expect(
        () => SlopeCalculator.fromHeightAndSlopeLength(
          heightDifferenceMeters: 5,
          slopeLengthMeters: 5,
        ),
        throwsFormatException,
      );
    });
  });

  testWidgets('画面は3m・4m・5mの法面を自動計算し見積の丸めも反映する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: SlopeCalculationScreen(
          settings: const AppSettings(
            decimalPlaces: 2,
            roundingMode: CalculatorRoundingMode.ceiling,
          ),
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    expect(find.text('勾配・法面計算'), findsOneWidget);
    expect(find.byKey(const Key('slopeDiagram')), findsOneWidget);

    final horizontalField = find.descendant(
      of: find.byKey(const Key('slopeHorizontalDistance')),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(horizontalField).controller!.text, '4.00');

    final extensionField = find.descendant(
      of: find.byKey(const Key('slopeExtension')),
      matching: find.byType(TextField),
    );
    await tester.enterText(extensionField, '1.111');
    await tester.pump();

    final sendButton = find.byKey(const Key('sendSlopeAreaToEstimate'));
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(sentDraft, isNotNull);
    expect(sentDraft!.trade, '勾配・法面');
    expect(sentDraft!.name, '法面工');
    expect(sentDraft!.quantity, 5.56);
    expect(sentDraft!.originalQuantity, closeTo(5.555, 0.000001));
    expect(sentDraft!.unit, 'm²');
  });
}
