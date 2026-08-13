import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_excel_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_totals.dart';

void main() {
  test('A4横の内訳書を記号・小計・計算式付きで生成する', () {
    final bytes = buildEstimateWorkbook(
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
        _item(
          id: 'item-1',
          trade: '土工事',
          name: '根切り',
          quantity: 7.2,
          unit: 'm³',
          unitPrice: 4500,
        ),
        _item(
          id: 'item-2',
          trade: '土工事',
          name: '埋戻し',
          quantity: 3,
          unit: 'm³',
          unitPrice: 3000,
        ),
        _item(
          id: 'item-3',
          trade: '外構工事',
          name: 'フェンス',
          quantity: 10,
          unit: 'm',
          unitPrice: 8000,
        ),
      ],
    );

    expect(bytes, isNotEmpty);
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['内訳'];
    expect(
      sheet.cell(CellIndex.indexByString('A1')).value,
      TextCellValue('内　訳　書'),
    );
    expect(
      sheet.cell(CellIndex.indexByString('A5')).value,
      TextCellValue('記号'),
    );
    expect(sheet.cell(CellIndex.indexByString('A6')).value, TextCellValue('①'));
    expect(
      sheet.cell(CellIndex.indexByString('B6')).value,
      TextCellValue('根切り'),
    );
    expect(
      sheet.cell(CellIndex.indexByString('A10')).value,
      TextCellValue('②'),
    );
    expect(
      sheet.cell(CellIndex.indexByString('B10')).value,
      TextCellValue('フェンス'),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G6')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'ROUND(D6*F6,0)',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G8')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'SUM(G6:G7)',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G13')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'SUM(G8,G11)',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G14')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'INT(G13*10%)',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G15')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'G13+G14',
      ),
    );
    expect(sheet.pageSetup?.orientation, PageOrientation.landscape);
    expect(sheet.pageSetup?.paperSize, PaperSize.a4);
    expect(sheet.pageSetup?.fitToWidth, 1);
    expect(sheet.pageSetup?.fitToHeight, 0);
    expect(sheet.printArea, 'A1:H15');
    expect(sheet.printTitleRows, '1:5');
  });

  test('小数明細でも共通計算と同じ行丸め・小計・税計算式を生成する', () {
    final items = [
      _item(
        id: 'item-1',
        trade: '端数確認',
        name: '1.5円明細',
        quantity: 1.5,
        unit: '式',
        unitPrice: 1,
      ),
      _item(
        id: 'item-2',
        trade: '端数確認',
        name: '2.5円明細',
        quantity: 2.5,
        unit: '式',
        unitPrice: 1,
      ),
      _item(
        id: 'item-3',
        trade: '端数確認',
        name: '1,994円明細',
        quantity: 199.4,
        unit: '式',
        unitPrice: 10,
      ),
    ];
    final excel = Excel.decodeBytes(
      buildEstimateWorkbook(
        info: EstimateInfo.initial(DateTime(2026, 8, 12)),
        items: items,
      ),
    );
    final sheet = excel['内訳'];

    expect(estimateSubtotal(items), 1999);
    expect(estimateTax(estimateSubtotal(items)), 199);
    expect(estimateGrandTotal(items), 2198);
    expect(_formula(sheet, 'G6'), 'ROUND(D6*F6,0)');
    expect(_formula(sheet, 'G7'), 'ROUND(D7*F7,0)');
    expect(_formula(sheet, 'G8'), 'ROUND(D8*F8,0)');
    expect(_formula(sheet, 'G9'), 'SUM(G6:G8)');
    expect(_formula(sheet, 'G11'), 'SUM(G9)');
    expect(_formula(sheet, 'G12'), 'INT(G11*10%)');
    expect(_formula(sheet, 'G13'), 'G11+G12');
  });

  test('正式数量をセル内部値へ保持し行金額数式で参照する', () {
    final item = _item(
      id: 'formal-quantity',
      trade: '数量確認',
      name: '正式数量',
      quantity: 12.346,
      unit: 'm²',
      unitPrice: 100,
    );
    final excel = Excel.decodeBytes(
      buildEstimateWorkbook(
        info: EstimateInfo.initial(DateTime(2026, 8, 12)),
        items: [item],
      ),
    );
    final sheet = excel['内訳'];

    expect(
      sheet.cell(CellIndex.indexByString('D6')).value,
      DoubleCellValue(12.346),
    );
    expect(_formula(sheet, 'G6'), 'ROUND(D6*F6,0)');
    expect(estimateSubtotal([item]), 1235);
  });
}

String _formula(Sheet sheet, String cell) =>
    (sheet.cell(CellIndex.indexByString(cell)).value as FormulaCellValue)
        .formula;

EstimateItem _item({
  required String id,
  required String trade,
  required String name,
  required double quantity,
  required String unit,
  required double unitPrice,
}) {
  return EstimateItem.fromDraft(
    EstimateItemDraft(
      trade: trade,
      name: name,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
    ),
    id: id,
    createdAt: DateTime(2026, 8, 3),
  );
}
