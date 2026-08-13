import 'dart:math' as math;

enum EstimateQuantityRoundingMode { halfUp, ceiling, floor }

double finalizeEstimateQuantity(
  double value, {
  required int decimalPlaces,
  required EstimateQuantityRoundingMode roundingMode,
}) {
  final places = decimalPlaces.clamp(1, 5);
  final factor = math.pow(10, places).toDouble();
  final scaled = value * factor;
  final rounded = switch (roundingMode) {
    EstimateQuantityRoundingMode.halfUp => scaled.roundToDouble(),
    EstimateQuantityRoundingMode.ceiling => scaled.ceilToDouble(),
    EstimateQuantityRoundingMode.floor => scaled.floorToDouble(),
  };
  return rounded / factor;
}

String formatEstimateQuantity(double? value) {
  if (value == null) return '';
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
}
