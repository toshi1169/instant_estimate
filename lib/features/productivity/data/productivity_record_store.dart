import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/domain/persistent_id_repair.dart';
import '../domain/productivity_record.dart';

abstract interface class ProductivityRecordStore {
  Future<List<ProductivityRecord>> load();
  Future<void> save(List<ProductivityRecord> records);
}

class MemoryProductivityRecordStore implements ProductivityRecordStore {
  MemoryProductivityRecordStore([List<ProductivityRecord> records = const []])
    : _records = List.of(records);
  List<ProductivityRecord> _records;
  @override
  Future<List<ProductivityRecord>> load() async => List.of(_records);
  @override
  Future<void> save(List<ProductivityRecord> records) async {
    _records = List.of(records);
  }
}

class PlatformProductivityRecordStore implements ProductivityRecordStore {
  static const _channel = MethodChannel(
    'jp.instant_estimate/productivity_records',
  );
  @override
  Future<List<ProductivityRecord>> load() async {
    final encoded = await _channel.invokeMethod<String>(
      'loadProductivityRecords',
    );
    if (encoded == null || encoded.isEmpty) return const [];
    late List<ProductivityRecord> records;
    var repaired = false;
    try {
      final decoded = jsonDecode(encoded) as List<Object?>;
      repaired = PersistentIdRepair.productivity(decoded);
      records = decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (record) => ProductivityRecord.fromJson(
              record.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
    if (repaired) await save(records);
    return records;
  }

  @override
  Future<void> save(List<ProductivityRecord> records) =>
      _channel.invokeMethod<void>('saveProductivityRecords', <String, Object>{
        'records': jsonEncode(
          records.map((record) => record.toJson()).toList(),
        ),
      });
}
