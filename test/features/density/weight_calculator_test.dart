import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/density/domain/weight_calculator.dart';
import 'package:instant_estimate/features/density/presentation/weight_calculation_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

void main() {
  test('体積と比重からtとkgの重量を計算する', () {
    final result = WeightCalculator.calculate(
      volumeCubicMeters: 2,
      densityTonnesPerCubicMeter: 2.4,
    );

    expect(result.weightTonnes, closeTo(4.8, 0.000001));
    expect(result.weightKilograms, closeTo(4800, 0.000001));
  });

  test('0以下の体積または比重はエラーにする', () {
    expect(
      () => WeightCalculator.calculate(
        volumeCubicMeters: 0,
        densityTonnesPerCubicMeter: 2.4,
      ),
      throwsFormatException,
    );
    expect(
      () => WeightCalculator.calculate(
        volumeCubicMeters: 2,
        densityTonnesPerCubicMeter: -1,
      ),
      throwsFormatException,
    );
  });

  testWidgets('材料と体積から重量を表示して見積へ送る', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: WeightCalculationScreen(
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('densityVolume')), '2');
    await tester.tap(find.byKey(const Key('calculateWeight')));
    await tester.pump();

    expect(find.byKey(const Key('weightCalculationResult')), findsOneWidget);
    expect(find.text('4.8 t'), findsOneWidget);
    expect(find.text('4800 kg'), findsOneWidget);

    final sendButton = find.byKey(const Key('sendWeightToEstimate'));
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pump();

    expect(sentDraft?.name, 'RCコンクリート');
    expect(sentDraft?.quantity, 4.8);
    expect(sentDraft?.unit, 't');
    expect(sentDraft?.specification, contains('体積=2m³'));
    expect(sentDraft?.calculationBasis, '2 × 2.4 ＝ 4.8t');
  });
}
