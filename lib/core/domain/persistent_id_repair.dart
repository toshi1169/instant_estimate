import 'persistent_id.dart';
import 'transport_vehicle.dart';

/// Repairs only ID fields in decoded, mutable JSON. Other fields are left for
/// their existing parsers and validators to check.
abstract final class PersistentIdRepair {
  static bool workspace(Map<String, dynamic> json) {
    final estimates = _maps(json['estimates']);
    final infos = <Map<String, dynamic>>[];
    final items = <Map<String, dynamic>>[];
    for (final estimate in estimates) {
      if (estimate['info'] case final Map<String, dynamic> info) {
        infos.add(info);
      }
      items.addAll(_maps(estimate['items']));
    }
    final firstOriginalId = infos.isEmpty ? null : infos.first['id'];
    var changed = _ids(infos);
    changed = _ids(items) || changed;
    changed = _ids(_maps(json['unitPriceMasters'])) || changed;
    if (infos.isNotEmpty &&
        json['activeEstimateId'] == '' &&
        (firstOriginalId == null || firstOriginalId == '')) {
      json['activeEstimateId'] = infos.first['id'];
      changed = true;
    }
    return changed;
  }

  static bool document(Map<String, dynamic> json) {
    var changed = false;
    if (json['info'] case final Map<String, dynamic> info) {
      changed = _ids([info]);
    }
    changed = _ids(_maps(json['items'])) || changed;
    return changed;
  }

  static bool productivity(List<dynamic> json) => _ids(_maps(json));

  static bool items(List<dynamic> json) => _ids(_maps(json));

  static bool settings(Map<String, dynamic> json) => _ids(
    _maps(json['customTransportVehicles']),
    forbidden: {
      ...InitialTransportVehicles.all.map((vehicle) => vehicle.id),
      InitialTransportVehicles.defaultVehicleId,
    },
  );

  static bool backup(Map<String, dynamic> root) {
    if (root['data'] is! Map<String, dynamic>) return false;
    final data = root['data'] as Map<String, dynamic>;
    var changed = false;
    if (data['settings'] case final Map<String, dynamic> value) {
      changed = settings(value) || changed;
    }
    if (data['estimateWorkspace'] case final Map<String, dynamic> value) {
      changed = workspace(value) || changed;
    }
    if (data['productivityRecords'] case final List<dynamic> value) {
      changed = productivity(value) || changed;
    }
    return changed;
  }

  static List<Map<String, dynamic>> _maps(Object? value) => switch (value) {
    final List<dynamic> list => list.whereType<Map<String, dynamic>>().toList(),
    _ => const [],
  };

  static bool _ids(
    List<Map<String, dynamic>> values, {
    Set<String> forbidden = const {},
  }) {
    final reserved = <String>{...forbidden};
    for (final value in values) {
      if (value['id'] case final String id when id.trim().isNotEmpty) {
        reserved.add(id);
      }
    }
    final seen = <String>{...forbidden};
    var changed = false;
    for (final value in values) {
      final raw = value['id'];
      // A wrong type remains invalid and must be rejected by the validator.
      if (raw != null && raw is! String) continue;
      final id = raw as String?;
      if (id != null && id.trim().isNotEmpty && seen.add(id)) continue;
      final replacement = PersistentId.create(excluding: reserved);
      value['id'] = replacement;
      reserved.add(replacement);
      seen.add(replacement);
      changed = true;
    }
    return changed;
  }
}
