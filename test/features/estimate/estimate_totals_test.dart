import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_totals.dart';
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

  test('行金額は0.5を絶対値の大きい整数へ丸める', () {
    expect(estimateLineAmount(_item('1', quantity: 1.5, unitPrice: 1)), 2);
    expect(estimateLineAmount(_item('2', quantity: 2.5, unitPrice: 1)), 3);
    expect(estimateLineAmount(_item('3', quantity: -1.5, unitPrice: 1)), -2);
    expect(estimateLineAmount(_item('4', quantity: -2.5, unitPrice: 1)), -3);
  });

  test('各行を丸めてから税抜合計を計算する', () {
    final items = [
      _item('1', quantity: 1.5, unitPrice: 1),
      _item('2', quantity: 2.5, unitPrice: 1),
      _item('3', quantity: 199.4, unitPrice: 10),
    ];

    expect(items.map(estimateLineAmount), [2, 3, 1994]);
    expect(estimateSubtotal(items), 1999);
    expect(estimateTax(1999), 199);
    expect(estimateGrandTotal(items), 2198);
  });

  test('税抜合計1995円の税額と税込総額を計算する', () {
    final items = [_item('1', quantity: 199.5, unitPrice: 10)];

    expect(estimateSubtotal(items), 1995);
    expect(estimateTax(1995), 199);
    expect(estimateGrandTotal(items), 2194);
  });

  test('表計算数式はDartと同じ行丸めと税のfloorを使用する', () {
    expect(estimateLineAmountSpreadsheetFormula('D2', 'F2'), 'ROUND(D2*F2,0)');
    expect(estimateTaxSpreadsheetFormula('G8'), 'INT(G8*10%)');
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
