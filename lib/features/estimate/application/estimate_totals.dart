import '../domain/estimate_item.dart';

const estimateTaxRate = 0.10;

int estimateLineAmount(EstimateItem item) => (item.amount ?? 0).round();

int estimateSubtotal(Iterable<EstimateItem> items) =>
    items.fold(0, (total, item) => total + estimateLineAmount(item));

int estimateTax(int subtotal) => (subtotal * estimateTaxRate).floor();

int estimateGrandTotal(Iterable<EstimateItem> items) {
  final subtotal = estimateSubtotal(items);
  return subtotal + estimateTax(subtotal);
}
