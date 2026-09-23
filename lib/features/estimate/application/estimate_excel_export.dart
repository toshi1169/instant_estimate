import 'dart:io';

import 'package:excel_plus/excel_plus.dart';

import '../../settings/domain/company_profile.dart';
import 'estimate_export_file_name.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_symbol.dart';
import '../domain/estimate_quantity.dart';
import '../domain/estimate_totals.dart';

const _coverSheetName = '御見積書';
const _breakdownSheetName = '内訳';
const _grandTotalDefinedName = 'EstimateGrandTotal';
const _breakdownHeaders = ['記号', '名称', '仕様', '数量', '単位', '単価', '金額', '摘要'];
const _moneyFormat = '#,##0';
const _breakdownBlockRows = 20;
const _breakdownDataRows = 17;

List<int> buildEstimateWorkbook({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
  CompanyProfile companyProfile = const CompanyProfile(),
  int estimateDecimalPlaces = 2,
}) {
  final itemList = items.toList(growable: false);
  final excel = Excel.createExcel();
  excel.rename('Sheet1', _coverSheetName);
  final coverSheet = excel[_coverSheetName];
  final breakdownSheet = excel[_breakdownSheetName];
  excel.setDefaultSheet(_coverSheetName);
  coverSheet.showGridLines = false;
  breakdownSheet.showGridLines = false;

  final grandTotalRow = _writeBreakdownSheet(
    breakdownSheet,
    itemList,
    estimateDecimalPlaces: estimateDecimalPlaces,
  );
  excel.setDefinedName(
    _grandTotalDefinedName,
    "'$_breakdownSheetName'!\$G\$$grandTotalRow",
  );
  _writeCoverSheet(coverSheet, info, companyProfile);

  excel.recalculate();
  final bytes = excel.save();
  if (bytes == null) throw StateError('Excel file could not be generated.');
  return bytes;
}

typedef EstimateWorkbookFileCreator =
    Future<File> Function({
      required EstimateInfo info,
      required Iterable<EstimateItem> items,
      required CompanyProfile companyProfile,
      required int estimateDecimalPlaces,
    });

