import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/calculator/domain/calculation_engine.dart';

void main() {
  const engine = CalculationEngine();

  group('CalculationEngine', () {
    test('四則演算の優先順位を処理する', () {
      expect(engine.evaluate('2+3×4'), 14);
    });

    test('カッコと小数を処理する', () {
      expect(engine.evaluate('(12.5+3.75)×2.8÷4'), closeTo(11.375, 1e-12));
    });

    test('百分率を100分の1として処理する', () {
      expect(engine.evaluate('200×10%'), 20);
    });

    test('べき乗を処理する', () {
      expect(engine.evaluate('2^3^2'), 512);
      expect(engine.evaluate('9^0.5'), 3);
    });

    test('0除算では専用エラーを返す', () {
      expect(
        () => engine.evaluate('10÷0'),
        throwsA(
          isA<CalculationException>().having(
            (error) => error.message,
            'message',
            '0で割ることはできません',
          ),
        ),
      );
    });

    test('不完全な式は計算不可にする', () {
      expect(() => engine.evaluate('1+'), throwsA(isA<CalculationException>()));
    });
  });
}
