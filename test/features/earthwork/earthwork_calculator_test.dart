import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/earthwork/domain/earthwork_calculator.dart';
import 'package:instant_estimate/features/earthwork/presentation/earthwork_calculation_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';

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

  test('掘削・搬出ではほぐし係数を使って運搬回数を切り上げる', () {
    final result = EarthworkCalculator.calculateExcavationHaul(
      lengthMeters: 10,
      widthMeters: 2,
      depthMeters: 1,
      looseFactor: 1.25,
      loadCapacityCubicMeters: 3,
    );

    expect(result.bankVolume, 20);
    expect(result.looseVolume, 25);
    expect(result.transportTrips, 9);
  });

  test('埋戻しでは締固め係数をほぐし係数と分けて計算する', () {
    final result = EarthworkCalculator.calculateBackfill(
      lengthMeters: 10,
      widthMeters: 2,
      depthMeters: 1,
      structureVolumeCubicMeters: 5,
      compactionFactor: 0.9,
    );

    expect(result.excavationVolume, 20);
    expect(result.backfillTargetVolume, 15);
    expect(result.requiredBankVolume, closeTo(16.6667, 0.0001));
    expect(result.balanceVolume, closeTo(3.3333, 0.0001));
    expect(result.hasSurplus, isTrue);
  });

  test('法面なしの盛土量・必要搬入土量・運搬回数を計算する', () {
    final result = EarthworkCalculator.calculateEmbankment(
      topLengthMeters: 10,
      topWidthMeters: 5,
      heightMeters: 2,
      hasSlope: false,
      slopeRatioHorizontal: 0,
      compactionFactor: 0.9,
      looseFactor: 1.25,
      loadCapacityCubicMeters: 3,
    );

    expect(result.completedVolume, 100);
    expect(result.requiredBankVolume, closeTo(111.1111, 0.0001));
    expect(result.requiredIncomingLooseVolume, closeTo(138.8889, 0.0001));
    expect(result.transportTrips, 47);
  });

  test('法面ありの盛土形状を将来連携用の寸法とともに計算する', () {
    final result = EarthworkCalculator.calculateEmbankment(
      topLengthMeters: 10,
      topWidthMeters: 5,
      heightMeters: 2,
      hasSlope: true,
      slopeRatioHorizontal: 1.5,
      compactionFactor: 1,
      looseFactor: 1,
      loadCapacityCubicMeters: 10,
    );

    expect(result.geometry.slopeHorizontalRun, 3);
    expect(result.geometry.slopeLength, closeTo(3.60555, 0.00001));
    expect(result.geometry.bottomLengthMeters, 16);
    expect(result.geometry.bottomWidthMeters, 11);
    expect(result.completedVolume, 214);
  });

  test('見積数量は設定した小数桁と丸め方法を反映する', () {
    const halfUp = AppSettings(
      estimateDecimalPlaces: 2,
      estimateRoundingMode: EstimateQuantityRoundingMode.halfUp,
    );
    const ceiling = AppSettings(
      estimateDecimalPlaces: 2,
      estimateRoundingMode: EstimateQuantityRoundingMode.ceiling,
    );
    const floor = AppSettings(
      estimateDecimalPlaces: 2,
      estimateRoundingMode: EstimateQuantityRoundingMode.floor,
    );

    expect(halfUp.roundEstimateQuantity(151.115), 151.12);
    expect(ceiling.roundEstimateQuantity(151.11111111111111), 151.12);
    expect(floor.roundEstimateQuantity(151.119), 151.11);
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
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    final calculateButton = find.byKey(const Key('calculateEarthwork'));
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

  testWidgets('土量結果は丸め前候補として見積編集へ送る', (tester) async {
    EstimateItemDraft? sentDraft;
    await tester.pumpWidget(
      MaterialApp(
        home: EarthworkCalculationScreen(
          settings: const AppSettings(
            decimalPlaces: 2,
            roundingMode: CalculatorRoundingMode.ceiling,
          ),
          onSendToEstimate: (draft) async => sentDraft = draft,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('earthworkLength')), '1.111');
    await tester.enterText(find.byKey(const Key('earthworkWidth')), '1');
    await tester.enterText(find.byKey(const Key('earthworkDepth')), '1');
    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    final calculateButton = find.byKey(const Key('calculateEarthwork'));
    await tester.ensureVisible(calculateButton);
    await tester.pumpAndSettle();
    await tester.tap(calculateButton);
    await tester.pumpAndSettle();

    final haulCard = find.byKey(const Key('earthworkExcavationResult'));
    await tester.scrollUntilVisible(
      haulCard,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: haulCard, matching: find.text('見積へ')));
    await tester.pump();

    expect(sentDraft?.quantity, 1.111);
    expect(sentDraft?.originalQuantity, 1.111);
  });

  testWidgets('埋戻しと盛土をタブで切り替え、高い盛土では注意を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EarthworkCalculationScreen(onSendToEstimate: (_) async {}),
      ),
    );

    await tester.tap(find.text('埋戻し'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('earthworkStructureVolume')), findsOneWidget);
    expect(find.byKey(const Key('backfillCompactionFactor')), findsOneWidget);

    await tester.tap(find.text('盛土'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('embankmentLength')), '10');
    await tester.enterText(find.byKey(const Key('embankmentWidth')), '5');
    await tester.enterText(find.byKey(const Key('embankmentHeight')), '2');
    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    final calculateButton = find.byKey(const Key('calculateEmbankment'));
    await tester.ensureVisible(calculateButton);
    await tester.pumpAndSettle();
    await tester.tap(calculateButton);
    await tester.pumpAndSettle();

    expect(
      find.text('注意\n盛土高さが大きい場合は、地盤条件・法面安定・排水条件・設計図書・関係法令等を確認してください。'),
      findsOneWidget,
    );
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
    final vehicleField = find.byKey(const Key('earthworkVehicle'));
    await tester.scrollUntilVisible(
      vehicleField,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(vehicleField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('10tダンプ  6m³ / 10t').last);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('earthworkLoadCapacity')))
          .controller
          ?.text,
      '6',
    );
  });

  testWidgets('英語設定で土量計算の表示と入力エラーを英語化する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        home: EarthworkCalculationScreen(onSendToEstimate: (_) async {}),
      ),
    );

    expect(find.text('Earthwork calculation'), findsOneWidget);
    expect(find.text('Excavation & haul'), findsOneWidget);
    expect(find.text('Backfill'), findsOneWidget);
    expect(find.text('Embankment'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calculateEarthwork')));
    await tester.pump();

    expect(find.text('Enter a number greater than 0'), findsWidgets);
    expect(find.text('0より大きい数値を入力'), findsNothing);
  });
}
