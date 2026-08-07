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

  static SlopeCalculationResult fromHeightAndSlopeLength({
    required double heightDifferenceMeters,
    required double slopeLengthMeters,
  }) {
    _validateLength(heightDifferenceMeters, '高さ');
    _validateLength(slopeLengthMeters, '法長');
    if (slopeLengthMeters <= heightDifferenceMeters) {
      throw const FormatException('法長は高さより大きい数値を入力してください');
    }
    final horizontalDistance = math.sqrt(
      slopeLengthMeters * slopeLengthMeters -
          heightDifferenceMeters * heightDifferenceMeters,
    );
    return calculate(
      horizontalDistanceMeters: horizontalDistance,
      inputType: SlopeInputType.heightDifference,
      inputValue: heightDifferenceMeters,
    );
  }

  static SlopeCalculationResult fromHorizontalAndSlopeLength({
    required double horizontalDistanceMeters,
    required double slopeLengthMeters,
  }) {
    _validateLength(horizontalDistanceMeters, '水平距離');
    _validateLength(slopeLengthMeters, '法長');
    if (slopeLengthMeters <= horizontalDistanceMeters) {
      throw const FormatException('法長は水平距離より大きい数値を入力してください');
    }
    final heightDifference = math.sqrt(
      slopeLengthMeters * slopeLengthMeters -
          horizontalDistanceMeters * horizontalDistanceMeters,
    );
    return calculate(
      horizontalDistanceMeters: horizontalDistanceMeters,
      inputType: SlopeInputType.heightDifference,
      inputValue: heightDifference,
    );
  }

  static SlopeCalculationResult fromSlopeLengthAndGradientRatio({
    required double slopeLengthMeters,
    required double gradientRatioDenominator,
  }) {
    _validateLength(slopeLengthMeters, '法長');
    if (!gradientRatioDenominator.isFinite || gradientRatioDenominator <= 0) {
      throw const FormatException('法勾配は0より大きい数値を入力してください');
    }
    final angle = math.atan(1 / gradientRatioDenominator);
    final horizontalDistance = slopeLengthMeters * math.cos(angle);
    return calculate(
      horizontalDistanceMeters: horizontalDistance,
      inputType: SlopeInputType.gradientRatio,
      inputValue: gradientRatioDenominator,
    );
  }

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

  static void _validateLength(double value, String label) {
    if (!value.isFinite || value <= 0) {
      throw FormatException('$labelは0より大きい数値を入力してください');
    }
  }
}
