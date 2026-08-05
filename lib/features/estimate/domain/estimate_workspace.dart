import 'estimate_document.dart';
import 'unit_price_master.dart';

class EstimateWorkspace {
  const EstimateWorkspace({
    required this.activeEstimateId,
    required this.estimates,
    this.unitPriceMasters = const [],
  });

  final String activeEstimateId;
  final List<EstimateDocument> estimates;
  final List<UnitPriceMaster> unitPriceMasters;

  Map<String, Object?> toJson() => {
    'version': 4,
    'activeEstimateId': activeEstimateId,
    'estimates': estimates.map((estimate) => estimate.toJson()).toList(),
    'unitPriceMasters': unitPriceMasters
        .map((price) => price.toJson())
        .toList(),
  };
}
