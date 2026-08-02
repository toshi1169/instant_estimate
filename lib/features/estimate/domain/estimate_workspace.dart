import 'estimate_document.dart';

class EstimateWorkspace {
  const EstimateWorkspace({
    required this.activeEstimateId,
    required this.estimates,
  });

  final String activeEstimateId;
  final List<EstimateDocument> estimates;

  Map<String, Object?> toJson() => {
    'version': 3,
    'activeEstimateId': activeEstimateId,
    'estimates': estimates.map((estimate) => estimate.toJson()).toList(),
  };
}
