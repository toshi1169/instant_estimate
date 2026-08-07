import 'dart:math' as math;

class EarthworkCalculationResult {
  const EarthworkCalculationResult({
    required this.lengthMeters,
    required this.widthMeters,
    required this.depthMeters,
    required this.structureVolumeCubicMeters,
    required this.soilChangeFactor,
    required this.loadCapacityCubicMeters,
  });

  final double lengthMeters;
  final double widthMeters;
  final double depthMeters;
  final double structureVolumeCubicMeters;
  final double soilChangeFactor;
  final double loadCapacityCubicMeters;

  double get excavationVolume => lengthMeters * widthMeters * depthMeters;

  double get backfillVolume => excavationVolume - structureVolumeCubicMeters;

  double get haulVolume => excavationVolume * soilChangeFactor;

  int get transportTrips => (haulVolume / loadCapacityCubicMeters).ceil();
}

class ExcavationHaulResult {
  const ExcavationHaulResult({
    required this.lengthMeters,
    required this.widthMeters,
    required this.depthMeters,
    required this.looseFactor,
    required this.loadCapacityCubicMeters,
  });

  final double lengthMeters;
  final double widthMeters;
  final double depthMeters;
  final double looseFactor;
  final double loadCapacityCubicMeters;

  double get bankVolume => lengthMeters * widthMeters * depthMeters;
  double get looseVolume => bankVolume * looseFactor;
  int get transportTrips => (looseVolume / loadCapacityCubicMeters).ceil();
}

class BackfillCalculationResult {
  const BackfillCalculationResult({
    required this.lengthMeters,
    required this.widthMeters,
    required this.depthMeters,
    required this.structureVolumeCubicMeters,
    required this.compactionFactor,
  });

  final double lengthMeters;
  final double widthMeters;
  final double depthMeters;
  final double structureVolumeCubicMeters;
  final double compactionFactor;

  double get excavationVolume => lengthMeters * widthMeters * depthMeters;
  double get backfillTargetVolume =>
      excavationVolume - structureVolumeCubicMeters;
  double get requiredBankVolume => backfillTargetVolume / compactionFactor;
  double get balanceVolume => excavationVolume - requiredBankVolume;
  bool get hasSurplus => balanceVolume >= 0;
}

class EmbankmentGeometry {
  const EmbankmentGeometry({
    required this.topLengthMeters,
    required this.topWidthMeters,
    required this.heightMeters,
    required this.hasSlope,
    required this.slopeRatioHorizontal,
  });

  final double topLengthMeters;
  final double topWidthMeters;
  final double heightMeters;
  final bool hasSlope;

  /// 垂直1に対する水平距離。断面図・法面計算との将来連携にも使用する。
  final double slopeRatioHorizontal;

  double get slopeHorizontalRun =>
      hasSlope ? heightMeters * slopeRatioHorizontal : 0;

  double get slopeLength => hasSlope
      ? math.sqrt(
          heightMeters * heightMeters + slopeHorizontalRun * slopeHorizontalRun,
        )
      : heightMeters;

  double get bottomLengthMeters => topLengthMeters + 2 * slopeHorizontalRun;
  double get bottomWidthMeters => topWidthMeters + 2 * slopeHorizontalRun;

  double get topArea => topLengthMeters * topWidthMeters;
  double get middleArea {
    final run = slopeHorizontalRun / 2;
    return (topLengthMeters + 2 * run) * (topWidthMeters + 2 * run);
  }

  double get bottomArea => bottomLengthMeters * bottomWidthMeters;

  /// 四周に同一勾配の法面を設けた形状を、角錐台のプリズモイダル公式で算出する。
  double get completedVolume => hasSlope
      ? heightMeters * (topArea + 4 * middleArea + bottomArea) / 6
      : topArea * heightMeters;
}

class EmbankmentCalculationResult {
  const EmbankmentCalculationResult({
    required this.geometry,
    required this.compactionFactor,
    required this.looseFactor,
    required this.loadCapacityCubicMeters,
  });

  final EmbankmentGeometry geometry;
  final double compactionFactor;
  final double looseFactor;
  final double loadCapacityCubicMeters;

