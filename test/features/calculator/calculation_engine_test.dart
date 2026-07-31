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

    test('定数・対数・根・絶対値を処理する', () {
      expect(engine.evaluate('π'), closeTo(3.141592653589793, 1e-14));
      expect(engine.evaluate('e'), closeTo(2.718281828459045, 1e-14));
      expect(engine.evaluate('φ'), closeTo(1.618033988749895, 1e-14));
      expect(engine.evaluate('log(1000)'), closeTo(3, 1e-12));
      expect(engine.evaluate('ln(e)'), closeTo(1, 1e-12));
      expect(engine.evaluate('log₂(8)'), closeTo(3, 1e-12));
      expect(engine.evaluate('√(81)'), 9);
      expect(engine.evaluate('³√(-27)'), closeTo(-3, 1e-12));
      expect(engine.evaluate('abs(-12.5)'), 12.5);
    });

    test('階乗を処理し不正な階乗は拒否する', () {
      expect(engine.evaluate('5!'), 120);
      expect(engine.evaluate('0!'), 1);
      expect(
        () => engine.evaluate('1.5!'),
        throwsA(isA<CalculationException>()),
      );
      expect(
        () => engine.evaluate('171!'),
        throwsA(isA<CalculationException>()),
      );
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
