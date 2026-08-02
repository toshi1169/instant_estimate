class EstimateInfo {
  const EstimateInfo({
    required this.id,
    required this.estimateName,
    required this.siteName,
    required this.clientName,
    required this.createdDate,
    required this.estimateNumber,
    required this.notes,
  });

  factory EstimateInfo.initial(DateTime now) => EstimateInfo(
    id: now.microsecondsSinceEpoch.toString(),
    estimateName: '名称未設定の見積',
    siteName: '',
    clientName: '',
    createdDate: DateTime(now.year, now.month, now.day),
    estimateNumber: '',
    notes: '',
  );

  factory EstimateInfo.fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    return EstimateInfo(
      id: json['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      estimateName: json['estimateName'] as String? ?? '名称未設定の見積',
      siteName: json['siteName'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      createdDate:
          DateTime.tryParse(json['createdDate'] as String? ?? '') ??
          DateTime(now.year, now.month, now.day),
      estimateNumber: json['estimateNumber'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  final String id;
  final String estimateName;
  final String siteName;
  final String clientName;
  final DateTime createdDate;
  final String estimateNumber;
  final String notes;

  String get displayName =>
      estimateName.trim().isEmpty ? '名称未設定の見積' : estimateName.trim();

  EstimateInfo copyWith({
    String? estimateName,
    String? siteName,
    String? clientName,
    DateTime? createdDate,
    String? estimateNumber,
    String? notes,
  }) => EstimateInfo(
    id: id,
    estimateName: estimateName ?? this.estimateName,
    siteName: siteName ?? this.siteName,
    clientName: clientName ?? this.clientName,
    createdDate: createdDate ?? this.createdDate,
    estimateNumber: estimateNumber ?? this.estimateNumber,
    notes: notes ?? this.notes,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'estimateName': estimateName,
    'siteName': siteName,
    'clientName': clientName,
    'createdDate': createdDate.toIso8601String(),
    'estimateNumber': estimateNumber,
    'notes': notes,
  };
}