Future<File> createEstimateWorkbookFile({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
  CompanyProfile companyProfile = const CompanyProfile(),
  int estimateDecimalPlaces = 2,
}) async {
  final directory = await Directory.systemTemp.createTemp('instant_estimate_');
  final file = File(
    '${directory.path}/${safeEstimateExportBaseName(info.displayName)}.xlsx',
  );
  final bytes = buildEstimateWorkbook(
    info: info,
    items: items,
    companyProfile: companyProfile,
    estimateDecimalPlaces: estimateDecimalPlaces,
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

void _writeCoverSheet(
  Sheet sheet,
  EstimateInfo info,
  CompanyProfile companyProfile,
) {
  const widths = [
    6.83,
    6.83,
    3.83,
    4.83,
    1.17,
    2.17,
    2.83,
    10.0,
    7.0,
    4.83,
    9.5,
    0.45,
    3.5,
    19.0,
    35.5,
    6.83,
  ];
  const heights = [
    60.0,
    22.0,
    23.0,
    32.25,
    30.75,
    30.75,
    41.25,
    36.0,
    39.75,
    39.0,
    24.75,
    24.75,
    24.75,
    24.75,
    24.75,
    38.25,
    18.75,
  ];
  for (var column = 0; column < widths.length; column++) {
    sheet.setColumnWidth(column, widths[column]);
  }
  for (var row = 0; row < heights.length; row++) {
    sheet.setRowHeight(row, heights[row]);
  }

  _mergeText(sheet, 'I1', 'N1', '御　見　積　書', _coverTitleStyle());
  _mergeText(sheet, 'C3', 'I3', '', _coverFieldStyle(fontSize: 14));
  _setText(sheet, 'O2', _westernDate(info.createdDate), _coverDateStyle());
  _mergeText(sheet, 'C4', 'J4', info.displayName, _coverEstimateNameStyle());

  _mergeText(sheet, 'B6', 'C6', '金 額', _coverAmountLabelStyle());
  _mergeText(sheet, 'F6', 'G6', '¥', _coverYenStyle());
  sheet.merge(
    CellIndex.indexByString('H6'),
    CellIndex.indexByString('M6'),
    customValue: FormulaCellValue(_grandTotalDefinedName),
  );
  sheet.cell(CellIndex.indexByString('H6')).cellStyle = _coverAmountStyle();

  _mergeText(sheet, 'F7', 'G7', '但', _coverProvisoLabelStyle());
  _mergeText(sheet, 'H7', 'N7', info.proviso.trim(), _coverProvisoValueStyle());
  _mergeText(
    sheet,
    'I8',
    'N9',
    '内 訳 別 紙 明 細 書 の 通 り',
    _coverBreakdownNoteStyle(),
  );
  _mergeText(
    sheet,
    'B10',
    'P10',
    '上記の通り御見積申し上げますので、何卒ご用命の程お願い申し上げます。',
    _coverStatementStyle(),
  );

  _mergeText(sheet, 'B11', 'D11', '見 積 有 効 期 限', _coverLabelStyle());
  _mergeText(sheet, 'E11', 'G11', '', _coverHelperStyle());
  _mergeText(
    sheet,
    'H11',
    'M11',
    info.validityPeriod.trim(),
    _coverValueStyle(),
  );
  _mergeText(sheet, 'B13', 'D13', '工 期', _coverLabelStyle());
  _mergeText(
    sheet,
    'H13',
    'M13',
    info.constructionPeriod.trim(),
    _coverValueStyle(),
  );
  _mergeText(sheet, 'B15', 'D15', '御 支 払 条 件', _coverLabelStyle());
  _mergeText(sheet, 'H15', 'M15', info.paymentTerms.trim(), _coverValueStyle());
  _mergeText(sheet, 'H16', 'M16', info.notes.trim(), _coverNotesStyle());

  _writeCompanyProfile(sheet, companyProfile);
  _applyCoverBorders(sheet);
  final notesStart = CellIndex.indexByString('H16');
  final notesStyle = _coverNotesStyle();
  sheet.setMergedCellStyle(notesStart, notesStyle);
  sheet.cell(notesStart).cellStyle = notesStyle;
  sheet.setPrintArea(
    CellIndex.indexByString('A1'),
    CellIndex.indexByString('P17'),
  );
  sheet.pageSetup = const PageSetup(
    orientation: PageOrientation.landscape,
    paperSize: PaperSize.a4,
    fitToWidth: 1,
    fitToHeight: 1,
    horizontalCentered: true,
    verticalCentered: true,
    margins: PageMargins(
      left: 13 / 25.4,
      right: 13 / 25.4,
      top: 17 / 25.4,
      bottom: 17 / 25.4,
      header: 0.2,
      footer: 0.2,
    ),
  );
}

void _writeCompanyProfile(Sheet sheet, CompanyProfile profile) {
  final values = <CompanyProfileSection, String>{
    CompanyProfileSection.companyName: profile.companyName.trim(),
    CompanyProfileSection.representativeName: profile.representativeName.trim(),
    CompanyProfileSection.postalCode: profile.postalCode.trim(),
    CompanyProfileSection.addressLine1: profile.addressLine1.trim(),
    CompanyProfileSection.addressLine2: profile.addressLine2.trim(),
    CompanyProfileSection.phoneNumber: profile.phoneNumber.trim(),
  };
  final visibleSections = profile.effectiveExcelVisibleSections.toSet();
  final lines = [
    for (final section in profile.effectiveDisplayOrder)
      if (visibleSections.contains(section) && values[section]!.isNotEmpty)
        values[section]!,
  ].take(5).toList(growable: false);

  for (var row = 11; row <= 16; row++) {
    _mergeText(
      sheet,
      'O$row',
      'P$row',
      row <= 15 && row - 11 < lines.length ? lines[row - 11] : '',
      row <= 15
          ? _companyInformationStyle()
          : _companyInformationReserveStyle(),
    );
  }
}

int _writeBreakdownSheet(
  Sheet sheet,
  List<EstimateItem> items, {
  required int estimateDecimalPlaces,
}) {
  const widths = [
    4.83,
    32.0,
    32.0,
    6.83,
    4.67,
    10.76,
    13.67,
    11.5,
    3.0,
    3.0,
    10.17,
  ];
  for (var column = 0; column < widths.length; column++) {
    sheet.setColumnWidth(column, widths[column]);
  }

  final writer = _BreakdownWriter(sheet);
  final groups = _groupItemsByLocation(items);
  final subtotalLabel = _subtotalLabel(groups.keys.map((group) => group.$1));
  var firstGroup = true;
  for (final entry in groups.entries) {
    if (!firstGroup && writer.usedDataRows > 0) {
      // 空欄・施工場所見出し・最低1明細を同じページに置けない場合だけ
      // 次ページへ送り、収まる分の明細は20行雛形内へ順に配置する。
      if (writer.remainingDataRows < 3) {
        writer.startNextPage();
      } else {
        writer.writeBlankRow();
      }
    }

    writer.writeLocationRow(entry.key.$1, entry.key.$2);
    final detailRows = <int>[];
    for (final item in entry.value) {
      if (writer.remainingDataRows == 0) writer.startNextPage();
      detailRows.add(writer.writeItemRow(item));
    }
    if (writer.remainingDataRows == 0) writer.startNextPage();
    writer.writeSubtotalRow(detailRows);
    firstGroup = false;
  }

  // 最後の小計の直後へ、空欄1行＋最終集計3行を連続配置する。
  // 4行分が収まらない場合は、空欄を含む集計ブロック全体を次ページへ送る。
  if (writer.usedDataRows > 0) {
    if (writer.remainingDataRows < 4) writer.startNextPage();
    writer.writeBlankRow();
  }
  final grandTotalRow = writer.writeSummaryRows(subtotalLabel: subtotalLabel);
  writer.finish();
  return grandTotalRow;
}

class _BreakdownWriter {
  _BreakdownWriter(this.sheet) {
    _writePageHeader();
  }

  final Sheet sheet;
  final List<int> subtotalRows = <int>[];
  var pageIndex = 0;
  var usedDataRows = 0;

  int get remainingDataRows => _breakdownDataRows - usedDataRows;
  int get _blockStart => pageIndex * _breakdownBlockRows;
  int get _nextRow => _blockStart + 3 + usedDataRows;

  void _writePageHeader() {
    final start = _blockStart;
    sheet.setRowHeight(start, 43.5);
    sheet.setRowHeight(start + 1, 12);
    sheet.setRowHeight(start + 2, 25.5);
    for (var row = start + 3; row <= start + 18; row++) {
      sheet.setRowHeight(row, 30);
    }
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: start),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: start),
      customValue: TextCellValue('　内　訳　書'),
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: start))
            .cellStyle =
        _breakdownTitleStyle();
    _setCell(
      sheet,
      start,
      10,
      TextCellValue('No.${pageIndex + 1}'),
      _breakdownPageNumberStyle(),
    );
    for (var column = 0; column < 7; column++) {
      _setCell(
        sheet,
        start + 2,
        column,
        TextCellValue(_breakdownHeaders[column]),
        _breakdownHeaderStyle(),
      );
    }
    _mergeRowText(
      sheet,
      start + 2,
      7,
      10,
      _breakdownHeaders[7],
      _breakdownDescriptionHeaderStyle(),
    );
  }

  void startNextPage() {
    _fillRemainingTemplateRows();
    pageIndex++;
    usedDataRows = 0;
    sheet.insertRowPageBreak(_blockStart);
    _writePageHeader();
  }

  void writeBlankRow() {
    _writeEmptyBreakdownRow(sheet, _nextRow);
    sheet.setRowHeight(_nextRow, 30);
    usedDataRows++;
  }

  void writeLocationRow(String marker, String location) {
    if (remainingDataRows == 0) startNextPage();
    final row = _nextRow;
    _setCell(sheet, row, 0, TextCellValue(marker), _locationMarkerStyle());
    _setCell(sheet, row, 1, TextCellValue(location), _locationTextStyle());
    for (var column = 2; column < 7; column++) {
      _setCell(sheet, row, column, TextCellValue(''), _locationTextStyle());
    }
    _mergeRowText(sheet, row, 7, 10, '', _breakdownDescriptionStyle());
    sheet.setRowHeight(row, 30);
    usedDataRows++;
  }

  int writeItemRow(EstimateItem item) {
    final row = _nextRow;
    final fontSize = _detailFontSize(item);
    final values = <CellValue>[
      TextCellValue(''),
      TextCellValue(item.name),
      TextCellValue(item.specification),
      _numberValue(item.quantity),
      TextCellValue(item.unit),
      _numberValue(item.unitPrice),
      FormulaCellValue(
        estimateLineAmountSpreadsheetFormula('D${row + 1}', 'F${row + 1}'),
      ),
    ];
    for (var column = 0; column < 7; column++) {
      final alignment = switch (column) {
        0 || 3 || 4 => HorizontalAlign.Center,
        5 || 6 => HorizontalAlign.Right,
        _ => HorizontalAlign.Left,
      };
      final format = switch (column) {
        3 => _quantityFormat(item.quantity),
        5 || 6 => _moneyFormat,
        _ => null,
      };
      _setCell(
        sheet,
        row,
        column,
        values[column],
        column == 1 || column == 2
            ? _breakdownItemTextStyle(fontSize: fontSize)
            : _detailStyle(
                horizontal: alignment,
                fontSize: fontSize,
                numberFormat: format,
              ),
      );
    }
    _mergeRowText(
      sheet,
      row,
      7,
      10,
      item.description,
      _breakdownDescriptionStyle(),
    );
    sheet.setRowHeight(row, 30);
    usedDataRows++;
    return row + 1;
  }

  void writeSubtotalRow(List<int> detailRows) {
    final row = _nextRow;
    _writeEmptyBreakdownRow(sheet, row, style: _subtotalStyle());
    _setCell(sheet, row, 1, TextCellValue('小計'), _subtotalStyle());
    _setCell(
      sheet,
      row,
      6,
      FormulaCellValue(_sumCellReferences('G', detailRows)),
      _subtotalStyle(numberFormat: _moneyFormat),
    );
    subtotalRows.add(row + 1);
    sheet.setRowHeight(row, 30);
    usedDataRows++;
  }

  int writeSummaryRows({required String subtotalLabel}) {
    final taxExcludedRow = _nextRow;
    _writeSummaryRow(taxExcludedRow, subtotalLabel);
    _setCell(
      sheet,
      taxExcludedRow,
      6,
      FormulaCellValue(_sumCellReferences('G', subtotalRows)),
      _summaryStyle(numberFormat: _moneyFormat),
    );
    usedDataRows++;

    final taxRow = _nextRow;
    _writeSummaryRow(taxRow, '消費税$estimateTaxPercentage%');
    _setCell(
      sheet,
      taxRow,
      6,
      FormulaCellValue(estimateTaxSpreadsheetFormula('G${taxExcludedRow + 1}')),
      _summaryStyle(numberFormat: _moneyFormat),
    );
    usedDataRows++;

    final totalRow = _nextRow;
    _writeSummaryRow(totalRow, '合計', emphasized: true);
    _setCell(
      sheet,
      totalRow,
      6,
      FormulaCellValue('G${taxExcludedRow + 1}+G${taxRow + 1}'),
      _totalStyle(numberFormat: _moneyFormat),
    );
    usedDataRows++;
    return totalRow + 1;
  }

  void _writeSummaryRow(int row, String label, {bool emphasized = false}) {
    final style = emphasized ? _totalStyle() : _summaryStyle();
    _writeEmptyBreakdownRow(sheet, row, style: style);
    _setCell(sheet, row, 1, TextCellValue(label), style);
    sheet.setRowHeight(row, 30);
  }

  void finish() {
    final completeBlocks = pageIndex + 1;
    final finalRow = completeBlocks * _breakdownBlockRows;
    _fillRemainingTemplateRows();
    sheet.setPrintArea(
      CellIndex.indexByString('A1'),
      CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: finalRow - 1),
    );
    sheet.pageSetup = const PageSetup(
      orientation: PageOrientation.landscape,
      paperSize: PaperSize.a4,
      scale: 92,
      horizontalCentered: true,
      margins: PageMargins(
        left: 13 / 25.4,
        right: 13 / 25.4,
        top: 9 / 25.4,
        bottom: 9 / 25.4,
        header: 0.15,
        footer: 0.15,
      ),
    );
  }

  void _fillRemainingTemplateRows() {
    final finalRow = (pageIndex + 1) * _breakdownBlockRows;
    for (var row = _nextRow; row < finalRow; row++) {
      _writeEmptyBreakdownRow(sheet, row);
      sheet.setRowHeight(row, 30);
    }
  }
}

