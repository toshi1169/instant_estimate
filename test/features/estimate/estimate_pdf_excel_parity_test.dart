import 'dart:convert';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_excel_export.dart';
import 'package:instant_estimate/features/estimate/application/estimate_pdf_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_totals.dart';

import 'fixtures/formal_estimate_comparison_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('同一Fixtureから正式XLSXと正式PDFを生成し内容とページ割付を一致させる', () async {
    final items = buildFormalEstimateComparisonItems();
    final settings = formalEstimateComparisonSettings;
    final workbookBytes = buildEstimateWorkbook(
      info: formalEstimateComparisonInfo,
      items: items,
      companyProfile: settings.companyProfile,
      estimateDecimalPlaces: settings.estimateDecimalPlaces,
    );
    final pdfBytes = await buildEstimatePdf(
      info: formalEstimateComparisonInfo,
      items: items,
      companyProfile: settings.companyProfile,
      estimateDecimalPlaces: settings.estimateDecimalPlaces,
    );

    expect(workbookBytes, isNotEmpty);
    expect(ascii.decode(pdfBytes.take(4).toList()), '%PDF');

    final excel = Excel.decodeBytes(workbookBytes);
    final cover = excel['御見積書'];
    final breakdown = excel['内訳'];
    final pdfPages = buildEstimatePdfBreakdownLayout(items);

    expect(excel.sheetOrder, ['御見積書', '内訳']);
    expect(breakdown.printArea, 'A1:K40');
    expect(pdfPages, hasLength(2));
    expect(pdfPages.map((page) => page.number), [1, 2]);
    expect(pdfPages.every((page) => page.rows.length == 17), isTrue);

    expect(_text(cover, 'C4'), formalEstimateComparisonInfo.displayName);
    expect(_text(cover, 'O2'), '2026年8月19日');
    expect(_formula(cover, 'H6'), 'EstimateGrandTotal');
    expect(_text(cover, 'H7'), formalEstimateComparisonInfo.proviso);
    expect(_text(cover, 'I8'), '内 訳 別 紙 明 細 書 の 通 り');
    expect(_text(cover, 'B10'), '上記の通り御見積申し上げますので、何卒ご用命の程お願い申し上げます。');
    expect(_text(cover, 'H11'), formalEstimateComparisonInfo.validityPeriod);
    expect(
      _text(cover, 'H13'),
      formalEstimateComparisonInfo.constructionPeriod,
    );
    expect(_text(cover, 'H15'), formalEstimateComparisonInfo.paymentTerms);
    expect(_text(cover, 'H16'), formalEstimateComparisonInfo.notes);

    final companyLines = estimatePdfCompanyProfileLines(
      settings.companyProfile,
    );
    expect(companyLines, hasLength(5));
    for (var index = 0; index < companyLines.length; index++) {
      expect(_text(cover, 'O${index + 11}'), companyLines[index]);
    }
    expect(companyLines, isNot(contains(settings.companyProfile.phoneNumber)));
    expect(
      _allText(excel),
      isNot(contains(formalEstimateComparisonInfo.clientName)),
    );
    expect(
      _allText(excel),
      isNot(contains(formalEstimateComparisonInfo.estimateNumber)),
    );
    expect(_allText(excel), isNot(contains('正式帳票には表示しない工種')));

    for (var pageIndex = 0; pageIndex < pdfPages.length; pageIndex++) {
      expect(_text(breakdown, 'K${pageIndex * 20 + 1}'), 'No.${pageIndex + 1}');
      for (var rowIndex = 0; rowIndex < 17; rowIndex++) {
        final excelRow = pageIndex * 20 + rowIndex + 4;
        _expectSameBreakdownRow(
          breakdown,
          excelRow,
          pdfPages[pageIndex].rows[rowIndex],
          settings.estimateDecimalPlaces,
        );
      }
    }

    expect(_text(breakdown, 'A4'), '①');
    expect(_text(breakdown, 'B4'), '西・北面　隣地側　土留CB');
    expect(_text(breakdown, 'B11'), '小計');
    expect(_text(breakdown, 'B12'), '');
    expect(_text(breakdown, 'A13'), '②');
    expect(_text(breakdown, 'B13'), '南　道路側　土留めブロック工事');
    expect(_text(breakdown, 'B20'), '道路側工事項目 7');
    expect(_text(breakdown, 'B24'), '小計');
    expect(_text(breakdown, 'B25'), '');
    expect(_text(breakdown, 'B26'), '①+② 計');
    expect(_text(breakdown, 'B27'), '消費税10%');
    expect(_text(breakdown, 'B28'), '合計');

    final firstSubtotal = estimateSubtotal(items.take(6));
    final secondSubtotal = estimateSubtotal(items.skip(6));
    final subtotal = estimateSubtotal(items);
    final tax = estimateTax(subtotal);
    final total = estimateGrandTotal(items);
    final pdfRows = pdfPages.expand((page) => page.rows).toList();
    final pdfSubtotals = pdfRows
        .where((row) => row.type == EstimatePdfRowType.subtotal)
        .map((row) => row.amount)
        .toList();

    expect(items.map(estimateLineAmount), [
      155547,
      1000,
      40700,
      3,
      1000,
      50000,
      699300,
      727700,
      756600,
      786000,
      815900,
      846300,
      877200,
    ]);
    expect(firstSubtotal, 248250);
    expect(secondSubtotal, 5509000);
    expect(pdfSubtotals, [firstSubtotal, secondSubtotal]);
    expect(subtotal, 5757250);
    expect(tax, 575725);
    expect(total, 6332975);
    expect(pdfRows.firstWhere((row) => row.label == '①+② 計').amount, subtotal);
    expect(pdfRows.firstWhere((row) => row.label == '消費税10%').amount, tax);
    expect(pdfRows.firstWhere((row) => row.label == '合計').amount, total);
    expect(_formula(breakdown, 'G11'), 'SUM(G5,G6,G7,G8,G9,G10)');
    expect(_formula(breakdown, 'G24'), 'SUM(G14,G15,G16,G17,G18,G19,G20)');
    expect(_formula(breakdown, 'G26'), 'SUM(G11,G24)');
    expect(_formula(breakdown, 'G27'), 'INT(G26*10%)');
    expect(_formula(breakdown, 'G28'), 'G26+G27');
    expect(
      excel.definedNames
          .singleWhere((name) => name.name == 'EstimateGrandTotal')
          .refersTo,
      "'内訳'!\$G\$28",
    );
  });
}

