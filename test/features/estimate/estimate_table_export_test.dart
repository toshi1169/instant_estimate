import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_table_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

void main() {
  test('Excel貼り付け用の8列をタブ区切りで生成する', () {
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
      '工種\t名称\t仕様\t数量\t単位\t単価\t金額\t摘要\n'
      '土工事\t根切り\tW1.2 × H0.5\t7.2\tm³\t4500\t32400\t小運搬含む\n'
      '内装工事\tクロス貼り\t\t40\tm²\t\t\t',
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

    final row = buildEstimateTableText([item]).split('\n').last;
    expect(row, "外構 工事\t'=1+1\t既存 撤去\t1\t式\t-500\t-500\t'@SUM(A1:A2)");
  });
}
