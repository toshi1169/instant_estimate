import 'dart:io';

import 'package:excel_plus/excel_plus.dart';

import '../../settings/domain/company_profile.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_totals.dart';

const _coverSheetName = '御見積書';
const _breakdownSheetName = '内訳';
const _grandTotalDefinedName = 'EstimateGrandTotal';
const _breakdownHeaders = ['記号', '名称', '仕様', '数量', '単位', '単価', '金額', '摘要'];
const _quantityFormat = '#,##0.#####';
const _moneyFormat = '#,##0';
const _breakdownBlockRows = 20;
const _breakdownDataRows = 17;

List<int> buildEstimateWorkbook({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
  CompanyProfile companyProfile = const CompanyProfile(),
}) {
  final itemList = items.toList(growable: false);
  final excel = Excel.createExcel();
  excel.rename('Sheet1', _coverSheetName);
  final coverSheet = excel[_coverSheetName];
  final breakdownSheet = excel[_breakdownSheetName];
  excel.setDefaultSheet(_coverSheetName);
  coverSheet.showGridLines = false;
  breakdownSheet.showGridLines = false;

  final grandTotalRow = _writeBreakdownSheet(breakdownSheet, itemList);
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

Future<File> createEstimateWorkbookFile({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
  CompanyProfile companyProfile = const CompanyProfile(),
}) async {
  final directory = await Directory.systemTemp.createTemp('instant_estimate_');
  final file = File(
    '${directory.path}/${_safeFileName(info.displayName)}.xlsx',
  );
  final bytes = buildEstimateWorkbook(
    info: info,
    items: items,
    companyProfile: companyProfile,
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
    29.25,
    10.5,
    32.25,
    30.75,
    30.75,
    41.25,
    36.0,
    39.75,
    39.0,
    24.75,
    21.75,
    24.75,
    16.5,
    24.75,
    38.25,
    35.25,
  ];
  for (var column = 0; column < widths.length; column++) {
    sheet.setColumnWidth(column, widths[column]);
  }
  for (var row = 0; row < heights.length; row++) {
    sheet.setRowHeight(row, heights[row]);
  }

  _mergeText(sheet, 'A1', 'P1', '御見積書', _coverTitleStyle());
  _mergeText(
    sheet,
    'C3',
    'I3',
    info.siteName.trim().isEmpty ? '' : '現場名：${info.siteName.trim()}',
    _coverFieldStyle(fontSize: 14),
  );
  _setText(sheet, 'O2', _japaneseEraDate(info.createdDate), _coverDateStyle());
  _mergeText(
    sheet,
    'C4',
    'I4',
    _clientWithoutHonorific(info.clientName),
    _coverClientStyle(),
  );
  _setText(sheet, 'J4', '様', _coverHonorificStyle());

  _mergeText(sheet, 'B6', 'C6', '金 額', _coverAmountLabelStyle());
  _setText(sheet, 'D6', '￥', _coverYenStyle());
  sheet.merge(
    CellIndex.indexByString('F6'),
    CellIndex.indexByString('K6'),
    customValue: FormulaCellValue(_grandTotalDefinedName),
  );
  sheet.cell(CellIndex.indexByString('F6')).cellStyle = _coverAmountStyle();

  _setText(
    sheet,
    'F7',
    '但',
    _coverFieldStyle(horizontal: HorizontalAlign.Center),
  );
  _mergeText(
    sheet,
    'G7',
    'N7',
    info.proviso.trim(),
    _coverFieldStyle(wrap: true),
  );
  _mergeText(
    sheet,
    'I8',
    'P8',
    '内訳別紙明細書の通り',
    _coverFieldStyle(horizontal: HorizontalAlign.Center),
  );
  _mergeText(
    sheet,
    'B9',
    'P9',
    '上記の通り御見積申し上げますので、何卒ご用命の程お願い申し上げます。',
    _coverStatementStyle(),
  );

  _mergeText(sheet, 'B11', 'D11', '見積有効期限', _coverLabelStyle());
  _mergeText(sheet, 'E11', 'G11', '（発行日より）', _coverHelperStyle());
  _mergeText(
    sheet,
    'H11',
    'M11',
    info.validityPeriod.trim(),
    _coverValueStyle(),
  );
  _mergeText(sheet, 'B13', 'D13', '工期', _coverLabelStyle());
  _mergeText(
    sheet,
    'H13',
    'M13',
    info.constructionPeriod.trim(),
    _coverValueStyle(),
  );
  _mergeText(sheet, 'B15', 'D15', '御支払条件', _coverLabelStyle());
  _mergeText(sheet, 'H15', 'M15', info.paymentTerms.trim(), _coverValueStyle());

  final postalAddress = [
    if (companyProfile.postalCode.trim().isNotEmpty)
      '〒${companyProfile.postalCode.trim()}',
    if (companyProfile.addressLine1.trim().isNotEmpty)
      companyProfile.addressLine1.trim(),
  ].join(' ');
  _mergeText(sheet, 'O13', 'P13', postalAddress, _companyStyle());
  _mergeText(
    sheet,
    'O14',
    'P14',
    companyProfile.addressLine2.trim(),
    _companyStyle(),
  );
  _mergeText(
    sheet,
    'O15',
    'P15',
    companyProfile.companyName.trim(),
    _companyStyle(),
  );
  _mergeText(
    sheet,
    'O16',
    'P16',
    companyProfile.representativeName.trim(),
    _companyStyle(),
  );
  _applyCoverBorders(sheet);
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

int _writeBreakdownSheet(Sheet sheet, List<EstimateItem> items) {
  const widths = [4.83, 28.0, 24.83, 10.5, 5.5, 11.5, 14.5, 23.17, 6.17, 0.91];
  for (var column = 0; column < widths.length; column++) {
    sheet.setColumnWidth(column, widths[column]);
  }

  final writer = _BreakdownWriter(sheet);
  final groups = _groupItemsByLocation(items);
  var groupNumber = 1;
  var firstGroup = true;
  for (final entry in groups.entries) {
    final rowsNeeded = entry.value.length + 2;
    if (!firstGroup && writer.usedDataRows > 0) {
      final needWithGap = rowsNeeded <= _breakdownDataRows ? rowsNeeded + 1 : 3;
      if (writer.remainingDataRows < needWithGap) {
        writer.startNextPage();
      } else {
        writer.writeBlankRow();
      }
    }
    if (rowsNeeded <= _breakdownDataRows &&
        writer.remainingDataRows < rowsNeeded) {
      writer.startNextPage();
    }

    writer.writeLocationRow(_groupMarker(groupNumber), entry.key);
    final detailRows = <int>[];
    for (final item in entry.value) {
      if (writer.remainingDataRows == 0) writer.startNextPage();
      detailRows.add(writer.writeItemRow(item));
    }
    if (writer.remainingDataRows == 0) writer.startNextPage();
    writer.writeSubtotalRow(detailRows);
    groupNumber++;
    firstGroup = false;
  }

  if (writer.usedDataRows > 0) {
    if (writer.remainingDataRows < 4) {
      writer.startNextPage();
    } else {
      writer.writeBlankRow();
    }
  } else if (writer.remainingDataRows < 3) {
    writer.startNextPage();
  }
  final grandTotalRow = writer.writeSummaryRows();
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
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: start),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: start),
      customValue: TextCellValue('内訳書'),
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: start))
            .cellStyle =
        _breakdownTitleStyle();
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: start),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: start),
      customValue: TextCellValue('No. ${pageIndex + 1}'),
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: start))
            .cellStyle =
        _breakdownPageNumberStyle();
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
      9,
      _breakdownHeaders[7],
      _breakdownHeaderStyle(),
    );
  }

  void startNextPage() {
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
    _mergeRowText(sheet, row, 7, 9, '', _locationTextStyle());
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
        3 => _quantityFormat,
        5 || 6 => _moneyFormat,
        _ => null,
      };
      _setCell(
        sheet,
        row,
        column,
        values[column],
        _detailStyle(
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
      9,
      item.description,
      _detailStyle(horizontal: HorizontalAlign.Left, fontSize: fontSize),
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

  int writeSummaryRows() {
    final taxExcludedRow = _nextRow;
    _writeSummaryRow(taxExcludedRow, '税抜合計');
    _setCell(
      sheet,
      taxExcludedRow,
      6,
      FormulaCellValue(_sumCellReferences('G', subtotalRows)),
      _summaryStyle(numberFormat: _moneyFormat),
    );
    usedDataRows++;

    final taxRow = _nextRow;
    _writeSummaryRow(taxRow, '消費税（10%）');
    _setCell(
      sheet,
      taxRow,
      6,
      FormulaCellValue(estimateTaxSpreadsheetFormula('G${taxExcludedRow + 1}')),
      _summaryStyle(numberFormat: _moneyFormat),
    );
    usedDataRows++;

    final totalRow = _nextRow;
    _writeSummaryRow(totalRow, '税込総額', emphasized: true);
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
    for (var row = _nextRow; row < finalRow; row++) {
      _writeEmptyBreakdownRow(sheet, row);
      sheet.setRowHeight(row, 30);
    }
    sheet.setPrintArea(
      CellIndex.indexByString('A1'),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: finalRow - 1),
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
}

Map<String, List<EstimateItem>> _groupItemsByLocation(
  List<EstimateItem> items,
) {
  final grouped = <String, List<EstimateItem>>{};
  for (final item in items) {
    final location = item.constructionLocation.trim();
    grouped.putIfAbsent(location, () => <EstimateItem>[]).add(item);
  }
  return grouped;
}

void _writeEmptyBreakdownRow(Sheet sheet, int row, {CellStyle? style}) {
  final resolvedStyle = style ?? _detailStyle(horizontal: HorizontalAlign.Left);
  for (var column = 0; column < 7; column++) {
    _setCell(sheet, row, column, TextCellValue(''), resolvedStyle);
  }
  _mergeRowText(sheet, row, 7, 9, '', resolvedStyle);
}

void _mergeRowText(
  Sheet sheet,
  int row,
  int fromColumn,
  int toColumn,
  String text,
  CellStyle style,
) {
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: fromColumn, rowIndex: row),
    CellIndex.indexByColumnRow(columnIndex: toColumn, rowIndex: row),
    customValue: TextCellValue(text),
  );
  sheet
          .cell(
            CellIndex.indexByColumnRow(columnIndex: fromColumn, rowIndex: row),
          )
          .cellStyle =
      style;
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
  _applyBottomBorder(sheet, 5, 1, 10, _thinBorder());
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
  fontSize: 12,
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Bottom,
);

