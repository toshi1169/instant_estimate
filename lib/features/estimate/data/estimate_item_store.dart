import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_workspace.dart';
import '../domain/unit_price_master.dart';

abstract interface class EstimateItemStore {
  Future<EstimateWorkspace> load();
  Future<void> save(EstimateWorkspace workspace);
}

class PlatformEstimateItemStore implements EstimateItemStore {
  static const _channel = MethodChannel('jp.instant_estimate/estimate_items');

  @override
  Future<EstimateWorkspace> load() async {
    final encoded = await _channel.invokeMethod<String>('loadEstimateItems');
    if (encoded == null || encoded.isEmpty) {
      return const EstimateWorkspace(activeEstimateId: '', estimates: []);
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is List<Object?>) {
        final document = EstimateDocument(
          info: EstimateInfo.initial(DateTime.now()),
          items: _decodeItems(decoded),
        );
        return EstimateWorkspace(
          activeEstimateId: document.info.id,
          estimates: [document],
        );
      }
      final map = (decoded as Map<Object?, Object?>).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      if (map['estimates'] case final List<Object?> encodedEstimates) {
        final estimates = encodedEstimates
            .whereType<Map<Object?, Object?>>()
            .map(
              (estimate) => EstimateDocument.fromJson(
                estimate.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList(growable: false);
        if (estimates.isNotEmpty) {
          final requestedId = map['activeEstimateId'] as String?;
          final activeId =
              estimates.any((estimate) => estimate.info.id == requestedId)
              ? requestedId!
              : estimates.first.info.id;
          return EstimateWorkspace(
            activeEstimateId: activeId,
            estimates: estimates,
            unitPriceMasters: _decodeUnitPriceMasters(map['unitPriceMasters']),
          );
        }
        return EstimateWorkspace(
          activeEstimateId: '',
          estimates: const [],
          unitPriceMasters: _decodeUnitPriceMasters(map['unitPriceMasters']),
        );
      }
      final document = EstimateDocument.fromJson(map);
      return EstimateWorkspace(
        activeEstimateId: document.info.id,
        estimates: [document],
      );
    } on FormatException {
      final document = EstimateDocument(
        info: EstimateInfo.initial(DateTime.now()),
        items: const [],
      );
      return EstimateWorkspace(
        activeEstimateId: document.info.id,
        estimates: [document],
      );
    } on TypeError {
      final document = EstimateDocument(
        info: EstimateInfo.initial(DateTime.now()),
        items: const [],
      );
      return EstimateWorkspace(
        activeEstimateId: document.info.id,
        estimates: [document],
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

  List<UnitPriceMaster> _decodeUnitPriceMasters(Object? encoded) {
    if (encoded is! List<Object?>) return const [];
    return encoded
        .whereType<Map<Object?, Object?>>()
        .map(
          (price) => UnitPriceMaster.fromJson(
            price.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(EstimateWorkspace workspace) {
    return _channel.invokeMethod<void>('saveEstimateItems', <String, Object>{
      'items': jsonEncode(workspace.toJson()),
    });
  }
}
