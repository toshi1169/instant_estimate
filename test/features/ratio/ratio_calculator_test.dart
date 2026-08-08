import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/ratio/domain/ratio_calculator.dart';
import 'package:instant_estimate/features/ratio/presentation/ratio_calculation_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  const calculator = RatioCalculator();

  group('RatioCalculator', () {
    test('calculates A from B C D', () {
      final result = calculator.calculate(a: null, b: 5, c: 8, d: 20);
      expect(result.missingTerm, RatioTerm.a);
      expect(result.value, 2);
    });

    test('calculates B from A C D', () {
      final result = calculator.calculate(a: 2, b: null, c: 8, d: 20);
      expect(result.missingTerm, RatioTerm.b);
      expect(result.value, 5);
    });

    test('calculates C from A B D', () {
      final result = calculator.calculate(a: 2, b: 5, c: null, d: 20);
      expect(result.missingTerm, RatioTerm.c);
      expect(result.value, 8);
    });

    test('calculates D from A B C', () {
      final result = calculator.calculate(a: 2, b: 5, c: 8, d: null);
      expect(result.missingTerm, RatioTerm.d);
      expect(result.value, 20);
    });

    test('rejects zero and negative values', () {
      expect(
        () => calculator.calculate(a: 0, b: 5, c: 8, d: null),
        throwsFormatException,
      );
    });
  });

  testWidgets('screen calculates the blank field using app rounding', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RatioCalculationScreen(
          settings: AppSettings(
            decimalPlaces: 2,
            roundingMode: CalculatorRoundingMode.ceiling,
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('ratioA')), '3');
    await tester.enterText(find.byKey(const Key('ratioB')), '2');
    await tester.enterText(find.byKey(const Key('ratioC')), '10');
    await tester.pump();

    expect(find.text('D ＝ 6.67'), findsOneWidget);
  });
}
