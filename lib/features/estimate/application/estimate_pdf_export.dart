import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../settings/domain/company_profile.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_symbol.dart';
import '../domain/estimate_totals.dart';

const _headers = ['記号', '名称', '仕様', '数量', '単位', '単価', '金額', '摘要'];
const _breakdownDataRows = 17;
const _columnWidths = <int, pw.TableColumnWidth>{
  0: pw.FlexColumnWidth(4.83),
  1: pw.FlexColumnWidth(32),
  2: pw.FlexColumnWidth(32),
  3: pw.FlexColumnWidth(6.83),
  4: pw.FlexColumnWidth(4.67),
  5: pw.FlexColumnWidth(10.76),
  6: pw.FlexColumnWidth(13.67),
  7: pw.FlexColumnWidth(27.67),
};

Future<Uint8List> buildEstimatePdf({
  required EstimateInfo info,
  required Iterable<EstimateItem> items,
  CompanyProfile companyProfile = const CompanyProfile(),
  int estimateDecimalPlaces = 2,
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
  final pages = buildEstimatePdfBreakdownLayout(itemList);

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => _coverPage(
        info: info,
        items: itemList,
        companyProfile: companyProfile,
      ),
    ),
  );
  for (final page in pages) {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        build: (_) =>
            _breakdownPage(page, estimateDecimalPlaces: estimateDecimalPlaces),
      ),
    );
  }
  return document.save();
}

enum EstimatePdfRowType { location, item, subtotal, blank, summary, total }

@immutable
class EstimatePdfRow {
  const EstimatePdfRow._(
    this.type, {
    this.symbol = '',
    this.location = '',
    this.item,
    this.label = '',
    this.amount,
  });

  const EstimatePdfRow.location(String symbol, String location)
    : this._(EstimatePdfRowType.location, symbol: symbol, location: location);

  const EstimatePdfRow.item(EstimateItem item)
    : this._(EstimatePdfRowType.item, item: item);

  const EstimatePdfRow.subtotal(int amount)
    : this._(EstimatePdfRowType.subtotal, label: '小計', amount: amount);

  const EstimatePdfRow.blank() : this._(EstimatePdfRowType.blank);

  const EstimatePdfRow.summary(String label, int amount)
    : this._(EstimatePdfRowType.summary, label: label, amount: amount);

  const EstimatePdfRow.total(int amount)
    : this._(EstimatePdfRowType.total, label: '合計', amount: amount);

  final EstimatePdfRowType type;
  final String symbol;
  final String location;
  final EstimateItem? item;
  final String label;
  final int? amount;
}

@immutable
class EstimatePdfPageLayout {
  const EstimatePdfPageLayout({required this.number, required this.rows});

  final int number;
  final List<EstimatePdfRow> rows;
}

/// 正式XLSXと同じ17帳票行（20行雛形の4～20行）でページを割り付ける。
@visibleForTesting
List<EstimatePdfPageLayout> buildEstimatePdfBreakdownLayout(
  Iterable<EstimateItem> items,
) {
  final itemList = items.toList(growable: false);
  final groups = _groupItemsByLocation(itemList);
  final pages = <List<EstimatePdfRow>>[<EstimatePdfRow>[]];

  List<EstimatePdfRow> current() => pages.last;
  int remaining() => _breakdownDataRows - current().length;
  void startNextPage() => pages.add(<EstimatePdfRow>[]);
  void add(EstimatePdfRow row) => current().add(row);

  var firstGroup = true;
  for (final entry in groups.entries) {
    if (!firstGroup && current().isNotEmpty) {
      if (remaining() < 3) {
        startNextPage();
      } else {
        add(const EstimatePdfRow.blank());
      }
    }

    if (remaining() == 0) startNextPage();
    add(EstimatePdfRow.location(entry.key.$1, entry.key.$2));
    for (final item in entry.value) {
      if (remaining() == 0) startNextPage();
      add(EstimatePdfRow.item(item));
    }
    if (remaining() == 0) startNextPage();
    add(EstimatePdfRow.subtotal(estimateSubtotal(entry.value)));
    firstGroup = false;
  }

  if (current().isNotEmpty) {
    if (remaining() < 4) startNextPage();
    add(const EstimatePdfRow.blank());
  }
  final subtotal = estimateSubtotal(itemList);
  final tax = estimateTax(subtotal);
  add(
    EstimatePdfRow.summary(
      _subtotalLabel(groups.keys.map((key) => key.$1)),
      subtotal,
    ),
  );
  add(EstimatePdfRow.summary('消費税$estimateTaxPercentage%', tax));
  add(EstimatePdfRow.total(subtotal + tax));

  for (final page in pages) {
    while (page.length < _breakdownDataRows) {
      page.add(const EstimatePdfRow.blank());
    }
  }
  return [
    for (var index = 0; index < pages.length; index++)
      EstimatePdfPageLayout(
        number: index + 1,
        rows: List<EstimatePdfRow>.unmodifiable(pages[index]),
      ),
  ];
}

