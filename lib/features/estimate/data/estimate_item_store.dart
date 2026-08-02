import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';

abstract interface class EstimateItemStore {
  Future<EstimateDocument> load();
  Future<void> save(EstimateDocument document);
}

class PlatformEstimateItemStore implements EstimateItemStore {
  static const _channel = MethodChannel('jp.instant_estimate/estimate_items');

  @override
  Future<EstimateDocument> load() async {
    final encoded = await _channel.invokeMethod<String>('loadEstimateItems');
    if (encoded == null || encoded.isEmpty) {
      return EstimateDocument(
        info: EstimateInfo.initial(DateTime.now()),
        items: const [],
      );
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is List<Object?>) {
        return EstimateDocument(
          info: EstimateInfo.initial(DateTime.now()),
          items: _decodeItems(decoded),
        );
      }
      final map = (decoded as Map<Object?, Object?>).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final infoMap = (map['info'] as Map<Object?, Object?>).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return EstimateDocument(
        info: EstimateInfo.fromJson(infoMap),
        items: _decodeItems(map['items'] as List<Object?>? ?? const []),
      );
    } on FormatException {
      return EstimateDocument(
        info: EstimateInfo.initial(DateTime.now()),
        items: const [],
      );
    } on TypeError {
      return EstimateDocument(
        info: EstimateInfo.initial(DateTime.now()),
        items: const [],
      );
    }
  }

  List<EstimateItem> _decodeItems(List<Object?> decoded) {
    return decoded
        .whereType<Map<Object?, Object?>>()
        .map(
          (item) => EstimateItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(EstimateDocument document) {
    return _channel.invokeMethod<void>('saveEstimateItems', <String, Object>{
      'items': jsonEncode(document.toJson()),
    });
  }
}
