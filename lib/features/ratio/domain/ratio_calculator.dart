enum RatioTerm { a, b, c, d }

class RatioCalculationResult {
  const RatioCalculationResult({
    required this.missingTerm,
    required this.value,
    required this.formula,
  });

  final RatioTerm missingTerm;
  final double value;
  final String formula;
}

class RatioCalculator {
  const RatioCalculator();

  RatioCalculationResult calculate({
    required double? a,
    required double? b,
    required double? c,
    required double? d,
  }) {
    final values = <RatioTerm, double?>{
      RatioTerm.a: a,
      RatioTerm.b: b,
      RatioTerm.c: c,
      RatioTerm.d: d,
    };
    final missing = values.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList(growable: false);

    if (missing.length != 1) {
      throw const FormatException('4項目のうち3項目を入力してください');
    }
    for (final value in values.values.whereType<double>()) {
      if (!value.isFinite || value <= 0) {
        throw const FormatException('0より大きい数値を入力してください');
      }
    }

    final missingTerm = missing.single;
    final (value, formula) = switch (missingTerm) {
      RatioTerm.a => (b! * c! / d!, 'A ＝ B × C ÷ D'),
      RatioTerm.b => (a! * d! / c!, 'B ＝ A × D ÷ C'),
      RatioTerm.c => (a! * d! / b!, 'C ＝ A × D ÷ B'),
      RatioTerm.d => (b! * c! / a!, 'D ＝ B × C ÷ A'),
    };
    if (!value.isFinite || value <= 0) {
      throw const FormatException('この値では計算できません');
    }
    return RatioCalculationResult(
      missingTerm: missingTerm,
      value: value,
      formula: formula,
    );
  }
}
