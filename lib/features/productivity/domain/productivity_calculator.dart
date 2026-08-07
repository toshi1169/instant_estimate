class LaborPlanResult {
  const LaborPlanResult({
    required this.requiredLabor,
    this.requiredDays,
    this.totalWorkHours,
  });
  final double requiredLabor;
  final double? requiredDays;
  final double? totalWorkHours;
}

class ProductivityResult {
  const ProductivityResult({
    required this.actualLabor,
    required this.actualLaborRate,
    required this.productivityPerLabor,
    this.laborRateDifference,
    this.efficiencyDifferencePercent,
  });
  final double actualLabor;
  final double actualLaborRate;
  final double productivityPerLabor;
  final double? laborRateDifference;
  final double? efficiencyDifferencePercent;
}

abstract final class ProductivityCalculator {
  static LaborPlanResult plan({
    required double quantity,
    required double standardLaborRate,
    double? workers,
    double? hoursPerDay,
  }) {
    if (quantity <= 0 || standardLaborRate < 0) {
      throw ArgumentError('Invalid plan values.');
    }
    final labor = quantity * standardLaborRate;
    final days = workers != null && workers > 0 ? labor / workers : null;
    return LaborPlanResult(
      requiredLabor: labor,
      requiredDays: days,
      totalWorkHours: days != null && hoursPerDay != null && hoursPerDay > 0
          ? days * hoursPerDay
          : null,
    );
  }

  static ProductivityResult actual({
    required double quantity,
    required double workers,
    required double workDays,
    double? standardLaborRate,
  }) {
    if (quantity <= 0 || workers <= 0 || workDays <= 0) {
      throw ArgumentError('Invalid actual values.');
    }
    final labor = workers * workDays;
    final rate = labor / quantity;
    return ProductivityResult(
      actualLabor: labor,
      actualLaborRate: rate,
      productivityPerLabor: quantity / labor,
      laborRateDifference: standardLaborRate == null
          ? null
          : rate - standardLaborRate,
      efficiencyDifferencePercent: standardLaborRate == null || rate == 0
          ? null
          : (standardLaborRate / rate - 1) * 100,
    );
  }
}
