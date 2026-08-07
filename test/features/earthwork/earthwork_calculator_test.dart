import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/earthwork/domain/earthwork_calculator.dart';
import 'package:instant_estimate/features/earthwork/presentation/earthwork_calculation_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

void main() {
  test('掘削・埋戻し・搬出土・ダンプ台数を計算する', () {
    final result = EarthworkCalculator.calculate(
      lengthMeters: 10,
      widthMeters: 2,
      depthMeters: 1,
      structureVolumeCubicMeters: 5,
      soilChangeFactor: 1.25,
      dumpCapacityCubicMeters: 4,
    );

    expect(result.excavationVolume, 20);
    expect(result.backfillVolume, 15);
    expect(result.haulVolume, 25);
    expect(result.dumpTrips, 7);
  });

  test('構造物体積が掘削量を超える場合はエラーにする', () {
    expect(
      () => EarthworkCalculator.calculate(
        lengthMeters: 1,
        widthMeters: 1,
        depthMeters: 1,
        structureVolumeCubicMeters: 2,
        soilChangeFactor: 1.25,
        dumpCapacityCubicMeters: 4,
      ),
      throwsFormatException,
    );
  });

  testWidgets('土量結果を表示して掘削量を見積へ送る', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: EarthworkCalculationScreen(
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('earthworkLength')), '10');
    await tester.enterText(find.byKey(const Key('earthworkWidth')), '2');
    await tester.enterText(find.byKey(const Key('earthworkDepth')), '1');
    await tester.enterText(
      find.byKey(const Key('earthworkStructureVolume')),
      '5',
    );
    await tester.tap(find.byKey(const Key('calculateEarthwork')));
    await tester.pump();

    expect(find.text('20 m³'), findsOneWidget);
    expect(find.text('15 m³'), findsOneWidget);
    final excavationCard = find.byKey(const Key('earthworkExcavationResult'));
    await tester.ensureVisible(excavationCard);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: excavationCard, matching: find.text('見積へ')),
    );
    await tester.pump();

    expect(sentDraft?.trade, '土工');
    expect(sentDraft?.name, '掘削');
    expect(sentDraft?.quantity, 20);
    expect(sentDraft?.unit, 'm³');
    expect(sentDraft?.specification, contains('L=10m'));
  });
}