  double get completedVolume => geometry.completedVolume;
  double get requiredBankVolume => completedVolume / compactionFactor;
  double get requiredIncomingLooseVolume => requiredBankVolume * looseFactor;
  int get transportTrips =>
      (requiredIncomingLooseVolume / loadCapacityCubicMeters).ceil();
}

abstract final class EarthworkCalculator {
  static ExcavationHaulResult calculateExcavationHaul({
    required double lengthMeters,
    required double widthMeters,
    required double depthMeters,
    required double looseFactor,
    required double loadCapacityCubicMeters,
  }) {
    _requirePositive([
      lengthMeters,
      widthMeters,
      depthMeters,
      looseFactor,
      loadCapacityCubicMeters,
    ], '寸法・ほぐし係数・積載容量');
    return ExcavationHaulResult(
      lengthMeters: lengthMeters,
      widthMeters: widthMeters,
      depthMeters: depthMeters,
      looseFactor: looseFactor,
      loadCapacityCubicMeters: loadCapacityCubicMeters,
    );
  }

  static BackfillCalculationResult calculateBackfill({
    required double lengthMeters,
    required double widthMeters,
    required double depthMeters,
    required double structureVolumeCubicMeters,
    required double compactionFactor,
  }) {
    _requirePositive([
      lengthMeters,
      widthMeters,
      depthMeters,
      compactionFactor,
    ], '寸法・締固め係数');
    if (structureVolumeCubicMeters < 0 ||
        !structureVolumeCubicMeters.isFinite) {
      throw const FormatException('控除する構造物体積には0以上の数値を入力してください');
    }
    final result = BackfillCalculationResult(
      lengthMeters: lengthMeters,
      widthMeters: widthMeters,
      depthMeters: depthMeters,
      structureVolumeCubicMeters: structureVolumeCubicMeters,
      compactionFactor: compactionFactor,
    );
    if (structureVolumeCubicMeters > result.excavationVolume) {
      throw const FormatException('控除する構造物体積が掘削体積を超えています');
    }
    return result;
  }

  static EmbankmentCalculationResult calculateEmbankment({
    required double topLengthMeters,
    required double topWidthMeters,
    required double heightMeters,
    required bool hasSlope,
    required double slopeRatioHorizontal,
    required double compactionFactor,
    required double looseFactor,
    required double loadCapacityCubicMeters,
  }) {
    _requirePositive([
      topLengthMeters,
      topWidthMeters,
      heightMeters,
      compactionFactor,
      looseFactor,
      loadCapacityCubicMeters,
      if (hasSlope) slopeRatioHorizontal,
    ], '寸法・係数・積載容量');
    final geometry = EmbankmentGeometry(
      topLengthMeters: topLengthMeters,
      topWidthMeters: topWidthMeters,
      heightMeters: heightMeters,
      hasSlope: hasSlope,
      slopeRatioHorizontal: hasSlope ? slopeRatioHorizontal : 0,
    );
    return EmbankmentCalculationResult(
      geometry: geometry,
      compactionFactor: compactionFactor,
      looseFactor: looseFactor,
      loadCapacityCubicMeters: loadCapacityCubicMeters,
    );
  }

  static EarthworkCalculationResult calculate({
    required double lengthMeters,
    required double widthMeters,
    required double depthMeters,
    required double structureVolumeCubicMeters,
    required double soilChangeFactor,
    required double loadCapacityCubicMeters,
  }) {
    final requiredPositiveValues = [
      lengthMeters,
      widthMeters,
      depthMeters,
      soilChangeFactor,
      loadCapacityCubicMeters,
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
      loadCapacityCubicMeters: loadCapacityCubicMeters,
    );
    if (structureVolumeCubicMeters > result.excavationVolume) {
      throw const FormatException('構造物体積が掘削量を超えています');
    }
    return result;
  }

  static void _requirePositive(List<double> values, String label) {
    if (values.any((value) => !value.isFinite || value <= 0)) {
      throw FormatException('$labelには0より大きい数値を入力してください');
    }
  }
}
