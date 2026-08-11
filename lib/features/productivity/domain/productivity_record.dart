class ProductivityRecord {
  const ProductivityRecord({
    required this.id,
    required this.createdAt,
    required this.trade,
    required this.taskName,
    required this.siteName,
    required this.workDate,
    required this.quantity,
    required this.unit,
    required this.workers,
    required this.workDays,
    required this.actualLabor,
    required this.actualLaborRate,
    required this.productivityPerLabor,
    this.actualWorkHours,
    this.standardLaborRate,
    this.standardProductivity,
    this.totalPersonHours,
    this.hourlyProductivity,
    this.productivityDifferencePercent,
    this.conditions = '',
  });
  final String id;
  final DateTime createdAt;
  final String trade;
  final String taskName;
  final String siteName;
  final DateTime workDate;
  final double quantity;
  final String unit;
  final double workers;
  final double workDays;
  final double? actualWorkHours;
  final double actualLabor;
  final double? standardLaborRate;
  final double? standardProductivity;
  final double actualLaborRate;
  final double productivityPerLabor;
  final double? totalPersonHours;
  final double? hourlyProductivity;
  final double? productivityDifferencePercent;
  final String conditions;
  String get groupKey =>
      '${trade.trim()}\u0000${taskName.trim()}\u0000${unit.trim()}';

  factory ProductivityRecord.fromJson(Map<String, Object?> json) {
    final quantity = (json['quantity'] as num).toDouble();
    final actualLabor = (json['actualLabor'] as num).toDouble();
    final actualLaborRate = (json['actualLaborRate'] as num).toDouble();
    final productivity =
        (json['productivityPerLabor'] as num?)?.toDouble() ??
        quantity / actualLabor;
    final hoursPerDay = (json['actualWorkHours'] as num?)?.toDouble();
    final storedStandardRate = (json['standardLaborRate'] as num?)?.toDouble();
    final standardProductivity =
        (json['standardProductivity'] as num?)?.toDouble() ??
        (storedStandardRate != null && storedStandardRate > 0
            ? 1 / storedStandardRate
            : null);
    final totalPersonHours =
        (json['totalPersonHours'] as num?)?.toDouble() ??
        (hoursPerDay != null && hoursPerDay > 0
            ? actualLabor * hoursPerDay
            : null);
    return ProductivityRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      trade: json['trade'] as String? ?? '',
      taskName: json['taskName'] as String? ?? '',
      siteName: json['siteName'] as String? ?? '',
      workDate: DateTime.parse(json['workDate'] as String),
      quantity: quantity,
      unit: json['unit'] as String? ?? '',
      workers: (json['workers'] as num).toDouble(),
      workDays: (json['workDays'] as num).toDouble(),
      actualWorkHours: (json['actualWorkHours'] as num?)?.toDouble(),
      actualLabor: actualLabor,
      standardLaborRate: storedStandardRate,
      standardProductivity: standardProductivity,
      actualLaborRate: actualLaborRate,
      productivityPerLabor: productivity,
      totalPersonHours: totalPersonHours,
      hourlyProductivity:
          (json['hourlyProductivity'] as num?)?.toDouble() ??
          (totalPersonHours != null && totalPersonHours > 0
              ? quantity / totalPersonHours
              : null),
      productivityDifferencePercent:
          (json['productivityDifferencePercent'] as num?)?.toDouble() ??
          (standardProductivity != null && standardProductivity > 0
              ? (productivity / standardProductivity - 1) * 100
              : null),
      conditions: json['conditions'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'trade': trade,
    'taskName': taskName,
    'siteName': siteName,
    'workDate': workDate.toIso8601String(),
    'quantity': quantity,
    'unit': unit,
    'workers': workers,
    'workDays': workDays,
    'actualWorkHours': actualWorkHours,
    'actualLabor': actualLabor,
    'standardLaborRate': standardLaborRate,
    'standardProductivity': standardProductivity,
    'actualLaborRate': actualLaborRate,
    'productivityPerLabor': productivityPerLabor,
    'totalPersonHours': totalPersonHours,
    'hourlyProductivity': hourlyProductivity,
    'productivityDifferencePercent': productivityDifferencePercent,
    'conditions': conditions,
  };
}

class ProductivitySummary {
  const ProductivitySummary({
    required this.trade,
    required this.taskName,
    required this.unit,
    required this.records,
    required this.standardLaborRate,
    required this.standardProductivity,
    required this.averageActualLaborRate,
    required this.averageProductivity,
    required this.minimumLaborRate,
    required this.maximumLaborRate,
    required this.averageHourlyProductivity,
  });
  final String trade;
  final String taskName;
  final String unit;
  final List<ProductivityRecord> records;
  final double? standardLaborRate;
  final double? standardProductivity;
  final double averageActualLaborRate;
  final double averageProductivity;
  final double minimumLaborRate;
  final double maximumLaborRate;
  final double? averageHourlyProductivity;
  int get recordCount => records.length;

  factory ProductivitySummary.fromRecords(List<ProductivityRecord> records) {
    if (records.isEmpty) throw ArgumentError('Records are required.');
    final newest = [...records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    double? standard;
    double? standardProductivity;
    for (final record in newest) {
      if (record.standardLaborRate != null) {
        standard = record.standardLaborRate;
      }
      if (record.standardProductivity != null) {
        standardProductivity = record.standardProductivity;
      }
      if (standard != null && standardProductivity != null) break;
    }
    standardProductivity ??= standard != null && standard > 0
        ? 1 / standard
        : null;
    standard ??= standardProductivity != null && standardProductivity > 0
        ? 1 / standardProductivity
        : null;
    final rates = records.map((record) => record.actualLaborRate).toList();
    final products = records
        .map((record) => record.productivityPerLabor)
        .toList();
    final hourlyProducts = records
        .map((record) => record.hourlyProductivity)
        .whereType<double>()
        .toList();
    return ProductivitySummary(
      trade: records.first.trade,
      taskName: records.first.taskName,
      unit: records.first.unit,
      records: List.unmodifiable(newest),
      standardLaborRate: standard,
      standardProductivity: standardProductivity,
      averageActualLaborRate: rates.reduce((a, b) => a + b) / rates.length,
      averageProductivity: products.reduce((a, b) => a + b) / products.length,
      minimumLaborRate: rates.reduce((a, b) => a < b ? a : b),
      maximumLaborRate: rates.reduce((a, b) => a > b ? a : b),
      averageHourlyProductivity: hourlyProducts.isEmpty
          ? null
          : hourlyProducts.reduce((a, b) => a + b) / hourlyProducts.length,
    );
  }
}
