import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';

void main() {
  test('四捨五入・切り上げ・切り捨てで正式数量を確定する', () {
    expect(
      finalizeEstimateQuantity(
        12.34567,
        decimalPlaces: 3,
        roundingMode: EstimateQuantityRoundingMode.halfUp,
      ),
      12.346,
    );
    expect(
      finalizeEstimateQuantity(
        12.34567,
        decimalPlaces: 2,
        roundingMode: EstimateQuantityRoundingMode.halfUp,
      ),
      12.35,
    );
    expect(
      finalizeEstimateQuantity(
        12.34567,
        decimalPlaces: 2,
        roundingMode: EstimateQuantityRoundingMode.floor,
      ),
      12.34,
    );
    expect(
      finalizeEstimateQuantity(
        12.341,
        decimalPlaces: 2,
        roundingMode: EstimateQuantityRoundingMode.ceiling,
      ),
      12.35,
    );
  });

  test('1～5桁、0、負数、非常に小さい値を現在の入力仕様のまま処理する', () {
    for (var places = 1; places <= 5; places++) {
      expect(
        finalizeEstimateQuantity(
          1.234567,
          decimalPlaces: places,
          roundingMode: EstimateQuantityRoundingMode.halfUp,
        ),
        isA<double>(),
      );
    }
    expect(
      finalizeEstimateQuantity(
        0,
        decimalPlaces: 2,
        roundingMode: EstimateQuantityRoundingMode.halfUp,
      ),
      0,
    );
    expect(
      finalizeEstimateQuantity(
        -12.345,
        decimalPlaces: 2,
        roundingMode: EstimateQuantityRoundingMode.halfUp,
      ),
      -12.35,
    );
    expect(
      finalizeEstimateQuantity(
        0.000001,
        decimalPlaces: 5,
        roundingMode: EstimateQuantityRoundingMode.ceiling,
      ),
      0.00001,
    );
  });

  test('数量表示は不要な末尾0だけを除き保存値を再丸めしない', () {
    expect(formatEstimateQuantity(null), '');
    expect(formatEstimateQuantity(0), '0');
    expect(formatEstimateQuantity(12), '12');
    expect(formatEstimateQuantity(12.3), '12.3');
    expect(formatEstimateQuantity(12.34), '12.34');
    expect(formatEstimateQuantity(12.346), '12.346');
    expect(formatEstimateQuantity(12.34567), '12.34567');
    expect(formatEstimateQuantity(12.340), '12.34');
    expect(formatEstimateQuantity(17.90), '17.9');
    expect(formatEstimateQuantity(-12.340), '-12.34');
    expect(formatEstimateQuantity(123456789.12345), '123456789.12345');
  });
}
