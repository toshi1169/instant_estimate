import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import 'estimate_totals.dart';

const _headers = ['記号', '名称', '仕様', '数量', '単位', '単価', '金額', '摘要'];
const _columnWidths = <int, pw.TableColumnWidth>{
  0: pw.FlexColumnWidth(0.55),
  1: pw.FlexColumnWidth(2.35),
  2: pw.FlexColumnWidth(2.25),
  3: pw.FlexColumnWidth(0.85),
  4: pw.FlexColumnWidth(0.7),
  5: pw.FlexColumnWidth(1.05),
  6: pw.FlexColumnWidth(1.25),
  7: pw.FlexColumnWidth(2.3),
};

Future<Uint8List> buildEstimatePdf({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
}) async {
  final itemList = items.toList(growable: false);
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSansJP-Bold.ttf'),
  );
  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final grouped = _groupItems(itemList);
  final subtotal = estimateSubtotal(itemList);
  final tax = estimateTax(subtotal);

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
      header: (context) => _pageHeader(info, context.pageNumber),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
        ),
      ),
      build: (_) => [
        _columnHeader(),
        ..._detailTables(grouped),
        pw.SizedBox(height: 8),
        _summaryTable(subtotal: subtotal, tax: tax),
      ],
    ),
  );
  return document.save();
}

Map<String, List<EstimateItem>> _groupItems(List<EstimateItem> items) {
  final grouped = <String, List<EstimateItem>>{};
  for (final item in items) {
    final trade = item.trade.trim().isEmpty ? '工種未設定' : item.trade.trim();
    grouped.putIfAbsent(trade, () => []).add(item);
  }
  return grouped;
}

pw.Widget _pageHeader(EstimateInfo info, int pageNumber) {
  final date = info.createdDate;
  final dateText =
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  final estimateNumber = info.estimateNumber.trim().isEmpty
      ? pageNumber.toString()
      : info.estimateNumber.trim();
  return pw.Column(
    children: [
      pw.Stack(
        children: [
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              '内　訳　書',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'No. $estimateNumber',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 7),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              '見積名：${info.displayName}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              '現場名：${_fallback(info.siteName)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              '宛名：${_fallback(info.clientName)}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              '作成日：$dateText',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
    ],
  );
}

pw.Widget _columnHeader() => pw.Table(
  columnWidths: _columnWidths,
  border: pw.TableBorder.all(width: 0.6),
  children: [
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: _headers
          .map((text) => _cell(text, bold: true, center: true, fontSize: 8))
          .toList(growable: false),
    ),
  ],
);

List<pw.Widget> _detailTables(Map<String, List<EstimateItem>> grouped) {
  final widgets = <pw.Widget>[];
  var number = 1;
  for (final entry in grouped.entries) {
    final groupItems = entry.value;
    widgets.add(
      pw.Table(
        columnWidths: _columnWidths,
        border: pw.TableBorder.all(width: 0.45),
        children: [
          pw.TableRow(
            children: [
              _cell(_groupMarker(number), bold: true, center: true),
              _cell(entry.key, bold: true),
              ...List.generate(6, (_) => _cell('')),
            ],
          ),
          ...groupItems.map(
            (item) => pw.TableRow(
              children: [
                _cell(''),
                _cell(item.name),
                _cell(item.specification),
                _cell(_number(item.quantity), right: true),
                _cell(item.unit, center: true),
                _cell(_moneyValue(item.unitPrice), right: true),
                _cell(_money(estimateLineAmount(item)), right: true),
                _cell(item.description),
              ],
            ),
          ),
          pw.TableRow(
            children: [
              ...List.generate(5, (_) => _cell('')),
              _cell('小計', bold: true, right: true),
              _cell(
                _money(estimateSubtotal(groupItems)),
                bold: true,
                right: true,
              ),
              _cell(''),
            ],
          ),
        ],
      ),
    );
    widgets.add(pw.SizedBox(height: 5));
    number++;
  }
  return widgets;
}

pw.Widget _summaryTable({required int subtotal, required int tax}) => pw.Align(
  alignment: pw.Alignment.centerRight,
  child: pw.SizedBox(
    width: 250,
    child: pw.Table(
      border: pw.TableBorder.all(width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        _summaryRow('税抜合計', subtotal),
        _summaryRow('消費税（10%）', tax),
        _summaryRow('税込総額', subtotal + tax, emphasized: true),
      ],
    ),
  ),
);

pw.TableRow _summaryRow(String label, int value, {bool emphasized = false}) =>
    pw.TableRow(
      decoration: emphasized
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: [
        _cell(label, bold: true, right: true, fontSize: emphasized ? 9 : 8),
        _cell(
          _money(value),
          bold: true,
          right: true,
          fontSize: emphasized ? 9 : 8,
        ),
      ],
    );

pw.Widget _cell(
  String text, {
  bool bold = false,
  bool center = false,
  bool right = false,
  double fontSize = 7.5,
}) => pw.Container(
  constraints: const pw.BoxConstraints(minHeight: 23),
  padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
  alignment: right
      ? pw.Alignment.centerRight
      : center
      ? pw.Alignment.center
      : pw.Alignment.centerLeft,
  child: pw.Text(
    text,
    softWrap: true,
    style: pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  ),
);

String _number(double? value) {
  if (value == null) return '';
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _moneyValue(double? value) => value == null ? '' : _money(value.round());

String _money(int value) {
  final digits = value.abs().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return value < 0 ? '-$formatted' : formatted;
}

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
