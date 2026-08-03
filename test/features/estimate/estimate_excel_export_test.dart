import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_excel_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

void main() {
  test('A4横の内訳書を工種小計と計算式付きで生成する', () {
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
      TextCellValue('土工事'),
    );
    expect(
      sheet.cell(CellIndex.indexByString('B7')).value,
      TextCellValue('根切り'),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G7')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'D7*F7',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G9')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'SUM(G7:G8)',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G15')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'SUM(G9,G13)',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G16')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'ROUNDDOWN(G15*10%,0)',
      ),
    );
    expect(
      sheet.cell(CellIndex.indexByString('G17')).value,
      isA<FormulaCellValue>().having(
        (value) => value.formula,
        'formula',
        'G15+G16',
      ),
    );
    expect(sheet.pageSetup?.orientation, PageOrientation.landscape);
    expect(sheet.pageSetup?.paperSize, PaperSize.a4);
    expect(sheet.pageSetup?.fitToWidth, 1);
    expect(sheet.pageSetup?.fitToHeight, 0);
    expect(sheet.printArea, 'A1:H17');
    expect(sheet.printTitleRows, '1:5');
  });
}

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
