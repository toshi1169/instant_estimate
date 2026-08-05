class UnitPriceMasterDraft {
  const UnitPriceMasterDraft({
    this.trade = '',
    this.name = '',
    this.specification = '',
    this.unit = '',
    this.unitPrice,
    this.description = '',
  });

  final String trade;
  final String name;
  final String specification;
  final String unit;
  final double? unitPrice;
  final String description;
}

class UnitPriceMaster {
  const UnitPriceMaster({
    required this.id,
    required this.createdAt,
    required this.trade,
    required this.name,
    required this.specification,
    required this.unit,
    required this.unitPrice,
    required this.description,
  });

  final String id;
  final DateTime createdAt;
  final String trade;
  final String name;
  final String specification;
  final String unit;
  final double? unitPrice;
  final String description;

  factory UnitPriceMaster.fromDraft(
    UnitPriceMasterDraft draft, {
    required String id,
    required DateTime createdAt,
  }) => UnitPriceMaster(
    id: id,
    createdAt: createdAt,
    trade: draft.trade,
    name: draft.name,
    specification: draft.specification,
    unit: draft.unit,
    unitPrice: draft.unitPrice,
    description: draft.description,
  );

  factory UnitPriceMaster.fromJson(Map<String, Object?> json) =>
      UnitPriceMaster(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        trade: json['trade'] as String? ?? '',
        name: json['name'] as String? ?? '',
        specification: json['specification'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        unitPrice: (json['unitPrice'] as num?)?.toDouble(),
        description: json['description'] as String? ?? '',
      );

  UnitPriceMasterDraft toDraft() => UnitPriceMasterDraft(
    trade: trade,
    name: name,
    specification: specification,
    unit: unit,
    unitPrice: unitPrice,
    description: description,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'trade': trade,
    'name': name,
    'specification': specification,
    'unit': unit,
    'unitPrice': unitPrice,
    'description': description,
  };
}

bool matchesUnitPriceMasterQuery(UnitPriceMaster price, String query) {
  final terms = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty);
  if (terms.isEmpty) return true;
  final searchable = [
    price.trade,
    price.name,
    price.specification,
    price.unit,
    price.description,
    if (price.unitPrice != null) price.unitPrice.toString(),
  ].join(' ').toLowerCase();
  return terms.every(searchable.contains);
}
