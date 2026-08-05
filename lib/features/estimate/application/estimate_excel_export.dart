import 'dart:io';

import 'package:excel_plus/excel_plus.dart';

import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';

const _sheetName = '内訳';
const _headers = ['記号', '名称', '仕様', '数量', '単位', '単価', '金額', '摘要'];
const _numberFormat = '#,##0.###';
const _moneyFormat = '#,##0';

List<int> buildEstimateWorkbook({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
}) {
  final itemList = items.toList(growable: false);
  final excel = Excel.createExcel();
  excel.rename('Sheet1', _sheetName);
  excel.setDefaultSheet(_sheetName);
  final sheet = excel[_sheetName];
  sheet.showGridLines = false;

  _setColumnWidths(sheet);
  _writeTitle(sheet);
  _writeInfo(sheet, info);
  _writeHeader(sheet);

  var row = 5;
  final subtotalRows = <int>[];
  final groupedItems = _groupItems(itemList);
  var groupNumber = 1;
  for (final entry in groupedItems.entries) {
    final firstItemRow = row;
    for (var index = 0; index < entry.value.length; index++) {
      _writeItem(
        sheet,
        row,
        entry.value[index],
        marker: index == 0 ? _groupMarker(groupNumber) : '',
      );
      row++;
    }
    _writeSubtotal(sheet, row, firstItemRow, row - 1);
    subtotalRows.add(row);
    row += 2;
    groupNumber++;
  }

  final summaryEndRow = _writeSummary(sheet, row, subtotalRows);
  sheet.setPrintArea(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: summaryEndRow),
  );
  sheet.setPrintTitleRows(0, 4);
  sheet.pageSetup = const PageSetup(
    orientation: PageOrientation.landscape,
    paperSize: PaperSize.a4,
    fitToWidth: 1,
    fitToHeight: 0,
    horizontalCentered: true,
    margins: PageMargins.narrow(),
  );
  excel.recalculate();
  final bytes = excel.save();
  if (bytes == null) throw StateError('Excel file could not be generated.');
  return bytes;
}

