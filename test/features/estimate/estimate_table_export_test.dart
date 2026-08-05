import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_table_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

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
      buildEstimateTableText(items),
      '記号\t名称\t仕様\t数量\t単位\t単価\t金額\t摘要\n'
      '①\t\t\t\t\t\t\t\n'
      '\t根切り\tW1.2 × H0.5\t7.2\tm³\t4500\t=D3*F3\t小運搬含む\n'
      '\t\t\t\t\t小計\t=SUM(G3:G3)\t\n'
      '\t\t\t\t\t\t\t\n'
      '②\t\t\t\t\t\t\t\n'
      '\tクロス貼り\t\t40\tm²\t\t=D7*F7\t\n'
      '\t\t\t\t\t小計\t=SUM(G7:G7)\t\n'
      '\t\t\t\t\t\t\t\n'
      '\t\t\t\t\t税抜合計\t=SUM(G4,G8)\t\n'
      '\t\t\t\t\t消費税（10%）\t=ROUNDDOWN(G10*10%,0)\t\n'
      '\t\t\t\t\t税込総額\t=G10+G11\t',
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

    final row = buildEstimateTableText([
      item,
    ]).split('\n').firstWhere((row) => row.contains("'=1+1"));
    expect(row, "\t'=1+1\t既存 撤去\t1\t式\t-500\t=D3*F3\t'@SUM(A1:A2)");
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

    final text = buildEstimateTableText(items);
    expect(text, isNot(contains('ブロック工事')));
    expect(RegExp('①').allMatches(text), hasLength(1));
    expect(text, isNot(contains('②')));
    expect(text, contains('小計\t=SUM(G3:G4)'));
    expect(text, contains('税抜合計'));
    expect(text, contains('消費税（10%）'));
    expect(text, contains('税込総額'));
  });
}
