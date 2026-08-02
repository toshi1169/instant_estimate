import 'estimate_item_draft.dart';

class EstimateItem {
  const EstimateItem({
    required this.id,
    required this.createdAt,
    required this.trade,
    required this.name,
    required this.specification,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.description,
    required this.calculationBasis,
    required this.originalQuantity,
  });

  factory EstimateItem.fromDraft(
    EstimateItemDraft draft, {
    required String id,
    required DateTime createdAt,
  }) {
    return EstimateItem(
      id: id,
      createdAt: createdAt,
      trade: draft.trade,
      name: draft.name,
      specification: draft.specification,
      quantity: draft.quantity,
      unit: draft.unit,
      unitPrice: draft.unitPrice,
      description: draft.description,
      calculationBasis: draft.calculationBasis,
      originalQuantity: draft.originalQuantity,
    );
  }

  factory EstimateItem.fromJson(Map<String, Object?> json) {
    return EstimateItem(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      trade: json['trade'] as String? ?? '',
      name: json['name'] as String? ?? '',
      specification: json['specification'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      calculationBasis: json['calculationBasis'] as String? ?? '',
      originalQuantity: (json['originalQuantity'] as num?)?.toDouble(),
    );
  }

  final String id;
  final DateTime createdAt;
  final String trade;
  final String name;
  final String specification;
  final double? quantity;
  final String unit;
  final double? unitPrice;
  final String description;
  final String calculationBasis;
  final double? originalQuantity;

  double? get amount {
    final quantity = this.quantity;
    final unitPrice = this.unitPrice;
    if (quantity == null || unitPrice == null) return null;
    return quantity * unitPrice;
  }

  EstimateItemDraft toDraft() => EstimateItemDraft(
    trade: trade,
    name: name,
    specification: specification,
    quantity: quantity,
    unit: unit,
    unitPrice: unitPrice,
    description: description,
    calculationBasis: calculationBasis,
    originalQuantity: originalQuantity,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'trade': trade,
    'name': name,
    'specification': specification,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
    'description': description,
    'calculationBasis': calculationBasis,
    'originalQuantity': originalQuantity,
  };
}
