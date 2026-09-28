import 'estimate_item.dart';

const defaultEstimateTaxRateBasisPoints = 1000;
const minEstimateTaxRateBasisPoints = 0;
const maxEstimateTaxRateBasisPoints = 10000;

int estimateLineAmount(EstimateItem item) => (item.amount ?? 0).round();

int estimateSubtotal(Iterable<EstimateItem> items) =>
    items.fold(0, (total, item) => total + estimateLineAmount(item));

int estimateTax(
  int subtotal, {
  bool taxEnabled = true,
  int taxRateBasisPoints = defaultEstimateTaxRateBasisPoints,
}) {
  validateEstimateTaxRateBasisPoints(taxRateBasisPoints);
  if (!taxEnabled) return 0;
  final scaled = subtotal * taxRateBasisPoints;
  if (scaled >= 0) return scaled ~/ 10000;
  return -((-scaled + 9999) ~/ 10000);
}

void validateEstimateTaxRateBasisPoints(int value) {
  if (value < minEstimateTaxRateBasisPoints ||
      value > maxEstimateTaxRateBasisPoints) {
    throw RangeError.range(
      value,
      minEstimateTaxRateBasisPoints,
      maxEstimateTaxRateBasisPoints,
      'taxRateBasisPoints',
    );
  }
}

String estimateLineAmountSpreadsheetFormula(
  String quantityCell,
  String unitPriceCell,
) => 'ROUND($quantityCell*$unitPriceCell,0)';

String formatEstimateTaxRate(int taxRateBasisPoints) {
  validateEstimateTaxRateBasisPoints(taxRateBasisPoints);
  final whole = taxRateBasisPoints ~/ 100;
  final fraction = taxRateBasisPoints % 100;
  if (fraction == 0) return '$whole%';
  if (fraction % 10 == 0) return '$whole.${fraction ~/ 10}%';
  return '$whole.${fraction.toString().padLeft(2, '0')}%';
}

String estimateTaxSpreadsheetFormula(
  String subtotalCell, {
  int taxRateBasisPoints = defaultEstimateTaxRateBasisPoints,
}) {
  validateEstimateTaxRateBasisPoints(taxRateBasisPoints);
  return 'INT($subtotalCell*$taxRateBasisPoints/10000)';
}

int estimateGrandTotal(
  Iterable<EstimateItem> items, {
  bool taxEnabled = true,
  int taxRateBasisPoints = defaultEstimateTaxRateBasisPoints,
}) {
  final subtotal = estimateSubtotal(items);
  return subtotal +
      estimateTax(
        subtotal,
        taxEnabled: taxEnabled,
        taxRateBasisPoints: taxRateBasisPoints,
      );
}
