import 'estimate_item.dart';
import 'estimate_totals.dart';

class EstimateItemGroup {
  const EstimateItemGroup({required this.trade, required this.items});

  final String trade;
  final List<EstimateItem> items;

  String get displayName => trade.trim().isEmpty ? '工種未設定' : trade.trim();

  int get subtotal => estimateSubtotal(items);
}
