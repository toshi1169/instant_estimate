import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/unit_conversion/domain/unit_converter.dart';

void main() {
  const converter = UnitConverter();

  test('尺・mm・m・ft・inを相互変換できる', () {
    final meters = converter.convert(
      category: UnitConversionCategory.length,
      value: 1,
      fromUnitId: 'shaku',
      toUnitId: 'm',
    );
    expect(meters, closeTo(0.303030303, 0.000000001));

    final inches = converter.convert(
      category: UnitConversionCategory.length,
      value: 1,
      fromUnitId: 'ft',
      toUnitId: 'in',
    );
    expect(inches, closeTo(12, 0.000000001));
  });

  test('面積・体積・重量・圧力を基準単位経由で変換できる', () {
    expect(
      converter.convert(
        category: UnitConversionCategory.area,
        value: 1,
        fromUnitId: 'ha',
        toUnitId: 'm2',
      ),
      10000,
    );
    expect(
      converter.convert(
        category: UnitConversionCategory.volume,
        value: 1000,
        fromUnitId: 'l',
        toUnitId: 'm3',
      ),
      1,
    );
    expect(
      converter.convert(
        category: UnitConversionCategory.weight,
        value: 1,
        fromUnitId: 'hyo',
        toUnitId: 'kg',
      ),
      60,
    );
    expect(
      converter.convert(
        category: UnitConversionCategory.pressure,
        value: 1,
        fromUnitId: 'mpa',
        toUnitId: 'bar',
      ),
      closeTo(10, 0.000000001),
    );
  });

  test('摂氏と華氏を相互変換できる', () {
    expect(
      converter.convert(
        category: UnitConversionCategory.temperature,
        value: 0,
        fromUnitId: 'c',
        toUnitId: 'f',
      ),
      32,
    );
    expect(
      converter.convert(
        category: UnitConversionCategory.temperature,
        value: 212,
        fromUnitId: 'f',
        toUnitId: 'c',
      ),
      100,
    );
  });

  test('勾配の百分率・1:n・角度を相互変換できる', () {
    expect(
      converter.convert(
        category: UnitConversionCategory.gradient,
        value: 50,
        fromUnitId: 'percent',
        toUnitId: 'ratio',
      ),
      closeTo(2, 0.000000001),
    );
    expect(
      converter.convert(
        category: UnitConversionCategory.gradient,
        value: 1,
        fromUnitId: 'ratio',
        toUnitId: 'degree',
      ),
      closeTo(45, 0.000000001),
    );
  });

  test('地山・ほぐし・締固めを別係数で変換できる', () {
    expect(
      converter.convert(
        category: UnitConversionCategory.earthwork,
        value: 100,
        fromUnitId: 'natural',
        toUnitId: 'loose',
        loosenFactor: 1.25,
        compactionFactor: 0.9,
      ),
      125,
    );
    expect(
      converter.convert(
        category: UnitConversionCategory.earthwork,
        value: 125,
        fromUnitId: 'loose',
        toUnitId: 'compacted',
        loosenFactor: 1.25,
        compactionFactor: 0.9,
      ),
      90,
    );
  });

  test('不正な勾配と土量係数は拒否する', () {
    expect(
      () => converter.convert(
        category: UnitConversionCategory.gradient,
        value: 90,
        fromUnitId: 'degree',
        toUnitId: 'percent',
      ),
      throwsFormatException,
    );
    expect(
      () => converter.convert(
        category: UnitConversionCategory.earthwork,
        value: 10,
        fromUnitId: 'natural',
        toUnitId: 'loose',
        loosenFactor: 0,
      ),
      throwsFormatException,
    );
  });
}
