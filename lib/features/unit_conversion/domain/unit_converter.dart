import 'dart:math' as math;

enum UnitConversionCategory {
  length('長さ'),
  area('面積'),
  volume('体積'),
  weight('重量'),
  temperature('温度'),
  pressure('圧力'),
  gradient('勾配'),
  earthwork('土量変換');

  const UnitConversionCategory(this.label);

  final String label;
}

class UnitConversionUnit {
  const UnitConversionUnit(this.id, this.label);

  final String id;
  final String label;
}

class UnitConverter {
  const UnitConverter();

  static const _lengthUnits = <UnitConversionUnit>[
    UnitConversionUnit('mm', 'mm'),
    UnitConversionUnit('cm', 'cm'),
    UnitConversionUnit('m', 'm'),
    UnitConversionUnit('km', 'km'),
    UnitConversionUnit('shaku', '尺'),
    UnitConversionUnit('sun', '寸'),
    UnitConversionUnit('ken', '間'),
    UnitConversionUnit('ft', 'ft'),
    UnitConversionUnit('in', 'in'),
  ];
  static const _areaUnits = <UnitConversionUnit>[
    UnitConversionUnit('m2', '㎡'),
    UnitConversionUnit('tsubo', '坪'),
    UnitConversionUnit('ha', 'ha'),
    UnitConversionUnit('acre', 'acre'),
  ];
  static const _volumeUnits = <UnitConversionUnit>[
    UnitConversionUnit('l', 'L'),
    UnitConversionUnit('m3', '㎥'),
  ];
  static const _weightUnits = <UnitConversionUnit>[
    UnitConversionUnit('g', 'g'),
    UnitConversionUnit('kg', 'kg'),
    UnitConversionUnit('t', 't'),
    UnitConversionUnit('lb', 'lb'),
    UnitConversionUnit('hyo', '俵'),
  ];
  static const _temperatureUnits = <UnitConversionUnit>[
    UnitConversionUnit('c', '℃'),
    UnitConversionUnit('f', '℉'),
  ];
  static const _pressureUnits = <UnitConversionUnit>[
    UnitConversionUnit('mpa', 'MPa'),
    UnitConversionUnit('psi', 'psi'),
    UnitConversionUnit('bar', 'bar'),
    UnitConversionUnit('kgfcm2', 'kgf/cm²'),
  ];
  static const _gradientUnits = <UnitConversionUnit>[
    UnitConversionUnit('percent', '％'),
    UnitConversionUnit('ratio', '1:n'),
    UnitConversionUnit('degree', '°'),
  ];
  static const _earthworkUnits = <UnitConversionUnit>[
    UnitConversionUnit('natural', '地山'),
    UnitConversionUnit('loose', 'ほぐし'),
    UnitConversionUnit('compacted', '締固め'),
  ];

  List<UnitConversionUnit> unitsFor(UnitConversionCategory category) {
    return switch (category) {
      UnitConversionCategory.length => _lengthUnits,
      UnitConversionCategory.area => _areaUnits,
      UnitConversionCategory.volume => _volumeUnits,
      UnitConversionCategory.weight => _weightUnits,
      UnitConversionCategory.temperature => _temperatureUnits,
      UnitConversionCategory.pressure => _pressureUnits,
      UnitConversionCategory.gradient => _gradientUnits,
      UnitConversionCategory.earthwork => _earthworkUnits,
    };
  }