Map<(String, String), List<EstimateItem>> _groupItemsByLocation(
  List<EstimateItem> items,
) {
  final locationsBySymbol = <String, String>{};
  for (final item in items) {
    final symbol = item.constructionSymbol.trim();
    final location = item.constructionLocation.trim();
    if (symbol.isNotEmpty && location.isNotEmpty) {
      locationsBySymbol.putIfAbsent(symbol, () => location);
    }
  }
  final grouped = <(String, String), List<EstimateItem>>{};
  for (final item in items) {
    final symbol = item.constructionSymbol.trim();
    final location = symbol.isEmpty
        ? item.constructionLocation.trim()
        : locationsBySymbol[symbol] ?? item.constructionLocation.trim();
    grouped.putIfAbsent((symbol, location), () => <EstimateItem>[]).add(item);
  }
  return grouped;
}

String _subtotalLabel(Iterable<String> groupSymbols) {
  final symbols = groupSymbols
      .map((symbol) => symbol.trim())
      .where((symbol) => symbol.isNotEmpty)
      .toSet()
      .toList();
  symbols.sort((left, right) {
    final leftIndex = estimateItemSymbols.indexOf(left);
    final rightIndex = estimateItemSymbols.indexOf(right);
    if (leftIndex >= 0 && rightIndex >= 0) {
      return leftIndex.compareTo(rightIndex);
    }
    if (leftIndex >= 0) return -1;
    if (rightIndex >= 0) return 1;
    return left.compareTo(right);
  });
  if (symbols.isEmpty) return '計';
  return '${symbols.join('+')} 計';
}

