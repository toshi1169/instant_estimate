import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/angle_unit.dart';
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

    test('度数法で三角関数と逆三角関数を処理する', () {
      expect(engine.evaluate('sin(30)'), closeTo(0.5, 1e-12));
      expect(engine.evaluate('cos(60)'), closeTo(0.5, 1e-12));
      expect(engine.evaluate('tan(45)'), closeTo(1, 1e-12));
      expect(engine.evaluate('sin⁻¹(0.5)'), closeTo(30, 1e-12));
      expect(engine.evaluate('cos⁻¹(0.5)'), closeTo(60, 1e-12));
      expect(engine.evaluate('tan⁻¹(1)'), closeTo(45, 1e-12));
    });

    test('ラジアンで三角関数と逆三角関数を処理する', () {
      expect(
        engine.evaluate('sin(π÷2)', angleUnit: AngleUnit.radians),
        closeTo(1, 1e-12),
      );
      expect(
        engine.evaluate('sin⁻¹(1)', angleUnit: AngleUnit.radians),
        closeTo(1.5707963267948966, 1e-12),
      );
    });

    test('双曲線関数と逆双曲線関数を処理する', () {
      expect(engine.evaluate('sinh(0)'), closeTo(0, 1e-12));
      expect(engine.evaluate('cosh(0)'), closeTo(1, 1e-12));
      expect(engine.evaluate('tanh(0)'), closeTo(0, 1e-12));
      expect(engine.evaluate('sinh⁻¹(0)'), closeTo(0, 1e-12));
      expect(engine.evaluate('cosh⁻¹(1)'), closeTo(0, 1e-12));
      expect(engine.evaluate('tanh⁻¹(0)'), closeTo(0, 1e-12));
    });

    test('定義域外の三角・双曲線関数は拒否する', () {
      for (final expression in [
        'tan(90)',
        'sin⁻¹(2)',
        'cosh⁻¹(0)',
        'tanh⁻¹(1)',
      ]) {
        expect(
          () => engine.evaluate(expression),
          throwsA(isA<CalculationException>()),
        );
      }
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