CellStyle _coverClientStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 18,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _mediumBorder(),
);

CellStyle _coverHonorificStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 18,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Bottom,
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
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Bottom,
  bottomBorder: _thinBorder(),
);

CellStyle _coverAmountStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 22,
  bold: true,
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Bottom,
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
  horizontalAlign: HorizontalAlign.Center,
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
  bottomBorder: _thinBorder(),
);

CellStyle _companyStyle({int fontSize = 16}) => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: fontSize,
  horizontalAlign: HorizontalAlign.Left,
  verticalAlign: VerticalAlign.Bottom,
  textWrapping: TextWrapping.WrapText,
);

CellStyle _breakdownTitleStyle() => CellStyle(
  fontFamily: 'MS Pゴシック',
  fontSize: 20,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
);

CellStyle _breakdownPageNumberStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 11,
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Bottom,
);

CellStyle _breakdownHeaderStyle() => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 11,
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
  textWrapping: TextWrapping.WrapText,
  leftBorder: _thinBorder(),
  rightBorder: _thinBorder(),
  topBorder: _thinBorder(),
  bottomBorder: _thinBorder(),
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
  leftBorder: _thinBorder(),
  rightBorder: _thinBorder(),
  topBorder: _thinBorder(),
  bottomBorder: _thinBorder(),
);

