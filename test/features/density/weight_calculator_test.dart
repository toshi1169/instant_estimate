import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/density/domain/weight_calculator.dart';
import 'package:instant_estimate/features/density/presentation/weight_calculation_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

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

  testWidgets('追加した材料を選択して設定へ保存できる', (tester) async {
    AppSettings? savedSettings;
    await tester.pumpWidget(
      MaterialApp(
        home: WeightCalculationScreen(
          onSendToEstimate: (_) async {},
          onSettingsChanged: (settings) => savedSettings = settings,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('densityMaterial')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('材料を追加').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('newDensityMaterialName')),
      '再生砕石',
    );
    await tester.enterText(
      find.byKey(const Key('newDensityMaterialValue')),
      '1.65',
    );
    await tester.tap(find.byKey(const Key('saveDensityMaterial')));
    await tester.pumpAndSettle();

    expect(find.text('再生砕石（登録）'), findsOneWidget);
    final densityField = tester.widget<TextFormField>(
      find.byKey(const Key('densityValue')),
    );
    expect(densityField.controller?.text, '1.65');
    expect(savedSettings?.customDensityMaterials.single.name, '再生砕石');
    expect(savedSettings?.customDensityMaterials.single.density, 1.65);
  });

  testWidgets('設定の小数桁と丸め方法を表示と見積数量へ反映する', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: WeightCalculationScreen(
          settings: const AppSettings(
            decimalPlaces: 2,
            roundingMode: CalculatorRoundingMode.floor,
          ),
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('densityVolume')), '1');
    await tester.enterText(find.byKey(const Key('densityValue')), '1.239');
    await tester.tap(find.byKey(const Key('calculateWeight')));
    await tester.pump();

    expect(find.text('1.23 t'), findsOneWidget);
    expect(find.text('1239 kg'), findsOneWidget);

    final sendButton = find.byKey(const Key('sendWeightToEstimate'));
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pump();

    expect(sentDraft?.quantity, 1.23);
    expect(sentDraft?.originalQuantity, 1.239);
    expect(sentDraft?.calculationBasis, '1 × 1.239 ＝ 1.239t');
  });
}
