import 'estimate_item.dart';
import 'estimate_totals.dart';

class EstimateItemGroup {
  const EstimateItemGroup({
    required this.constructionSymbol,
    required this.constructionLocation,
    required this.items,
  });

  final String constructionSymbol;
  final String constructionLocation;
  final List<EstimateItem> items;

  String get displayName => [
    constructionSymbol.trim(),
    constructionLocation.trim(),
  ].where((value) => value.isNotEmpty).join(' ');

  int get subtotal => estimateSubtotal(items);
}
