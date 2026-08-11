class LaborPlanResult {
  const LaborPlanResult({
    required this.requiredLabor,
    this.requiredDays,
    this.teamDailyProductivity,
    this.totalPersonHours,
  });
  final double requiredLabor;
  final double? requiredDays;
  final double? teamDailyProductivity;
  final double? totalPersonHours;

  /// Kept for compatibility with older callers.
  double? get totalWorkHours => totalPersonHours;
}

class ProductivityResult {
  const ProductivityResult({
    required this.actualLabor,
    required this.actualLaborRate,
    required this.actualProductivity,
    this.totalPersonHours,
    this.hourlyProductivity,
    this.baselineProductivity,
    this.productivityDifferencePercent,
  });
  final double actualLabor;
  final double actualLaborRate;
  final double actualProductivity;
  final double? totalPersonHours;
  final double? hourlyProductivity;
  final double? baselineProductivity;
  final double? productivityDifferencePercent;

  double get productivityPerLabor => actualProductivity;
}

abstract final class ProductivityCalculator {
  static LaborPlanResult plan({
    required double quantity,
    required double dailyProductivity,
    double? workers,
    double? hoursPerDay,
  }) {
    if (quantity <= 0 || dailyProductivity <= 0) {
      throw ArgumentError('Invalid plan values.');
    }
    if (workers != null && workers <= 0) {
      throw ArgumentError('Workers must be greater than zero.');
    }
    if (hoursPerDay != null && hoursPerDay < 0) {
      throw ArgumentError('Hours must not be negative.');
    }
    final labor = quantity / dailyProductivity;
    final days = workers != null && workers > 0 ? labor / workers : null;
    return LaborPlanResult(
      requiredLabor: labor,
      requiredDays: days,
      teamDailyProductivity: workers == null
          ? null
          : dailyProductivity * workers,
      totalPersonHours: hoursPerDay != null && hoursPerDay > 0
          ? labor * hoursPerDay
          : null,
    );
  }

  static ProductivityResult actual({
    required double quantity,
    required double workers,
    required double workDays,
    double? hoursPerDay,
    double? baselineProductivity,
  }) {
    if (quantity <= 0 || workers <= 0 || workDays <= 0) {
      throw ArgumentError('Invalid actual values.');
    }
    if (hoursPerDay != null && hoursPerDay < 0) {
      throw ArgumentError('Hours must not be negative.');
    }
    if (baselineProductivity != null && baselineProductivity <= 0) {
      throw ArgumentError('Baseline productivity must be greater than zero.');
    }
    final labor = workers * workDays;
    final rate = labor / quantity;
    final productivity = quantity / labor;
    final totalPersonHours = hoursPerDay != null && hoursPerDay > 0
        ? labor * hoursPerDay
        : null;
    return ProductivityResult(
      actualLabor: labor,
      actualLaborRate: rate,
      actualProductivity: productivity,
      totalPersonHours: totalPersonHours,
      hourlyProductivity: totalPersonHours == null
          ? null
          : quantity / totalPersonHours,
      baselineProductivity: baselineProductivity,
      productivityDifferencePercent: baselineProductivity == null
          ? null
          : (productivity / baselineProductivity - 1) * 100,
    );
  }
}
