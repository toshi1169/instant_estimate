import 'estimate_item.dart';

const estimateTaxPercentage = 10;
const estimateTaxRate = estimateTaxPercentage / 100;

int estimateLineAmount(EstimateItem item) => (item.amount ?? 0).round();

int estimateSubtotal(Iterable<EstimateItem> items) =>
    items.fold(0, (total, item) => total + estimateLineAmount(item));

int estimateTax(int subtotal) => (subtotal * estimateTaxRate).floor();

String estimateLineAmountSpreadsheetFormula(
  String quantityCell,
  String unitPriceCell,
) => 'ROUND($quantityCell*$unitPriceCell,0)';

String estimateTaxSpreadsheetFormula(String subtotalCell) =>
    'INT($subtotalCell*$estimateTaxPercentage%)';

int estimateGrandTotal(Iterable<EstimateItem> items) {
  final subtotal = estimateSubtotal(items);
  return subtotal + estimateTax(subtotal);
}