void _writeEmptyBreakdownRow(Sheet sheet, int row, {CellStyle? style}) {
  final resolvedStyle = style ?? _detailStyle(horizontal: HorizontalAlign.Left);
  for (var column = 0; column < 7; column++) {
    _setCell(sheet, row, column, TextCellValue(''), resolvedStyle);
  }
  _mergeRowText(sheet, row, 7, 10, '', _breakdownDescriptionStyle());
}

void _mergeRowText(
  Sheet sheet,
  int row,
  int fromColumn,
  int toColumn,
  String text,
  CellStyle style,
) {
  final start = CellIndex.indexByColumnRow(
    columnIndex: fromColumn,
    rowIndex: row,
  );
  sheet.merge(
    start,
    CellIndex.indexByColumnRow(columnIndex: toColumn, rowIndex: row),
    customValue: TextCellValue(text),
  );
  sheet.setMergedCellStyle(start, style);
  sheet.cell(start).cellStyle = style;
}

void _mergeText(
  Sheet sheet,
  String from,
  String to,
  String text,
  CellStyle style,
) {
  sheet.merge(
    CellIndex.indexByString(from),
    CellIndex.indexByString(to),
    customValue: TextCellValue(text),
  );
  sheet.cell(CellIndex.indexByString(from)).cellStyle = style;
}

