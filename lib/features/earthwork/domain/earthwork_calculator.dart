class EarthworkCalculationResult {
  const EarthworkCalculationResult({
    required this.lengthMeters,
    required this.widthMeters,
    required this.depthMeters,
    required this.structureVolumeCubicMeters,
    required this.soilChangeFactor,
    required this.dumpCapacityCubicMeters,
  });

  final double lengthMeters;
  final double widthMeters;
  final double depthMeters;
  final double structureVolumeCubicMeters;
  final double soilChangeFactor;
  final double dumpCapacityCubicMeters;

  double get excavationVolume => lengthMeters * widthMeters * depthMeters;

  double get backfillVolume => excavationVolume - structureVolumeCubicMeters;

  double get haulVolume => excavationVolume * soilChangeFactor;

  int get dumpTrips => (haulVolume / dumpCapacityCubicMeters).ceil();
}

abstract final class EarthworkCalculator {
  static EarthworkCalculationResult calculate({
    required double lengthMeters,
    required double widthMeters,
    required double depthMeters,
    required double structureVolumeCubicMeters,
    required double soilChangeFactor,
    required double dumpCapacityCubicMeters,
  }) {
    final requiredPositiveValues = [
      lengthMeters,
      widthMeters,
      depthMeters,
      soilChangeFactor,
      dumpCapacityCubicMeters,
    ];
    if (requiredPositiveValues.any((value) => !value.isFinite || value <= 0)) {
      throw const FormatException('寸法・変化率・積載容量には0より大きい数値を入力してください');
    }
    if (!structureVolumeCubicMeters.isFinite ||
        structureVolumeCubicMeters < 0) {
      throw const FormatException('構造物体積には0以上の数値を入力してください');
    }

    final result = EarthworkCalculationResult(
      lengthMeters: lengthMeters,
      widthMeters: widthMeters,
      depthMeters: depthMeters,
      structureVolumeCubicMeters: structureVolumeCubicMeters,
      soilChangeFactor: soilChangeFactor,
      dumpCapacityCubicMeters: dumpCapacityCubicMeters,
    );
    if (structureVolumeCubicMeters > result.excavationVolume) {
      throw const FormatException('構造物体積が掘削量を超えています');
    }
    return result;
  }
}
