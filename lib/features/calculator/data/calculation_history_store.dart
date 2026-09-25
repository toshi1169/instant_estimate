import 'dart:convert';

import 'package:flutter/services.dart';

class StoredCalculationHistoryEntry {
  const StoredCalculationHistoryEntry({
    required this.expression,
    required this.result,
    required this.decimalResult,
    required this.createdAt,
    this.improperFractionResult,
    this.mixedFractionResult,
    this.remainderResult,
  });

  factory StoredCalculationHistoryEntry.fromJson(Map<String, Object?> json) {
    return StoredCalculationHistoryEntry(
      expression: json['expression'] as String,
      result: json['result'] as String,
      decimalResult: json['decimalResult'] as String,
      improperFractionResult: json['improperFractionResult'] as String?,
      mixedFractionResult: json['mixedFractionResult'] as String?,
      remainderResult: json['remainderResult'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String expression;
  final String result;
  final String decimalResult;
  final String? improperFractionResult;
  final String? mixedFractionResult;
  final String? remainderResult;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'expression': expression,
    'result': result,
    'decimalResult': decimalResult,
    'improperFractionResult': improperFractionResult,
    'mixedFractionResult': mixedFractionResult,
    'remainderResult': remainderResult,
    'createdAt': createdAt.toIso8601String(),
  };
}

abstract interface class CalculationHistoryStore {
  Future<List<StoredCalculationHistoryEntry>> load();
  Future<void> save(List<StoredCalculationHistoryEntry> entries);
}

class PlatformCalculationHistoryStore implements CalculationHistoryStore {
  static const _channel = MethodChannel(
    'jp.instant_estimate/calculator_history',
  );

  @override
  Future<List<StoredCalculationHistoryEntry>> load() async {
    final encoded = await _channel.invokeMethod<String>('loadHistory');
    if (encoded == null || encoded.isEmpty) return const [];

    try {
      final decoded = jsonDecode(encoded) as List<Object?>;
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (entry) => StoredCalculationHistoryEntry.fromJson(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  @override
  Future<void> save(List<StoredCalculationHistoryEntry> entries) {
    return _channel.invokeMethod<void>('saveHistory', <String, Object>{
      'history': jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    });
  }
}