void _setText(Sheet sheet, String cell, String text, CellStyle style) {
  sheet.updateCell(
    CellIndex.indexByString(cell),
    TextCellValue(text),
    cellStyle: style,
  );
}

void _setCell(
  Sheet sheet,
  int row,
  int column,
  CellValue value,
  CellStyle style,
) {
  sheet.updateCell(
    CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    value,
    cellStyle: style,
  );
}

CellValue _numberValue(double? value) {
  if (value == null) return TextCellValue('');
  if (value.isFinite && value == value.truncateToDouble()) {
    return IntCellValue(value.toInt());
  }
  return DoubleCellValue(value);
}

void _applyCoverBorders(Sheet sheet) {
  for (var row = 0; row < 17; row++) {
    for (var column = 0; column < 16; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      );
      final style = cell.cellStyle ?? CellStyle(fontFamily: 'MS P明朝');
      cell.cellStyle = style.copyWith(
        leftBorderVal: column == 0 ? _mediumBorder() : null,
        rightBorderVal: column == 15 ? _mediumBorder() : null,
        topBorderVal: row == 0 ? _mediumBorder() : null,
        bottomBorderVal: row == 16 ? _mediumBorder() : null,
      );
    }
  }
  _applyBottomBorder(sheet, 3, 2, 9, _mediumBorder());
  _applyBottomBorder(sheet, 5, 1, 12, _thinBorder());
  _applyBottomBorder(sheet, 6, 5, 13, _thinBorder());
  _applyBottomBorder(sheet, 10, 1, 12, _thinBorder());
  _applyBottomBorder(sheet, 12, 1, 12, _thinBorder());
  _applyBottomBorder(sheet, 14, 1, 12, _thinBorder());
}

