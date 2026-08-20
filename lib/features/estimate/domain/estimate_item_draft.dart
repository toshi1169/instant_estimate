class EstimateItemDraft {
  const EstimateItemDraft({
    this.constructionSymbol = '',
    this.trade = '',
    this.constructionLocation = '',
    this.name = '',
    this.specification = '',
    this.quantity,
    this.unit = '',
    this.unitPrice,
    this.description = '',
    this.calculationBasis = '',
    this.originalQuantity,
  });

  final String constructionSymbol;
  final String trade;
  final String constructionLocation;
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

  EstimateItemDraft copyWith({
    String? constructionSymbol,
    String? trade,
    String? constructionLocation,
    String? name,
    String? specification,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    double? unitPrice,
    bool clearUnitPrice = false,
    String? description,
    String? calculationBasis,
    double? originalQuantity,
    bool clearOriginalQuantity = false,
  }) {
    return EstimateItemDraft(
      constructionSymbol: constructionSymbol ?? this.constructionSymbol,
      trade: trade ?? this.trade,
      constructionLocation: constructionLocation ?? this.constructionLocation,
      name: name ?? this.name,
      specification: specification ?? this.specification,
      quantity: clearQuantity ? null : quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: clearUnitPrice ? null : unitPrice ?? this.unitPrice,
      description: description ?? this.description,
      calculationBasis: calculationBasis ?? this.calculationBasis,
      originalQuantity: clearOriginalQuantity
          ? null
          : originalQuantity ?? this.originalQuantity,
    );
  }
}