pw.Widget _coverPage({
  required EstimateInfo info,
  required List<EstimateItem> items,
  required CompanyProfile companyProfile,
}) {
  final subtotal = estimateSubtotal(items);
  final tax = estimateTax(subtotal);
  final companyLines = estimatePdfCompanyProfileLines(companyProfile);
  return pw.Container(
    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
    padding: const pw.EdgeInsets.fromLTRB(20, 14, 20, 14),
    child: pw.Column(
      children: [
        pw.SizedBox(
          height: 58,
          child: pw.Stack(
            children: [
              pw.Align(
                alignment: pw.Alignment.topCenter,
                child: pw.Text(
                  '御　見　積　書',
                  style: const pw.TextStyle(fontSize: 28),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text(
                  _westernDate(info.createdDate),
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
            width: 260,
            height: 48,
            margin: const pw.EdgeInsets.only(left: 60),
            padding: const pw.EdgeInsets.only(bottom: 3),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.8)),
            ),
            alignment: pw.Alignment.bottomCenter,
            child: _fitText(info.displayName, fontSize: 22),
          ),
        ),
        pw.SizedBox(height: 17),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
            width: 342,
            height: 43,
            margin: const pw.EdgeInsets.only(left: 25),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 70,
                  child: pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Text(
                      '金 額',
                      style: const pw.TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                pw.SizedBox(width: 35),
                pw.SizedBox(
                  width: 30,
                  child: pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Text(
                      '¥',
                      style: const pw.TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                pw.SizedBox(
                  width: 200,
                  child: pw.Align(
                    alignment: pw.Alignment.bottomLeft,
                    child: _fitText(
                      _money(subtotal + tax),
                      fontSize: 22,
                      bold: true,
                      alignment: pw.Alignment.bottomLeft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Container(
            width: 390,
            height: 42,
            margin: const pw.EdgeInsets.only(left: 100),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 48,
                  child: pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Text(
                      '但',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: _fitText(
                    info.proviso.trim(),
                    fontSize: 16,
                    alignment: pw.Alignment.bottomLeft,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(
          height: 42,
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              width: 290,
              margin: const pw.EdgeInsets.only(left: 250),
              child: pw.Center(
                child: pw.Text(
                  '内 訳 別 紙 明 細 書 の 通 り',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ),
        pw.SizedBox(
          height: 31,
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 25),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                '上記の通り御見積申し上げますので、何卒ご用命の程お願い申し上げます。',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.SizedBox(width: 24),
              pw.SizedBox(
                width: 342,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    _coverValueRow('見 積 有 効 期 限', info.validityPeriod),
                    _coverValueRow('工 期', info.constructionPeriod),
                    _coverValueRow('御 支 払 条 件', info.paymentTerms),
                    _coverValueRow('備 考', info.notes, height: 42, fontSize: 10),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.SizedBox(
                width: 280,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    for (final line in companyLines)
                      pw.SizedBox(
                        height: 30,
                        child: _fitText(
                          line,
                          fontSize: 16,
                          bold: true,
                          alignment: pw.Alignment.bottomLeft,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _coverValueRow(
  String label,
  String value, {
  double height = 31,
  double fontSize = 12,
}) => pw.Container(
  height: height,
  decoration: const pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
  ),
  child: pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.SizedBox(
        width: 95,
        child: pw.Align(
          alignment: pw.Alignment.bottomCenter,
          child: pw.Text(label, style: pw.TextStyle(fontSize: fontSize)),
        ),
      ),
      pw.SizedBox(width: 12),
      pw.Expanded(
        child: _fitText(
          value.trim(),
          fontSize: fontSize,
          alignment: pw.Alignment.bottomLeft,
        ),
      ),
    ],
  ),
);

pw.Widget _breakdownPage(
  EstimatePdfPageLayout page, {
  required int estimateDecimalPlaces,
}) => pw.Column(
  children: [
    pw.SizedBox(
      height: 43,
      child: pw.Stack(
        children: [
          pw.Align(
            alignment: pw.Alignment.bottomCenter,
            child: pw.Text('　内　訳　書', style: const pw.TextStyle(fontSize: 26)),
          ),
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Container(
              width: 60,
              padding: const pw.EdgeInsets.only(bottom: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.4)),
              ),
              alignment: pw.Alignment.bottomCenter,
              child: pw.Text(
                'No.${page.number}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    ),
    pw.SizedBox(height: 10),
    pw.Table(
      columnWidths: _columnWidths,
      border: pw.TableBorder.all(width: 0.4, color: PdfColors.black),
      children: [
        pw.TableRow(
          children: [
            for (final header in _headers)
              _breakdownCell(
                header,
                height: 25,
                alignment: pw.Alignment.bottomCenter,
                fontSize: 10,
              ),
          ],
        ),
        for (final row in page.rows)
          pw.TableRow(
            children: _breakdownRowCells(
              row,
              estimateDecimalPlaces: estimateDecimalPlaces,
            ),
          ),
      ],
    ),
  ],
);

List<pw.Widget> _breakdownRowCells(
  EstimatePdfRow row, {
  required int estimateDecimalPlaces,
}) {
  if (row.type == EstimatePdfRowType.location) {
    return [
      _breakdownCell(row.symbol, bold: true, center: true),
      _breakdownCell(
        row.location,
        bold: true,
        fontSize: _detailFontSize(row.location),
      ),
      ...List.generate(6, (_) => _breakdownCell('')),
    ];
  }
  if (row.type == EstimatePdfRowType.item) {
    final item = row.item!;
    return [
      _breakdownCell(''),
      _breakdownCell(item.name, fontSize: _detailFontSize(item.name)),
      _breakdownCell(
        item.specification,
        fontSize: _detailFontSize(item.specification),
      ),
      _breakdownCell(
        formatEstimatePdfQuantity(item.quantity, estimateDecimalPlaces),
        center: true,
        fontSize: 7.5,
      ),
      _breakdownCell(item.unit, center: true, fontSize: 7.5),
      _breakdownCell(_moneyValue(item.unitPrice), right: true, fontSize: 7.5),
      _breakdownCell(
        _money(estimateLineAmount(item)),
        right: true,
        fontSize: 7.5,
      ),
      _breakdownCell(
        item.description,
        fontSize: _detailFontSize(item.description),
      ),
    ];
  }
  if (row.type == EstimatePdfRowType.blank) {
    return List.generate(8, (_) => _breakdownCell(''));
  }
  return [
    _breakdownCell(''),
    _breakdownCell(row.label, bold: row.type != EstimatePdfRowType.subtotal),
    ...List.generate(4, (_) => _breakdownCell('')),
    _breakdownCell(
      _money(row.amount ?? 0),
      bold: row.type != EstimatePdfRowType.subtotal,
      right: true,
    ),
    _breakdownCell(''),
  ];
}

pw.Widget _breakdownCell(
  String text, {
  double height = 25.5,
  bool bold = false,
  bool center = false,
  bool right = false,
  double fontSize = 8.2,
  pw.Alignment? alignment,
}) => pw.Container(
  height: height,
  padding: const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
  alignment:
      alignment ??
      (right
          ? pw.Alignment.centerRight
          : center
          ? pw.Alignment.center
          : pw.Alignment.centerLeft),
  child: pw.Text(
    text,
    softWrap: true,
    maxLines: 2,
    style: pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  ),
);

pw.Widget _fitText(
  String text, {
  required double fontSize,
  bool bold = false,
  pw.Alignment alignment = pw.Alignment.center,
}) {
  if (text.isEmpty) return pw.SizedBox();
  return pw.Align(
    alignment: alignment,
    child: pw.FittedBox(
      fit: pw.BoxFit.scaleDown,
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    ),
  );
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

@visibleForTesting
List<String> estimatePdfCompanyProfileLines(CompanyProfile profile) {
  final values = <CompanyProfileSection, String>{
    CompanyProfileSection.companyName: profile.companyName.trim(),
    CompanyProfileSection.representativeName: profile.representativeName.trim(),
    CompanyProfileSection.postalCode: profile.postalCode.trim(),
    CompanyProfileSection.addressLine1: profile.addressLine1.trim(),
    CompanyProfileSection.addressLine2: profile.addressLine2.trim(),
    CompanyProfileSection.phoneNumber: profile.phoneNumber.trim(),
  };
  final visible = profile.effectiveExcelVisibleSections.toSet();
  return [
    for (final section in profile.effectiveDisplayOrder)
      if (visible.contains(section) && values[section]!.isNotEmpty)
        values[section]!,
  ].take(5).toList(growable: false);
}

@visibleForTesting
String formatEstimatePdfQuantity(double? value, int decimalPlaces) {
  if (value == null) return '';
  return value.toStringAsFixed(decimalPlaces.clamp(1, 5));
}

double _detailFontSize(String value) {
  final lines = value.split('\n');
  final longest = lines.fold<int>(
    0,
    (length, line) => line.length > length ? line.length : length,
  );
  if (lines.length > 2 || longest > 28) return 6.2;
  if (lines.length > 1 || longest > 20) return 7;
  return 8.2;
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

String _westernDate(DateTime date) => '${date.year}年${date.month}月${date.day}日';
