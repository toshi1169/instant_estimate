import '../../../core/domain/persistent_id.dart';
import 'estimate_totals.dart';

class EstimateInfo {
  const EstimateInfo({
    required this.id,
    required this.estimateName,
    required this.siteName,
    required this.clientName,
    required this.createdDate,
    required this.estimateNumber,
    required this.notes,
    this.proviso = '',
    this.validityPeriod = '',
    this.constructionPeriod = '',
    this.paymentTerms = '',
    this.taxEnabled = true,
    this.taxRateBasisPoints = defaultEstimateTaxRateBasisPoints,
  });

  factory EstimateInfo.initial(
    DateTime now, {
    Iterable<String> excluding = const [],
    bool taxEnabled = true,
    int taxRateBasisPoints = defaultEstimateTaxRateBasisPoints,
  }) {
    validateEstimateTaxRateBasisPoints(taxRateBasisPoints);
    return EstimateInfo(
      id: PersistentId.create(excluding: excluding),
      estimateName: '名称未設定の見積',
      siteName: '',
      clientName: '',
      createdDate: DateTime(now.year, now.month, now.day),
      estimateNumber: '',
      notes: '',
      proviso: '',
      validityPeriod: '',
      constructionPeriod: '',
      paymentTerms: '',
      taxEnabled: taxEnabled,
      taxRateBasisPoints: taxRateBasisPoints,
    );
  }

  factory EstimateInfo.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    return EstimateInfo(
      id: json['id'] as String? ?? PersistentId.create(),
      estimateName: json['estimateName'] as String? ?? '名称未設定の見積',
      siteName: json['siteName'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      createdDate:
          DateTime.tryParse(json['createdDate'] as String? ?? '') ??
          DateTime(now.year, now.month, now.day),
      estimateNumber: json['estimateNumber'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      proviso: json['proviso'] as String? ?? '',
      validityPeriod: json['validityPeriod'] as String? ?? '',
      constructionPeriod: json['constructionPeriod'] as String? ?? '',
      paymentTerms: json['paymentTerms'] as String? ?? '',
      taxEnabled: _optionalBool(json, 'taxEnabled', true),
      taxRateBasisPoints: _optionalTaxRateBasisPoints(json),
    );
  }

  final String id;
  final String estimateName;
  final String siteName;
  final String clientName;
  final DateTime createdDate;
  final String estimateNumber;
  final String notes;
  final String proviso;
  final String validityPeriod;
  final String constructionPeriod;
  final String paymentTerms;
  final bool taxEnabled;
  final int taxRateBasisPoints;

  String get displayName =>
      estimateName.trim().isEmpty ? '名称未設定の見積' : estimateName.trim();

  EstimateInfo copyWith({
    String? estimateName,
    String? siteName,
    String? clientName,
    DateTime? createdDate,
    String? estimateNumber,
    String? notes,
    String? proviso,
    String? validityPeriod,
    String? constructionPeriod,
    String? paymentTerms,
    bool? taxEnabled,
    int? taxRateBasisPoints,
  }) {
    final resolvedTaxRate = taxRateBasisPoints ?? this.taxRateBasisPoints;
    validateEstimateTaxRateBasisPoints(resolvedTaxRate);
    return EstimateInfo(
      id: id,
      estimateName: estimateName ?? this.estimateName,
      siteName: siteName ?? this.siteName,
      clientName: clientName ?? this.clientName,
      createdDate: createdDate ?? this.createdDate,
      estimateNumber: estimateNumber ?? this.estimateNumber,
      notes: notes ?? this.notes,
      proviso: proviso ?? this.proviso,
      validityPeriod: validityPeriod ?? this.validityPeriod,
      constructionPeriod: constructionPeriod ?? this.constructionPeriod,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxRateBasisPoints: resolvedTaxRate,
    );
  }

  Map<String, Object?> toJson() {
    validateEstimateTaxRateBasisPoints(taxRateBasisPoints);
    return {
      'id': id,
      'estimateName': estimateName,
      'siteName': siteName,
      'clientName': clientName,
      'createdDate': createdDate.toIso8601String(),
      'estimateNumber': estimateNumber,
      'notes': notes,
      'proviso': proviso,
      'validityPeriod': validityPeriod,
      'constructionPeriod': constructionPeriod,
      'paymentTerms': paymentTerms,
      'taxEnabled': taxEnabled,
      'taxRateBasisPoints': taxRateBasisPoints,
    };
  }
}

bool _optionalBool(Map<String, Object?> json, String key, bool fallback) {
  if (!json.containsKey(key)) return fallback;
  final value = json[key];
  if (value is! bool) throw FormatException('$key must be a boolean');
  return value;
}

int _optionalTaxRateBasisPoints(Map<String, Object?> json) {
  const key = 'taxRateBasisPoints';
  if (!json.containsKey(key)) return defaultEstimateTaxRateBasisPoints;
  final value = json[key];
  if (value is! int) throw const FormatException('$key must be an integer');
  try {
    validateEstimateTaxRateBasisPoints(value);
  } on RangeError {
    throw const FormatException('$key is out of range');
  }
  return value;
}