Future<File> createEstimateWorkbookFile({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
}) async {
  final directory = await Directory.systemTemp.createTemp('instant_estimate_');
  final file = File(
    '${directory.path}/${_safeFileName(info.displayName)}.xlsx',
  );
  final bytes = buildEstimateWorkbook(info: info, items: items);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Map<String, List<EstimateItem>> _groupItems(List<EstimateItem> items) {
  final grouped = <String, List<EstimateItem>>{};
  for (final item in items) {
    final trade = item.trade.trim().isEmpty ? '工種未設定' : item.trade.trim();
    grouped.putIfAbsent(trade, () => []).add(item);
  }
  return grouped;
}

void _setColumnWidths(Sheet sheet) {
  const widths = [14.0, 25.0, 28.0, 11.0, 9.0, 13.0, 15.0, 25.0];
  for (var column = 0; column < widths.length; column++) {
    sheet.setColumnWidth(column, widths[column]);
  }
}

void _writeTitle(Sheet sheet) {
  sheet.merge(
    CellIndex.indexByString('A1'),
    CellIndex.indexByString('H2'),
    customValue: TextCellValue('内　訳　書'),
  );
  sheet.setRowHeight(0, 28);
  sheet.setRowHeight(1, 28);
  sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(
    fontFamily: 'Yu Gothic',
    fontSize: 18,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );
}

void _writeInfo(Sheet sheet, EstimateInfo info) {
  _mergeText(sheet, 'A3', 'D3', '見積名：${info.displayName}', _infoStyle());
  _mergeText(
    sheet,
    'E3',
    'H3',
    '現場名：${_fallback(info.siteName)}',
    _infoStyle(),
  );
  _mergeText(
    sheet,
    'A4',
    'D4',
    '宛名：${_fallback(info.clientName)}',
    _infoStyle(),
  );
  final date = info.createdDate;
  final dateText =
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  final number = info.estimateNumber.trim().isEmpty
      ? ''
      : '　No. ${info.estimateNumber.trim()}';
  _mergeText(sheet, 'E4', 'H4', '作成日：$dateText$number', _infoStyle());
  sheet.setRowHeight(2, 23);
  sheet.setRowHeight(3, 23);
}

void _writeHeader(Sheet sheet) {
  for (var column = 0; column < _headers.length; column++) {
    _setCell(sheet, 4, column, TextCellValue(_headers[column]), _headerStyle());
  }
  sheet.setRowHeight(4, 26);
}

void _writeItem(
  Sheet sheet,
  int row,
  EstimateItem item, {
  required String marker,
}) {
  final values = <CellValue>[
    TextCellValue(marker),
    TextCellValue(item.name),
    TextCellValue(item.specification),
    _numberValue(item.quantity),
    TextCellValue(item.unit),
    _numberValue(item.unitPrice),
    FormulaCellValue('D${row + 1}*F${row + 1}'),
    TextCellValue(item.description),
  ];
  for (var column = 0; column < values.length; column++) {
    final style = switch (column) {
      0 => _bodyStyle(horizontalAlign: HorizontalAlign.Center),
      3 => _bodyStyle(
        horizontalAlign: HorizontalAlign.Right,
        numberFormat: _numberFormat,
      ),
      4 => _bodyStyle(horizontalAlign: HorizontalAlign.Center),
      5 || 6 => _bodyStyle(
        horizontalAlign: HorizontalAlign.Right,
        numberFormat: _moneyFormat,
      ),
      _ => _bodyStyle(horizontalAlign: HorizontalAlign.Left),
    };
    _setCell(sheet, row, column, values[column], style);
  }
  sheet.setRowHeight(row, 34);
}

void _writeSubtotal(Sheet sheet, int row, int firstItemRow, int lastItemRow) {
  for (var column = 0; column < 8; column++) {
    _setCell(sheet, row, column, TextCellValue(''), _subtotalStyle());
  }
  _setCell(sheet, row, 5, TextCellValue('小計'), _subtotalStyle());
  _setCell(
    sheet,
    row,
    6,
    FormulaCellValue('SUM(G${firstItemRow + 1}:G${lastItemRow + 1})'),
    _subtotalStyle(numberFormat: _moneyFormat),
  );
  sheet.setRowHeight(row, 24);
}

int _writeSummary(Sheet sheet, int row, List<int> subtotalRows) {
  _writeSummaryRow(sheet, row, '税抜合計');
  final references = subtotalRows.map((row) => 'G${row + 1}').join(',');
  _setCell(
    sheet,
    row,
    6,
    FormulaCellValue(references.isEmpty ? '0' : 'SUM($references)'),
    _summaryStyle(numberFormat: _moneyFormat),
  );

  _writeSummaryRow(sheet, row + 1, '消費税（10%）');
  _setCell(
    sheet,
    row + 1,
    6,
    FormulaCellValue('ROUNDDOWN(G${row + 1}*10%,0)'),
    _summaryStyle(numberFormat: _moneyFormat),
  );

  _writeSummaryRow(sheet, row + 2, '税込総額', emphasized: true);
  _setCell(
    sheet,
    row + 2,
    6,
    FormulaCellValue('G${row + 1}+G${row + 2}'),
    _totalStyle(numberFormat: _moneyFormat),
  );
  return row + 2;
}

void _writeSummaryRow(
  Sheet sheet,
  int row,
  String label, {
  bool emphasized = false,
}) {
  final style = emphasized ? _totalStyle() : _summaryStyle();
  for (var column = 0; column < 8; column++) {
    _setCell(sheet, row, column, TextCellValue(''), style);
  }
  _setCell(sheet, row, 5, TextCellValue(label), style);
  sheet.setRowHeight(row, emphasized ? 28 : 24);
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

CellStyle _infoStyle() => CellStyle(
  fontFamily: 'Yu Gothic',
  fontSize: 10,
  verticalAlign: VerticalAlign.Center,
);

CellStyle _headerStyle() => CellStyle(
  fontFamily: 'Yu Gothic',
  fontSize: 10,
  bold: true,
  backgroundColorHex: ExcelColor.fromHexString('#E7E6E6'),
  horizontalAlign: HorizontalAlign.Center,
  verticalAlign: VerticalAlign.Center,
  leftBorder: _thinBorder(),
  rightBorder: _thinBorder(),
  topBorder: _mediumBorder(),
  bottomBorder: _mediumBorder(),
);

CellStyle _bodyStyle({
  required HorizontalAlign horizontalAlign,
  String? numberFormat,
}) => CellStyle(
  fontFamily: 'Yu Gothic',
  fontSize: 9,
  horizontalAlign: horizontalAlign,
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
  fontFamily: 'Yu Gothic',
  fontSize: 10,
  bold: true,
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Center,
  numberFormat: numberFormat == null
      ? NumFormat.standard_0
      : NumFormat.custom(formatCode: numberFormat),
  topBorder: _thinBorder(),
  bottomBorder: _mediumBorder(),
);

CellStyle _summaryStyle({String? numberFormat}) => CellStyle(
  fontFamily: 'Yu Gothic',
  fontSize: 10,
  bold: true,
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

CellStyle _totalStyle({String? numberFormat}) => CellStyle(
  fontFamily: 'Yu Gothic',
  fontSize: 11,
  bold: true,
  backgroundColorHex: ExcelColor.fromHexString('#E2F0D9'),
  horizontalAlign: HorizontalAlign.Right,
  verticalAlign: VerticalAlign.Center,
  numberFormat: numberFormat == null
      ? NumFormat.standard_0
      : NumFormat.custom(formatCode: numberFormat),
  topBorder: _mediumBorder(),
  bottomBorder: _mediumBorder(),
);

Border _thinBorder() => Border(
  borderStyle: BorderStyle.Thin,
  borderColorHex: ExcelColor.fromHexString('#808080'),
);

Border _mediumBorder() =>
    Border(borderStyle: BorderStyle.Medium, borderColorHex: ExcelColor.black);

String _fallback(String value) => value.trim().isEmpty ? '未設定' : value.trim();

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
