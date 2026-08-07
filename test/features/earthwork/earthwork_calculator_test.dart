import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/features/earthwork/domain/earthwork_calculator.dart';
import 'package:instant_estimate/features/earthwork/presentation/earthwork_calculation_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

void main() {
  test('掘削・埋戻し・搬出土・運搬回数を計算する', () {
    final result = EarthworkCalculator.calculate(
      lengthMeters: 10,
      widthMeters: 2,
      depthMeters: 1,
      structureVolumeCubicMeters: 5,
      soilChangeFactor: 1.25,
      loadCapacityCubicMeters: 4,
    );

    expect(result.excavationVolume, 20);
    expect(result.backfillVolume, 15);
    expect(result.haulVolume, 25);
    expect(result.transportTrips, 7);
  });

  test('構造物体積が掘削量を超える場合はエラーにする', () {
    expect(
      () => EarthworkCalculator.calculate(
        lengthMeters: 1,
        widthMeters: 1,
        depthMeters: 1,
        structureVolumeCubicMeters: 2,
        soilChangeFactor: 1.25,
        loadCapacityCubicMeters: 4,
      ),
      throwsFormatException,
    );
  });

  test('初期車両には指定された通常車両とクローラーダンプを登録する', () {
    expect(InitialTransportVehicles.standard, hasLength(9));
    expect(InitialTransportVehicles.crawlers, hasLength(4));
    expect(
      InitialTransportVehicles.standard
          .firstWhere((vehicle) => vehicle.id == 'dump_4t')
          .initialCapacityCubicMeters,
      3,
    );
    expect(
      InitialTransportVehicles.standard
          .firstWhere((vehicle) => vehicle.id == 'semi_trailer')
          .initialCapacityCubicMeters,
      12,
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
    final calculateButton = find.byKey(const Key('calculateEarthwork'));
    await tester.ensureVisible(calculateButton);
    await tester.pumpAndSettle();
    await tester.tap(calculateButton);
    await tester.pumpAndSettle();

    final excavationCard = find.byKey(const Key('earthworkExcavationResult'));
    await tester.scrollUntilVisible(
      excavationCard,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('20 m³'), findsOneWidget);
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

  testWidgets('運搬車両を選択すると積載容量の初期値を反映する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EarthworkCalculationScreen(onSendToEstimate: (_) async {}),
      ),
    );

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('earthworkLoadCapacity')))
          .controller
          ?.text,
      '3',
    );
    await tester.tap(find.byKey(const Key('earthworkVehicle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10tダンプ  6.0m³ / 10t').last);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('earthworkLoadCapacity')))
          .controller
          ?.text,
      '6',
    );
  });
}