void _applyBottomBorder(
  Sheet sheet,
  int row,
  int fromColumn,
  int toColumn,
  Border border,
) {
  for (var column = fromColumn; column <= toColumn; column++) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    );
    cell.cellStyle = (cell.cellStyle ?? CellStyle(fontFamily: 'MS P明朝'))
        .copyWith(bottomBorderVal: border);
  }
}

CellStyle _coverTitleStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 28,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
);

CellStyle _coverDateStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 16,
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Bottom,
);

CellStyle _coverEstimateNameStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 22,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.Clip,
  bottomBorder: _mediumBorder(),
);

CellStyle _coverAmountLabelStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 22,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _thinBorder(),
);

CellStyle _coverYenStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 22,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _thinBorder(),
);

CellStyle _coverAmountStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 22,
  bold: true,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  indent: 1,
  numberFormat: NumFormat.custom(formatCode: _moneyFormat),
  bottomBorder: _thinBorder(),
);

CellStyle _coverFieldStyle({
  int fontSize = 12,
  HorizontalAlign horizontal = HorizontalAlign.Left,
  bool wrap = false,
}) => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: fontSize,
  horizontalAlign: horizontal,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: wrap ? TextWrapping.WrapText : TextWrapping.Clip,
);

CellStyle _coverStatementStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 12,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Center,
  textWrapping: TextWrapping.WrapText,
);

CellStyle _coverLabelStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 12,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _thinBorder(),
);

CellStyle _coverProvisoLabelStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 16,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _thinBorder(),
);

CellStyle _coverProvisoValueStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 16,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.WrapText,
  bottomBorder: _thinBorder(),
);

CellStyle _coverBreakdownNoteStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 14,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
);

CellStyle _coverHelperStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 10,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _thinBorder(),
);

CellStyle _coverValueStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 12,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.Clip,
  bottomBorder: _thinBorder(),
);

CellStyle _coverNotesStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 10,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.WrapText,
  bottomBorder: _breakdownThinBorder(),
);

CellStyle _companyInformationStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 16,
  bold: true,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.Clip,
);

CellStyle _companyInformationReserveStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 10,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.Clip,
);

CellStyle _breakdownTitleStyle() => CellStyle(
  fontFamily: 'MS Pゴシック',
  fontSize: 26,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
);

CellStyle _breakdownPageNumberStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 10,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _dottedBorder(),
);

CellStyle _breakdownHeaderStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 11,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
  textWrapping: TextWrapping.WrapText,
  leftBorder: _breakdownThinBorder(),
  rightBorder: _breakdownThinBorder(),
  topBorder: _breakdownThinBorder(),
  bottomBorder: _breakdownThinBorder(),
);

