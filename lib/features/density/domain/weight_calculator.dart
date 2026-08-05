class WeightCalculationResult {
  const WeightCalculationResult({
    required this.volumeCubicMeters,
    required this.densityTonnesPerCubicMeter,
  });

  final double volumeCubicMeters;
  final double densityTonnesPerCubicMeter;

  double get weightTonnes => volumeCubicMeters * densityTonnesPerCubicMeter;

  double get weightKilograms => weightTonnes * 1000;
}

abstract final class WeightCalculator {
  static WeightCalculationResult calculate({
    required double volumeCubicMeters,
    required double densityTonnesPerCubicMeter,
  }) {
    if (!volumeCubicMeters.isFinite || volumeCubicMeters <= 0) {
      throw const FormatException('体積に0より大きい数値を入力してください');
    }
    if (!densityTonnesPerCubicMeter.isFinite ||
        densityTonnesPerCubicMeter <= 0) {
      throw const FormatException('比重に0より大きい数値を入力してください');
    }
    return WeightCalculationResult(
      volumeCubicMeters: volumeCubicMeters,
      densityTonnesPerCubicMeter: densityTonnesPerCubicMeter,
    );
  }
}

class DensityMaterialPreset {
  const DensityMaterialPreset({required this.name, required this.density});

  final String name;
  final double density;
}

const densityMaterialPresets = <DensityMaterialPreset>[
  DensityMaterialPreset(name: 'RCコンクリート', density: 2.4),
  DensityMaterialPreset(name: '砕石', density: 1.8),
  DensityMaterialPreset(name: 'アスファルト', density: 2.35),
  DensityMaterialPreset(name: '砂', density: 1.7),
  DensityMaterialPreset(name: '山砂', density: 1.8),
  DensityMaterialPreset(name: '改良土', density: 1.7),
  DensityMaterialPreset(name: '残土', density: 1.6),
];
