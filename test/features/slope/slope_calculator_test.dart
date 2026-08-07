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
  });

  testWidgets('見積数量へ設定の丸めを反映して元数量も保持する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
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

    await tester.enterText(
      find.byKey(const Key('slopeHorizontalDistance')),
      '10',
    );
    await tester.enterText(find.byKey(const Key('slopeInputValue')), '1.111');
    await tester.tap(find.byKey(const Key('calculateSlope')));
    await tester.pumpAndSettle();
    final sendButton = find.descendant(
      of: find.byKey(const Key('slopeHeightResult')),
      matching: find.widgetWithText(TextButton, '見積へ'),
    );
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(sentDraft, isNotNull);
    expect(sentDraft!.name, '高低差');
    expect(sentDraft!.quantity, 1.12);
    expect(sentDraft!.originalQuantity, 1.111);
    expect(sentDraft!.unit, 'm');
  });
}
