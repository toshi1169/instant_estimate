import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_pdf_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

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
}
