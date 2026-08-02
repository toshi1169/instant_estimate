import 'estimate_info.dart';
import 'estimate_item.dart';

class EstimateDocument {
  const EstimateDocument({required this.info, required this.items});

  final EstimateInfo info;
  final List<EstimateItem> items;

  double get totalAmount =>
      items.fold(0, (total, item) => total + (item.amount ?? 0));

  factory EstimateDocument.fromJson(Map<String, Object?> json) {
    final infoMap = (json['info'] as Map<Object?, Object?>).map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final items = (json['items'] as List<Object?>? ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(
          (item) => EstimateItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
    return EstimateDocument(info: EstimateInfo.fromJson(infoMap), items: items);
  }

  Map<String, Object?> toJson() => {
    'version': 2,
    'info': info.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}
