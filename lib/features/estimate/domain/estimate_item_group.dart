import 'estimate_item.dart';

class EstimateItemGroup {
  const EstimateItemGroup({required this.trade, required this.items});

  final String trade;
  final List<EstimateItem> items;

  String get displayName => trade.trim().isEmpty ? '工種未設定' : trade.trim();

  double get subtotal =>
      items.fold(0, (total, item) => total + (item.amount ?? 0));
}
