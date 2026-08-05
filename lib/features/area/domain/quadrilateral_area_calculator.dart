import 'dart:math' as math;

class QuadrilateralAreaResult {
  const QuadrilateralAreaResult({
    required this.firstTriangleArea,
    required this.secondTriangleArea,
  });

  final double firstTriangleArea;
  final double secondTriangleArea;

  double get totalArea => firstTriangleArea + secondTriangleArea;
}

abstract final class QuadrilateralAreaCalculator {
  static QuadrilateralAreaResult calculate({
    required double sideA,
    required double sideB,
    required double sideC,
    required double sideD,
    required double diagonal,
  }) {
    final values = [sideA, sideB, sideC, sideD, diagonal];
    if (values.any((value) => !value.isFinite || value <= 0)) {
      throw const FormatException('すべての長さに0より大きい数値を入力してください');
    }

    final firstArea = _triangleArea(sideA, sideB, diagonal);
    final secondArea = _triangleArea(sideC, sideD, diagonal);
    return QuadrilateralAreaResult(
      firstTriangleArea: firstArea,
      secondTriangleArea: secondArea,
    );
  }

  static double _triangleArea(double a, double b, double c) {
    if (a + b <= c || a + c <= b || b + c <= a) {
      throw const FormatException('入力した長さでは三角形を作れません');
    }
    final semiPerimeter = (a + b + c) / 2;
    return math.sqrt(
      semiPerimeter *
          (semiPerimeter - a) *
          (semiPerimeter - b) *
          (semiPerimeter - c),
    );
  }
}