CellStyle _breakdownDescriptionStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 11,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.Clip,
  leftBorder: _breakdownThinBorder(),
  rightBorder: _breakdownThinBorder(),
  topBorder: _breakdownThinBorder(),
  bottomBorder: _breakdownThinBorder(),
);

CellStyle _breakdownDescriptionHeaderStyle() =>
    _breakdownHeaderStyle().copyWith(verticalAlignVal: VerticalAlign.Bottom);

CellStyle _breakdownItemTextStyle({required int fontSize}) => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: fontSize,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Center,
  textWrapping: TextWrapping.WrapText,
  leftBorder: _breakdownThinBorder(),
  rightBorder: _breakdownThinBorder(),
  topBorder: _breakdownThinBorder(),
  bottomBorder: _breakdownThinBorder(),
);

CellStyle _locationMarkerStyle() =>
    _detailStyle(horizontal: HorizontalAlign.Center, fontSize: 11, bold: true);

CellStyle _locationTextStyle() =>
    _detailStyle(horizontal: HorizontalAlign.Left, fontSize: 11, bold: true);

CellStyle _detailStyle({
  required HorizontalAlign horizontal,
  int fontSize = 11,
  bool bold = false,
  String? numberFormat,
}) => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: fontSize,
  bold: bold,
  horizontalAlign: horizontal,
  verticalAlign: VerticalAlign.Center,
  textWrapping: TextWrapping.WrapText,
  numberFormat: numberFormat == null
      ? NumFormat.standard_0
      : NumFormat.custom(formatCode: numberFormat),
  leftBorder: _breakdownThinBorder(),
  rightBorder: _breakdownThinBorder(),
  topBorder: _breakdownThinBorder(),
  bottomBorder: _breakdownThinBorder(),
);

CellStyle _subtotalStyle({String? numberFormat}) => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 11,
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Center,
  numberFormat: numberFormat == null
      ? NumFormat.standard_0
      : NumFormat.custom(formatCode: numberFormat),
  leftBorder: _breakdownThinBorder(),
  rightBorder: _breakdownThinBorder(),
  topBorder: _breakdownThinBorder(),
  bottomBorder: _breakdownThinBorder(),
);

CellStyle _summaryStyle({String? numberFormat}) =>
    _subtotalStyle(numberFormat: numberFormat).copyWith(boldVal: true);

CellStyle _totalStyle({String? numberFormat}) =>
    _summaryStyle(numberFormat: numberFormat);

int _detailFontSize(EstimateItem item) {
  final longestLine = [item.name, item.specification, item.description]
      .expand((value) => value.split('\n'))
      .fold<int>(
        0,
        (length, value) => value.length > length ? value.length : length,
      );
  final lineCount = [item.name, item.specification, item.description]
      .map((value) => value.split('\n').length)
      .fold<int>(1, (count, value) => value > count ? value : count);
  return longestLine > 20 || lineCount > 1 ? 10 : 11;
}

String _sumCellReferences(String column, List<int> rows) {
  if (rows.isEmpty) return '0';
  return 'SUM(${rows.map((row) => '$column$row').join(',')})';
}

String _quantityFormat(double? value) {
  final formatted = formatEstimateQuantity(value);
  final decimalPoint = formatted.indexOf('.');
  if (decimalPoint < 0) return '#,##0';
  final decimalPlaces = (formatted.length - decimalPoint - 1).clamp(1, 5);
  return '#,##0.${List.filled(decimalPlaces, '0').join()}';
}

Border _thinBorder() => Border(
  borderStyle: BorderStyle.Thin,
  borderColorHex: ExcelColor.fromHexString('#808080'),
);

Border _breakdownThinBorder() =>
    Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.black);

Border _dottedBorder() =>
    Border(borderStyle: BorderStyle.Dotted, borderColorHex: ExcelColor.black);

Border _mediumBorder() =>
    Border(borderStyle: BorderStyle.Medium, borderColorHex: ExcelColor.black);

String _westernDate(DateTime date) => '${date.year}年${date.month}月${date.day}日';