  double convert({
    required UnitConversionCategory category,
    required double value,
    required String fromUnitId,
    required String toUnitId,
    double loosenFactor = 1.25,
    double compactionFactor = 0.90,
  }) {
    if (!value.isFinite) {
      throw const FormatException('有効な数値を入力してください');
    }
    final unitIds = unitsFor(category).map((unit) => unit.id);
    if (!unitIds.contains(fromUnitId) || !unitIds.contains(toUnitId)) {
      throw const FormatException('変換する単位を選択してください');
    }
    if (fromUnitId == toUnitId) return value;

    return switch (category) {
      UnitConversionCategory.length =>
        _convertByFactor(value, fromUnitId, toUnitId, const {
          'mm': 0.001,
          'cm': 0.01,
          'm': 1,
          'km': 1000,
          'shaku': 10 / 33,
          'sun': 1 / 33,
          'ken': 20 / 11,
          'ft': 0.3048,
          'in': 0.0254,
        }),
      UnitConversionCategory.area => _convertByFactor(
        value,
        fromUnitId,
        toUnitId,
        const {'m2': 1, 'tsubo': 400 / 121, 'ha': 10000, 'acre': 4046.8564224},
      ),
      UnitConversionCategory.volume => _convertByFactor(
        value,
        fromUnitId,
        toUnitId,
        const {'l': 0.001, 'm3': 1},
      ),
      UnitConversionCategory.weight => _convertByFactor(
        value,
        fromUnitId,
        toUnitId,
        const {'g': 0.001, 'kg': 1, 't': 1000, 'lb': 0.45359237, 'hyo': 60},
      ),
      UnitConversionCategory.temperature => _convertTemperature(
        value,
        fromUnitId,
        toUnitId,
      ),
      UnitConversionCategory.pressure => _convertByFactor(
        value,
        fromUnitId,
        toUnitId,
        const {
          'mpa': 1000000,
          'psi': 6894.757293168,
          'bar': 100000,
          'kgfcm2': 98066.5,
        },
      ),
      UnitConversionCategory.gradient => _convertGradient(
        value,
        fromUnitId,
        toUnitId,
      ),
      UnitConversionCategory.earthwork => _convertEarthwork(
        value,
        fromUnitId,
        toUnitId,
        loosenFactor,
        compactionFactor,
      ),
    };
  }

  double _convertByFactor(
    double value,
    String from,
    String to,
    Map<String, double> factors,
  ) {
    return value * factors[from]! / factors[to]!;
  }

  double _convertTemperature(double value, String from, String to) {
    final celsius = from == 'c' ? value : (value - 32) * 5 / 9;
    return to == 'c' ? celsius : celsius * 9 / 5 + 32;
  }

  double _convertGradient(double value, String from, String to) {
    if (value < 0) {
      throw const FormatException('0以上の勾配を入力してください');
    }
    final decimalSlope = switch (from) {
      'percent' => value / 100,
      'ratio' when value > 0 => 1 / value,
      'ratio' => throw const FormatException('1:nのnには0より大きい数値を入力してください'),
      'degree' when value < 90 => math.tan(value * math.pi / 180),
      'degree' => throw const FormatException('角度は90°未満で入力してください'),
      _ => throw const FormatException('変換する単位を選択してください'),
    };
    return switch (to) {
      'percent' => decimalSlope * 100,
      'ratio' when decimalSlope > 0 => 1 / decimalSlope,
      'ratio' => throw const FormatException('水平勾配は1:nに変換できません'),
      'degree' => math.atan(decimalSlope) * 180 / math.pi,
      _ => throw const FormatException('変換する単位を選択してください'),
    };
  }

  double _convertEarthwork(
    double value,
    String from,
    String to,
    double loosenFactor,
    double compactionFactor,
  ) {
    if (value < 0) {
      throw const FormatException('0以上の土量を入力してください');
    }
    if (!loosenFactor.isFinite || loosenFactor <= 0) {
      throw const FormatException('ほぐし係数は0より大きい数値を入力してください');
    }
    if (!compactionFactor.isFinite || compactionFactor <= 0) {
      throw const FormatException('締固め係数は0より大きい数値を入力してください');
    }
    final factors = <String, double>{
      'natural': 1,
      'loose': loosenFactor,
      'compacted': compactionFactor,
    };
    final naturalVolume = value / factors[from]!;
    return naturalVolume * factors[to]!;
  }
}