CellStyle _subtotalStyle({String? numberFormat}) => CellStyle(
  fontFamily: 'MS P明朝',
  fontSize: 11,
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Center,
  numberFormat: numberFormat == null
      ? NumFormat.standard_0
      : NumFormat.custom(formatCode: numberFormat),
  leftBorder: _thinBorder(),
  rightBorder: _thinBorder(),
  topBorder: _thinBorder(),
  bottomBorder: _thinBorder(),
);

CellStyle _summaryStyle({String? numberFormat}) =>
    _subtotalStyle(numberFormat: numberFormat).copyWith(boldVal: true);

CellStyle _totalStyle({String? numberFormat}) => _summaryStyle(
  numberFormat: numberFormat,
).copyWith(topBorderVal: _mediumBorder(), bottomBorderVal: _mediumBorder());

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

Border _thinBorder() => Border(
  borderStyle: BorderStyle.Thin,
  borderColorHex: ExcelColor.fromHexString('#808080'),
);

Border _mediumBorder() =>
    Border(borderStyle: BorderStyle.Medium, borderColorHex: ExcelColor.black);

String _clientWithoutHonorific(String value) {
  final client = value.trim();
  return client.endsWith('様')
      ? client.substring(0, client.length - 1).trimRight()
      : client;
}

String _japaneseEraDate(DateTime date) {
  if (!date.isBefore(DateTime(2019, 5, 1))) {
    final year = date.year - 2018;
    return '令和${year == 1 ? '元' : year}年${date.month}月${date.day}日';
  }
  if (!date.isBefore(DateTime(1989, 1, 8))) {
    final year = date.year - 1988;
    return '平成${year == 1 ? '元' : year}年${date.month}月${date.day}日';
  }
  return '${date.year}年${date.month}月${date.day}日';
}

String _groupMarker(int number) {
  const markers = [
    '①',
    '②',
    '③',
    '④',
    '⑤',
    '⑥',
    '⑦',
    '⑧',
    '⑨',
    '⑩',
    '⑪',
    '⑫',
    '⑬',
    '⑭',
    '⑮',
    '⑯',
    '⑰',
    '⑱',
    '⑲',
    '⑳',
  ];
  return number <= markers.length ? markers[number - 1] : '($number)';
}

String _safeFileName(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
      .trim();
  return sanitized.isEmpty ? '見積書' : sanitized;
}
