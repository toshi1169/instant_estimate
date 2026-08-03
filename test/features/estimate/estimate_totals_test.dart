import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_totals.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

void main() {
  test('税抜合計・消費税10%・税込総額を計算する', () {
    final items = [
      _item('1', quantity: 3, unitPrice: 4500),
      _item('2', quantity: 2.5, unitPrice: 1000),
    ];

    expect(estimateSubtotal(items), 16000);
    expect(estimateTax(16000), 1600);
    expect(estimateGrandTotal(items), 17600);
  });

  test('消費税の1円未満を切り捨てる', () {
    expect(estimateTax(12345), 1234);
  });
}

EstimateItem _item(
  String id, {
  required double quantity,
  required double unitPrice,
}) => EstimateItem.fromDraft(
  EstimateItemDraft(
    trade: '外構工事',
    name: 'テスト',
    quantity: quantity,
    unit: '式',
    unitPrice: unitPrice,
  ),
  id: id,
  createdAt: DateTime(2026, 8, 3),
);
