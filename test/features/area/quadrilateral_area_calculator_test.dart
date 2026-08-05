import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/area/domain/quadrilateral_area_calculator.dart';
import 'package:instant_estimate/features/area/presentation/quadrilateral_area_screen.dart';

void main() {
  test('対角線で分けた2つの三角形の面積を合計する', () {
    final result = QuadrilateralAreaCalculator.calculate(
      sideA: 3,
      sideB: 4,
      sideC: 3,
      sideD: 4,
      diagonal: 5,
    );

    expect(result.firstTriangleArea, closeTo(6, 0.000001));
    expect(result.secondTriangleArea, closeTo(6, 0.000001));
    expect(result.totalArea, closeTo(12, 0.000001));
  });

  test('三角形を作れない長さはエラーにする', () {
    expect(
      () => QuadrilateralAreaCalculator.calculate(
        sideA: 1,
        sideB: 2,
        sideC: 3,
        sideD: 4,
        diagonal: 5,
      ),
      throwsFormatException,
    );
  });

  test('0以下の長さはエラーにする', () {
    expect(
      () => QuadrilateralAreaCalculator.calculate(
        sideA: 0,
        sideB: 4,
        sideC: 3,
        sideD: 4,
        diagonal: 5,
      ),
      throwsFormatException,
    );
  });

  testWidgets('4辺と対角線を入力すると合計面積を表示する', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: QuadrilateralAreaScreen()));

    for (final (index, value) in ['3', '4', '3', '4', '5'].indexed) {
      await tester.enterText(
        find.byKey(Key('quadrilateralLength$index')),
        value,
      );
    }
    await tester.tap(find.byKey(const Key('calculateQuadrilateralArea')));
    await tester.pump();

    expect(find.byKey(const Key('quadrilateralAreaResult')), findsOneWidget);
    expect(find.text('12 m²'), findsOneWidget);
    expect(find.textContaining('三角形① 6 m²'), findsOneWidget);
  });
}
