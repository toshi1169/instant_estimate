import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/estimate_item.dart';

abstract interface class EstimateItemStore {
  Future<List<EstimateItem>> load();
  Future<void> save(List<EstimateItem> items);
}

class PlatformEstimateItemStore implements EstimateItemStore {
  static const _channel = MethodChannel('jp.instant_estimate/estimate_items');

  @override
  Future<List<EstimateItem>> load() async {
    final encoded = await _channel.invokeMethod<String>('loadEstimateItems');
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final decoded = jsonDecode(encoded) as List<Object?>;
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) => EstimateItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
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
  Future<void> save(List<EstimateItem> items) {
    return _channel.invokeMethod<void>('saveEstimateItems', <String, Object>{
      'items': jsonEncode(items.map((item) => item.toJson()).toList()),
    });
  }
}
