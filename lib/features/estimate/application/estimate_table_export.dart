import '../domain/estimate_item.dart';

const _headers = ['工種', '名称', '仕様', '数量', '単位', '単価', '金額', '摘要'];

String buildEstimateTableText(Iterable<EstimateItem> items) {
  final itemList = items.toList(growable: false);
  final rows = <List<String>>[
    _headers,
    for (var index = 0; index < itemList.length; index++)
      _itemCells(itemList[index], excelRow: index + 2),
  ];
  return rows.map((row) => row.join('\t')).join('\n');
}

List<String> _itemCells(EstimateItem item, {required int excelRow}) {
  return [
    _textCell(item.trade),
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
