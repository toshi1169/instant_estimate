import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_pdf_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_totals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('日本語を含むA4横の印刷用PDFを生成する', () async {
    final bytes = await buildEstimatePdf(
      info: EstimateInfo(
        id: 'estimate-1',
        estimateName: '○○邸 外構工事',
        siteName: '○○邸',
        clientName: '○○様',
        createdDate: DateTime(2026, 8, 3),
        estimateNumber: '001',
        notes: '',
      ),
      items: [
        EstimateItem.fromDraft(
          const EstimateItemDraft(
            trade: '外構工事',
            name: '化粧ブロック積み',
            specification: 'スマートC120タイプ',
            quantity: 10,
            unit: '本',
            unitPrice: 1100,
            description: '色：ダークグレー',
          ),
          id: 'item-1',
          createdAt: DateTime(2026, 8, 3),
        ),
      ],
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('小数明細を共通金額計算で集計してPDFを生成する', () async {
    final items = [
      _item('1', quantity: 1.5, unitPrice: 1),
      _item('2', quantity: 2.5, unitPrice: 1),
      _item('3', quantity: 199.4, unitPrice: 10),
    ];

    expect(items.map(estimateLineAmount), [2, 3, 1994]);
    expect(estimateSubtotal(items), 1999);
    expect(estimateTax(estimateSubtotal(items)), 199);
    expect(estimateGrandTotal(items), 2198);

    final bytes = await buildEstimatePdf(
      info: EstimateInfo.initial(DateTime(2026, 8, 12)),
      items: items,
    );
    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('PDF数量は正式数量を3桁へ再丸めせずそのまま表示する', () {
    expect(formatEstimateQuantity(12.346), '12.346');
    expect(formatEstimateQuantity(12.34567), '12.34567');
    expect(formatEstimateQuantity(12.300), '12.3');
  });
}

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
