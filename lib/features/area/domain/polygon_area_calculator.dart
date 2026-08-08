import 'dart:math' as math;

class PolygonAreaResult {
  const PolygonAreaResult({required this.triangleAreas});

  final List<double> triangleAreas;

  double get totalArea => triangleAreas.fold(0, (sum, area) => sum + area);
}

abstract final class PolygonAreaCalculator {
  static PolygonAreaResult calculate({
    required List<double> outerSides,
    required List<double> diagonals,
  }) {
    if (outerSides.length < 5) {
      throw const FormatException('外周は5辺以上入力してください');
    }
    if (diagonals.length != outerSides.length - 3) {
      throw const FormatException('辺数に対応する対角線を入力してください');
    }
    if ([
      ...outerSides,
      ...diagonals,
    ].any((value) => !value.isFinite || value <= 0)) {
      throw const FormatException('すべての長さに0より大きい数値を入力してください');
    }

    final triangles = <(double, double, double)>[
      (outerSides[0], outerSides[1], diagonals[0]),
      for (var index = 1; index < diagonals.length; index++)
        (diagonals[index - 1], outerSides[index + 1], diagonals[index]),
      (diagonals.last, outerSides[outerSides.length - 2], outerSides.last),
    ];

    return PolygonAreaResult(
      triangleAreas: [
        for (final (a, b, c) in triangles) _triangleArea(a, b, c),
      ],
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
