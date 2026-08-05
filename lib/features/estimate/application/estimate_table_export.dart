import '../domain/estimate_item.dart';

const _headers = ['記号', '名称', '仕様', '数量', '単位', '単価', '金額', '摘要'];

String buildEstimateTableText(Iterable<EstimateItem> items) {
  final groupedItems = _groupItems(items);
  final rows = <List<String>>[_headers];
  final subtotalRows = <int>[];
  var groupNumber = 1;

  for (final groupItems in groupedItems.values) {
    final firstItemRow = rows.length + 1;
    for (var index = 0; index < groupItems.length; index++) {
      final excelRow = rows.length + 1;
      rows.add(
        _itemCells(
          groupItems[index],
          excelRow: excelRow,
          marker: index == 0 ? _groupMarker(groupNumber) : '',
        ),
      );
    }
    final lastItemRow = rows.length;

    rows.add([
      '',
      '',
      '',
      '',
      '',
      '小計',
      '=SUM(G$firstItemRow:G$lastItemRow)',
      '',
    ]);
    subtotalRows.add(rows.length);
    rows.add(List.filled(_headers.length, ''));
    groupNumber++;
  }

  final subtotalRow = rows.length + 1;
  rows.add([
    '',
    '',
    '',
    '',
    '',
    '税抜合計',
    subtotalRows.isEmpty
        ? '0'
        : '=SUM(${subtotalRows.map((row) => 'G$row').join(',')})',
    '',
  ]);
  final taxRow = rows.length + 1;
  rows.add([
    '',
    '',
    '',
    '',
    '',
    '消費税（10%）',
    '=ROUNDDOWN(G$subtotalRow*10%,0)',
    '',
  ]);
  rows.add(['', '', '', '', '', '税込総額', '=G$subtotalRow+G$taxRow', '']);

  return rows.map((row) => row.join('\t')).join('\n');
}

Map<String, List<EstimateItem>> _groupItems(Iterable<EstimateItem> items) {
  final grouped = <String, List<EstimateItem>>{};
  for (final item in items) {
    final trade = item.trade.trim();
    grouped.putIfAbsent(trade, () => []).add(item);
  }
  return grouped;
}

List<String> _itemCells(
  EstimateItem item, {
  required int excelRow,
  required String marker,
}) {
  return [
    marker,
    _textCell(item.name),
    _textCell(item.specification),
    _numberCell(item.quantity),
    _textCell(item.unit),
    _numberCell(item.unitPrice),
    '=D$excelRow*F$excelRow',
    _textCell(item.description),
  ];
}

String _textCell(String value) {
  final sanitized = value.replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();
  if (sanitized.isEmpty) return '';
  if (RegExp(r'^[=+\-@]').hasMatch(sanitized)) return "'$sanitized";
  return sanitized;
}

String _numberCell(double? value) {
  if (value == null) return '';
  if (value.isFinite && value == value.truncateToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
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
