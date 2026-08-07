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
  final double actualLaborRate;
  final double productivityPerLabor;
  final String conditions;
  String get groupKey =>
      '${trade.trim()}\u0000${taskName.trim()}\u0000${unit.trim()}';

  factory ProductivityRecord.fromJson(Map<String, Object?> json) =>
      ProductivityRecord(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        trade: json['trade'] as String? ?? '',
        taskName: json['taskName'] as String? ?? '',
        siteName: json['siteName'] as String? ?? '',
        workDate: DateTime.parse(json['workDate'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String? ?? '',
        workers: (json['workers'] as num).toDouble(),
        workDays: (json['workDays'] as num).toDouble(),
        actualWorkHours: (json['actualWorkHours'] as num?)?.toDouble(),
        actualLabor: (json['actualLabor'] as num).toDouble(),
        standardLaborRate: (json['standardLaborRate'] as num?)?.toDouble(),
        actualLaborRate: (json['actualLaborRate'] as num).toDouble(),
        productivityPerLabor: (json['productivityPerLabor'] as num).toDouble(),
        conditions: json['conditions'] as String? ?? '',
      );

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
    'actualLaborRate': actualLaborRate,
    'productivityPerLabor': productivityPerLabor,
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
    required this.averageActualLaborRate,
    required this.averageProductivity,
    required this.minimumLaborRate,
    required this.maximumLaborRate,
  });
  final String trade;
  final String taskName;
  final String unit;
  final List<ProductivityRecord> records;
  final double? standardLaborRate;
  final double averageActualLaborRate;
  final double averageProductivity;
  final double minimumLaborRate;
  final double maximumLaborRate;
  int get recordCount => records.length;

  factory ProductivitySummary.fromRecords(List<ProductivityRecord> records) {
    if (records.isEmpty) throw ArgumentError('Records are required.');
    final newest = [...records]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    double? standard;
    for (final record in newest) {
      if (record.standardLaborRate != null) {
        standard = record.standardLaborRate;
        break;
      }
    }
    final rates = records.map((record) => record.actualLaborRate).toList();
    final products = records
        .map((record) => record.productivityPerLabor)
        .toList();
    return ProductivitySummary(
      trade: records.first.trade,
      taskName: records.first.taskName,
      unit: records.first.unit,
      records: List.unmodifiable(newest),
      standardLaborRate: standard,
      averageActualLaborRate: rates.reduce((a, b) => a + b) / rates.length,
      averageProductivity: products.reduce((a, b) => a + b) / products.length,
      minimumLaborRate: rates.reduce((a, b) => a < b ? a : b),
      maximumLaborRate: rates.reduce((a, b) => a > b ? a : b),
    );
  }
}