void _expectSameBreakdownRow(
  Sheet sheet,
  int excelRow,
  EstimatePdfRow pdfRow,
  int decimalPlaces,
) {
  switch (pdfRow.type) {
    case EstimatePdfRowType.location:
      expect(_text(sheet, 'A$excelRow'), pdfRow.symbol);
      expect(_text(sheet, 'B$excelRow'), pdfRow.location);
    case EstimatePdfRowType.item:
      final item = pdfRow.item!;
      expect(_text(sheet, 'B$excelRow'), item.name);
      expect(_text(sheet, 'C$excelRow'), item.specification);
      expect(_number(sheet, 'D$excelRow'), item.quantity);
      expect(
        formatEstimatePdfQuantity(item.quantity, decimalPlaces),
        item.quantity!.toStringAsFixed(decimalPlaces),
      );
      expect(_text(sheet, 'E$excelRow'), item.unit);
      expect(_number(sheet, 'F$excelRow'), item.unitPrice);
      expect(_formula(sheet, 'G$excelRow'), 'ROUND(D$excelRow*F$excelRow,0)');
      expect(_text(sheet, 'H$excelRow'), item.description);
      expect(
        sheet
            .cell(CellIndex.indexByString('D$excelRow'))
            .cellStyle
            ?.numberFormat
            .toString(),
        contains('#,##0.${List.filled(decimalPlaces, '0').join()}'),
      );
    case EstimatePdfRowType.subtotal:
      expect(_text(sheet, 'B$excelRow'), '小計');
      expect(_formula(sheet, 'G$excelRow'), startsWith('SUM('));
    case EstimatePdfRowType.blank:
      expect(_text(sheet, 'A$excelRow'), '');
      expect(_text(sheet, 'B$excelRow'), '');
      expect(_text(sheet, 'H$excelRow'), '');
    case EstimatePdfRowType.summary:
      expect(_text(sheet, 'B$excelRow'), pdfRow.label);
      expect(_formula(sheet, 'G$excelRow'), isNotEmpty);
    case EstimatePdfRowType.total:
      expect(_text(sheet, 'B$excelRow'), '合計');
      expect(_formula(sheet, 'G$excelRow'), isNotEmpty);
  }
}

String _text(Sheet sheet, String cell) {
  final value = sheet.cell(CellIndex.indexByString(cell)).value;
  return value is TextCellValue ? value.value.toString() : '';
}

String _formula(Sheet sheet, String cell) =>
    (sheet.cell(CellIndex.indexByString(cell)).value as FormulaCellValue)
        .formula;

double? _number(Sheet sheet, String cell) {
  return switch (sheet.cell(CellIndex.indexByString(cell)).value) {
    IntCellValue(:final value) => value.toDouble(),
    DoubleCellValue(:final value) => value,
    _ => null,
  };
}

List<String> _allText(Excel excel) => [
  for (final sheetName in excel.sheetOrder)
    for (final row in excel[sheetName].rows)
      for (final cell in row)
        if (cell?.value case TextCellValue(:final value)) value.toString(),
];
