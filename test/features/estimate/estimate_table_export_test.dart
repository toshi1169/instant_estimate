import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_table_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_totals.dart';

void main() {
  test('Excel貼り付け用の記号・小計・合計をタブ区切りで生成する', () {
    final items = [
      EstimateItem.fromDraft(
        const EstimateItemDraft(
          trade: '土工事',
          name: '根切り',
          specification: 'W1.2 × H0.5',
          quantity: 7.2,
          unit: 'm³',
          unitPrice: 4500,
          description: '小運搬含む',
        ),
        id: 'item-1',
        createdAt: DateTime(2026, 8, 3),
      ),
      EstimateItem.fromDraft(
        const EstimateItemDraft(
          trade: '内装工事',
          name: 'クロス貼り',
          quantity: 40,
          unit: 'm²',
        ),
        id: 'item-2',
        createdAt: DateTime(2026, 8, 3),
      ),
    ];

    expect(
      buildEstimateTableText(
        items,
        info: _info(taxEnabled: true, taxRateBasisPoints: 1000),
      ),
      '記号\t名称\t仕様\t数量\t単位\t単価\t金額\t摘要\n'
      '①\t根切り\tW1.2 × H0.5\t7.2\tm³\t4500\t=ROUND(D2*F2,0)\t小運搬含む\n'
      '\t\t\t\t\t小計\t=SUM(G2:G2)\t\n'
      '\t\t\t\t\t\t\t\n'
      '②\tクロス貼り\t\t40\tm²\t\t=ROUND(D5*F5,0)\t\n'
      '\t\t\t\t\t小計\t=SUM(G5:G5)\t\n'
      '\t\t\t\t\t\t\t\n'
      '\t\t\t\t\t税抜合計\t=SUM(G3,G6)\t\n'
      '\t\t\t\t\t消費税（10%）\t=INT(G8*1000/10000)\t\n'
      '\t\t\t\t\t税込総額\t=G8+G9\t',
    );
  });

  test('改行とタブを除去しExcelで式になる文字列を保護する', () {
    final item = EstimateItem.fromDraft(
      const EstimateItemDraft(
        trade: '外構\n工事',
        name: '=1+1',
        specification: '既存\t撤去',
        quantity: 1,
        unit: '式',
        unitPrice: -500,
        description: '@SUM(A1:A2)',
      ),
      id: 'item-1',
      createdAt: DateTime(2026, 8, 3),
    );

    final row = buildEstimateTableText(
      [item],
      info: _info(taxEnabled: true, taxRateBasisPoints: 1000),
    ).split('\n').firstWhere((row) => row.contains("'=1+1"));
    expect(row, "①\t'=1+1\t既存 撤去\t1\t式\t-500\t=ROUND(D2*F2,0)\t'@SUM(A1:A2)");
  });

  test('工種名は出力せず同じ工種を同じ記号と小計にまとめる', () {
    final items = [
      EstimateItem.fromDraft(
        const EstimateItemDraft(
          trade: 'ブロック工事',
          name: 'CB積み',
          quantity: 10,
          unit: '本',
          unitPrice: 1000,
        ),
        id: 'item-1',
        createdAt: DateTime(2026, 8, 5),
      ),
      EstimateItem.fromDraft(
        const EstimateItemDraft(
          trade: 'ブロック工事',
          name: 'CB天端',
          quantity: 5,
          unit: 'm',
          unitPrice: 400,
        ),
        id: 'item-2',
        createdAt: DateTime(2026, 8, 5),
      ),
    ];

    final text = buildEstimateTableText(
      items,
      info: _info(taxEnabled: true, taxRateBasisPoints: 1000),
    );
    expect(text, isNot(contains('ブロック工事')));
    expect(RegExp('①').allMatches(text), hasLength(1));
    expect(text, isNot(contains('②')));
    expect(text, contains('小計\t=SUM(G2:G3)'));
    expect(text, contains('税抜合計'));
    expect(text, contains('消費税（10%）'));
    expect(text, contains('税込総額'));
  });

  test('小数明細でも共通計算と一致する行丸め・小計・税計算式を生成する', () {
    final items = [
      _item('1', quantity: 1.5, unitPrice: 1),
      _item('2', quantity: 2.5, unitPrice: 1),
      _item('3', quantity: 199.4, unitPrice: 10),
    ];
    final text = buildEstimateTableText(
      items,
      info: _info(taxEnabled: true, taxRateBasisPoints: 1000),
    );

    expect(estimateSubtotal(items), 1999);
    expect(estimateTax(estimateSubtotal(items)), 199);
    expect(estimateGrandTotal(items), 2198);
    expect(text, contains('=ROUND(D2*F2,0)'));
    expect(text, contains('=ROUND(D3*F3,0)'));
    expect(text, contains('=ROUND(D4*F4,0)'));
    expect(text, contains('小計\t=SUM(G2:G4)'));
    expect(text, contains('税抜合計\t=SUM(G5)'));
    expect(text, contains('消費税（10%）\t=INT(G7*1000/10000)'));
    expect(text, contains('税込総額\t=G7+G8'));
  });

  test('Excelコピーは正式数量を再丸めせず行金額数式から参照する', () {
    final item = _item('formal', quantity: 12.346, unitPrice: 100);
    final text = buildEstimateTableText([
      item,
    ], info: _info(taxEnabled: true, taxRateBasisPoints: 1000));

    expect(text, contains('\t12.346\t式\t100\t=ROUND(D2*F2,0)'));
    expect(estimateSubtotal([item]), 1235);
  });

  test('Excelコピーは見積税率を使用し税OFFでは合計だけを出力する', () {
    final item = _item('tax', quantity: 12.345, unitPrice: 100);
    final taxed = buildEstimateTableText([
      item,
    ], info: _info(taxEnabled: true, taxRateBasisPoints: 825));
    expect(taxed, contains('税抜合計'));
    expect(taxed, contains('消費税（8.25%）\t=INT(G5*825/10000)'));
    expect(taxed, contains('税込総額\t=G5+G6'));

    final untaxed = buildEstimateTableText([
      item,
    ], info: _info(taxEnabled: false, taxRateBasisPoints: 825));
    expect(untaxed, contains('\t合計\t=SUM(G3)'));
    expect(untaxed, isNot(contains('税抜')));
    expect(untaxed, isNot(contains('消費税')));
    expect(untaxed, isNot(contains('税込')));
  });
}

EstimateInfo _info({
  required bool taxEnabled,
  required int taxRateBasisPoints,
}) => EstimateInfo(
  id: 'estimate-tax',
  estimateName: '税設定確認',
  siteName: '',
  clientName: '',
  createdDate: DateTime(2026, 9, 28),
  estimateNumber: '',
  notes: '',
  taxEnabled: taxEnabled,
  taxRateBasisPoints: taxRateBasisPoints,
);

EstimateItem _item(
  String id, {
  required double quantity,
  required double unitPrice,
}) => EstimateItem.fromDraft(
  EstimateItemDraft(
    trade: '端数確認',
    name: '端数明細$id',
    quantity: quantity,
    unit: '式',
    unitPrice: unitPrice,
  ),
  id: id,
  createdAt: DateTime(2026, 8, 12),
);
