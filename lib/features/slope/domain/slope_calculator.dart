import 'dart:math' as math;

enum SlopeInputType {
  heightDifference,
  gradientPercent,
  gradientRatio,
  angleDegrees,
}

class SlopeCalculationResult {
  const SlopeCalculationResult({
    required this.horizontalDistanceMeters,
    required this.heightDifferenceMeters,
    required this.gradientPercent,
    required this.gradientRatioDenominator,
    required this.angleDegrees,
    required this.slopeLengthMeters,
  });

  final double horizontalDistanceMeters;
  final double heightDifferenceMeters;
  final double gradientPercent;
  final double? gradientRatioDenominator;
  final double angleDegrees;
  final double slopeLengthMeters;
}

class SlopeCalculator {
  const SlopeCalculator._();

  static SlopeCalculationResult calculate({
    required double horizontalDistanceMeters,
    required SlopeInputType inputType,
    required double inputValue,
  }) {
    if (!horizontalDistanceMeters.isFinite || horizontalDistanceMeters <= 0) {
      throw const FormatException('水平距離は0より大きい数値を入力してください');
    }
    if (!inputValue.isFinite || inputValue < 0) {
      throw const FormatException('入力値は0以上の数値を入力してください');
    }
    if (inputType == SlopeInputType.gradientRatio && inputValue <= 0) {
      throw const FormatException('勾配比は0より大きい数値を入力してください');
    }
    if (inputType == SlopeInputType.angleDegrees && inputValue >= 90) {
      throw const FormatException('角度は0度以上90度未満で入力してください');
    }

    final slope = switch (inputType) {
      SlopeInputType.heightDifference => inputValue / horizontalDistanceMeters,
      SlopeInputType.gradientPercent => inputValue / 100,
      SlopeInputType.gradientRatio => 1 / inputValue,
      SlopeInputType.angleDegrees =>
        inputValue == 0 ? 0.0 : math.tan(inputValue * math.pi / 180),
    };
    final heightDifference = horizontalDistanceMeters * slope;
    return SlopeCalculationResult(
      horizontalDistanceMeters: horizontalDistanceMeters,
      heightDifferenceMeters: heightDifference,
      gradientPercent: slope * 100,
      gradientRatioDenominator: slope == 0 ? null : 1 / slope,
      angleDegrees: math.atan(slope) * 180 / math.pi,
      slopeLengthMeters: math.sqrt(
        horizontalDistanceMeters * horizontalDistanceMeters +
            heightDifference * heightDifference,
      ),
    );
  }
}
