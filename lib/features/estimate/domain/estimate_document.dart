import 'estimate_info.dart';
import 'estimate_item.dart';

class EstimateDocument {
  const EstimateDocument({required this.info, required this.items});

  final EstimateInfo info;
  final List<EstimateItem> items;

  Map<String, Object?> toJson() => {
    'version': 2,
    'info': info.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}
