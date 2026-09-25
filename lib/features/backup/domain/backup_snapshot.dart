import 'dart:convert';
import 'dart:typed_data';

import '../../../core/domain/persistent_id_repair.dart';
import '../../calculator/data/calculation_history_store.dart';
import '../../estimate/domain/estimate_document.dart';
import '../../estimate/domain/estimate_info.dart';
import '../../estimate/domain/estimate_item.dart';
import '../../estimate/domain/estimate_workspace.dart';
import '../../estimate/domain/unit_price_master.dart';
import '../../onboarding/domain/occupation.dart';
import '../../productivity/domain/productivity_record.dart';
import '../../settings/domain/app_settings.dart';

class BackupValidationException implements FormatException {
  const BackupValidationException(this.message);
  @override
  final String message;
  @override
  int? get offset => null;
  @override
  String? get source => null;
  @override
  String toString() => 'BackupValidationException: $message';
}

class UnsupportedBackupVersionException extends BackupValidationException {
  const UnsupportedBackupVersionException(super.message);
}

class BackupSnapshot {
  const BackupSnapshot({
    required this.createdAt,
    required this.appVersion,
    required this.buildNumber,
    required this.data,
  });

  static const formatIdentifier =
      'com.matsumotoboundary.constructioncalc.backup';
  static const currentVersion = 1;

  final DateTime createdAt;
  final String appVersion;
  final String buildNumber;
  final BackupData data;

  Map<String, Object?> toJson() => <String, Object?>{
    'format': formatIdentifier,
    'backupVersion': currentVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'data': data.toJson(),
  };

  String encode({bool pretty = true}) =>
      (pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder())
          .convert(toJson());

  Uint8List encodeUtf8() => Uint8List.fromList(utf8.encode(encode()));

  factory BackupSnapshot.decode(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw BackupValidationException('JSON is invalid: ${error.message}');
    }
    return BackupSnapshot.fromJson(_asStringMap(decoded, r'$'));
  }

  factory BackupSnapshot.fromJson(Map<String, Object?> json) {
    // Clone before changing IDs: callers' backup data remains untouched.
    final normalized = _mutableCopy(json) as Map<String, dynamic>;
    PersistentIdRepair.backup(normalized);
    return _BackupV1Validator(normalized).decode();
  }
}

Object? _mutableCopy(Object? value) => switch (value) {
  final Map<String, Object?> map => map.map(
    (key, nested) => MapEntry(key, _mutableCopy(nested)),
  ),
  final List<Object?> list => list.map(_mutableCopy).toList(),
  _ => value,
};

class BackupData {
  const BackupData({
    required this.occupation,
    required this.settings,
    required this.calculatorHistory,
    required this.estimateWorkspace,
    required this.productivityRecords,
  });

  final Occupation occupation;
  final AppSettings settings;
  final List<StoredCalculationHistoryEntry> calculatorHistory;
  final EstimateWorkspace estimateWorkspace;
  final List<ProductivityRecord> productivityRecords;

  Map<String, Object?> toJson() => <String, Object?>{
    'occupation': occupation.storageKey,
    'settings': settings.toJson(),
    'calculatorHistory': calculatorHistory
        .map((entry) => entry.toJson())
        .toList(growable: false),
    'estimateWorkspace': estimateWorkspace.toJson(),
    'productivityRecords': productivityRecords
        .map((record) => record.toJson())
        .toList(growable: false),
  };
}

class _BackupV1Validator {
  _BackupV1Validator(this.root);
  final Map<String, Object?> root;

  BackupSnapshot decode() {
    _exactKeys(root, const {
      'format',
      'backupVersion',
      'createdAt',
      'appVersion',
      'buildNumber',
      'data',
    }, r'$');
    if (_string(root, 'format', r'$') != BackupSnapshot.formatIdentifier) {
      _fail(r'$.format', 'format does not match this app');
    }
    final version = _integer(root, 'backupVersion', r'$');
    if (version != BackupSnapshot.currentVersion) {
      throw UnsupportedBackupVersionException(
        version > BackupSnapshot.currentVersion
            ? 'backupVersion $version is newer than supported version ${BackupSnapshot.currentVersion}'
            : 'backupVersion $version is not supported',
      );
    }
    return BackupSnapshot(
      createdAt: _date(root, 'createdAt', r'$', requireUtc: true),
      appVersion: _nonEmptyString(root, 'appVersion', r'$'),
      buildNumber: _nonEmptyString(root, 'buildNumber', r'$'),
      data: _decodeData(_mapValue(root, 'data', r'$')),
    );
  }

  BackupData _decodeData(Map<String, Object?> json) {
    const path = r'$.data';
    _exactKeys(json, const {
      'occupation',
      'settings',
      'calculatorHistory',
      'estimateWorkspace',
      'productivityRecords',
    }, path);
    final occupationRaw = _nonEmptyString(json, 'occupation', path);
    final occupation = Occupation.values
        .where((value) => value.storageKey == occupationRaw)
        .firstOrNull;
    if (occupation == null) _fail('$path.occupation', 'unknown occupation');

    final settingsJson = _mapValue(json, 'settings', path);
    _validateSettings(settingsJson, '$path.settings');
    final history = <StoredCalculationHistoryEntry>[];
    final historyJson = _list(json, 'calculatorHistory', path);
    for (var index = 0; index < historyJson.length; index++) {
      final itemPath = '$path.calculatorHistory[$index]';
      final item = _asStringMap(historyJson[index], itemPath);
      _validateHistory(item, itemPath);
      history.add(StoredCalculationHistoryEntry.fromJson(item));
    }
    final workspace = _decodeWorkspace(
      _mapValue(json, 'estimateWorkspace', path),
      '$path.estimateWorkspace',
    );
    final records = <ProductivityRecord>[];
    final recordIds = <String>{};
    final recordsJson = _list(json, 'productivityRecords', path);
    for (var index = 0; index < recordsJson.length; index++) {
      final itemPath = '$path.productivityRecords[$index]';
      final item = _asStringMap(recordsJson[index], itemPath);
      _validateProductivityRecord(item, itemPath);
      final id = item['id']! as String;
      if (!recordIds.add(id)) _fail('$itemPath.id', 'duplicate id "$id"');
      records.add(ProductivityRecord.fromJson(item));
    }
    return BackupData(
      occupation: occupation,
      settings: AppSettings.fromJson(settingsJson),
      calculatorHistory: List.unmodifiable(history),
      estimateWorkspace: workspace,
      productivityRecords: List.unmodifiable(records),
    );
  }

  void _validateSettings(Map<String, Object?> json, String path) {
    _keysWithOptional(
      json,
      const {
        'language',
        'theme',
        'decimalPlaces',
        'roundingMode',
        'estimateDecimalPlaces',
        'estimateRoundingMode',
        'angleUnit',
        'historySortOrder',
        'confirmHistoryDeletion',
        'calculatorTapSoundEnabled',
        'calculatorHapticsEnabled',
        'customTransportVehicles',
        'customDensityMaterials',
        'companyProfile',
      },
      const {
        'improperFractionResultEnabled',
        'mixedFractionResultEnabled',
        'remainderResultEnabled',
      },
      path,
    );
    _enumName(json, 'language', path, const {
      'japanese',
      'english',
      'simplifiedChinese',
      'traditionalChinese',
      'vietnamese',
      'indonesian',
      'filipino',
      'myanmar',
    });
    _enumName(json, 'theme', path, const {'system', 'light', 'gray', 'dark'});
    _rangedInteger(json, 'decimalPlaces', path, 1, 5);
    _enumName(json, 'roundingMode', path, const {'halfUp', 'ceiling', 'floor'});
    _rangedInteger(json, 'estimateDecimalPlaces', path, 1, 5);
    _enumName(json, 'estimateRoundingMode', path, const {
      'halfUp',
      'ceiling',
      'floor',
    });
    _enumName(json, 'angleUnit', path, const {'degrees', 'radians'});
    _enumName(json, 'historySortOrder', path, const {
      'ascending',
      'descending',
    });
    _boolean(json, 'confirmHistoryDeletion', path);
    _boolean(json, 'calculatorTapSoundEnabled', path);
    _boolean(json, 'calculatorHapticsEnabled', path);
    if (json.containsKey('improperFractionResultEnabled')) {
      _boolean(json, 'improperFractionResultEnabled', path);
    }
    if (json.containsKey('mixedFractionResultEnabled')) {
      _boolean(json, 'mixedFractionResultEnabled', path);
    }
    if (json.containsKey('remainderResultEnabled')) {
      _boolean(json, 'remainderResultEnabled', path);
    }

    final vehicleIds = <String>{};
    final vehicles = _list(json, 'customTransportVehicles', path);
    for (var index = 0; index < vehicles.length; index++) {
      final itemPath = '$path.customTransportVehicles[$index]';
      final item = _asStringMap(vehicles[index], itemPath);
      _exactKeys(item, const {
        'id',
        'name',
        'initialCapacityCubicMeters',
        'maximumPayloadTons',
        'approximateCapacityLabel',
        'isCrawler',
        'isCustom',
      }, itemPath);
      final id = _nonEmptyString(item, 'id', itemPath);
      if (!vehicleIds.add(id)) _fail('$itemPath.id', 'duplicate id "$id"');
      _nonEmptyString(item, 'name', itemPath);
      if (_finiteNumber(item, 'initialCapacityCubicMeters', itemPath) <= 0) {
        _fail(
          '$itemPath.initialCapacityCubicMeters',
          'must be greater than zero',
        );
      }
      _nullableFiniteNumber(item, 'maximumPayloadTons', itemPath);
      _nullableString(item, 'approximateCapacityLabel', itemPath);
      _boolean(item, 'isCrawler', itemPath);
      _boolean(item, 'isCustom', itemPath);
    }
    final materials = _list(json, 'customDensityMaterials', path);
    for (var index = 0; index < materials.length; index++) {
      final itemPath = '$path.customDensityMaterials[$index]';
      final item = _asStringMap(materials[index], itemPath);
      _exactKeys(item, const {'name', 'density'}, itemPath);
      _nonEmptyString(item, 'name', itemPath);
      if (_finiteNumber(item, 'density', itemPath) <= 0) {
        _fail('$itemPath.density', 'must be greater than zero');
      }
    }
    _validateCompanyProfile(
      _mapValue(json, 'companyProfile', path),
      '$path.companyProfile',
    );
  }

  void _validateCompanyProfile(Map<String, Object?> json, String path) {
    _exactKeys(json, const {
      'companyName',
      'representativeName',
      'postalCode',
      'addressLine1',
      'addressLine2',
      'phoneNumber',
      'displayOrder',
      'excelVisibleSections',
    }, path);
    for (final key in const [
      'companyName',
      'representativeName',
      'postalCode',
      'addressLine1',
      'addressLine2',
      'phoneNumber',
    ]) {
      _string(json, key, path);
    }
    const allowed = {
      'companyName',
      'representativeName',
      'postalCode',
      'addressLine1',
      'addressLine2',
      'phoneNumber',
    };
    final order = _stringList(json, 'displayOrder', path);
    if (order.length != allowed.length ||
        order.toSet().length != order.length ||
        !order.toSet().containsAll(allowed)) {
      _fail('$path.displayOrder', 'must contain every current section once');
    }
    final visible = _stringList(json, 'excelVisibleSections', path);
    if (visible.length > 5 ||
        visible.toSet().length != visible.length ||
        visible.any((value) => !allowed.contains(value))) {
      _fail(
        '$path.excelVisibleSections',
        'contains invalid or duplicate sections',
      );
    }
  }

  void _validateHistory(Map<String, Object?> json, String path) {
    _keysWithOptional(
      json,
      const {
        'expression',
        'result',
        'decimalResult',
        'improperFractionResult',
        'mixedFractionResult',
        'createdAt',
      },
      const {'remainderResult'},
      path,
    );
    _string(json, 'expression', path);
    _string(json, 'result', path);
    _string(json, 'decimalResult', path);
    _nullableString(json, 'improperFractionResult', path);
    _nullableString(json, 'mixedFractionResult', path);
    if (json.containsKey('remainderResult')) {
      _nullableString(json, 'remainderResult', path);
    }
    _date(json, 'createdAt', path);
  }

  EstimateWorkspace _decodeWorkspace(Map<String, Object?> json, String path) {
    _exactKeys(json, const {
      'version',
      'activeEstimateId',
      'estimates',
      'unitPriceMasters',
    }, path);
    if (_integer(json, 'version', path) != 4) {
      _fail('$path.version', 'unsupported estimate workspace version');
    }
    final activeId = _string(json, 'activeEstimateId', path);
    final estimates = <EstimateDocument>[];
    final estimateIds = <String>{};
    final itemIds = <String>{};
    final estimatesJson = _list(json, 'estimates', path);
    for (var index = 0; index < estimatesJson.length; index++) {
      final documentPath = '$path.estimates[$index]';
      final document = _asStringMap(estimatesJson[index], documentPath);
      _exactKeys(document, const {'version', 'info', 'items'}, documentPath);
      if (_integer(document, 'version', documentPath) != 2) {
        _fail('$documentPath.version', 'unsupported estimate version');
      }
      final info = _mapValue(document, 'info', documentPath);
      _validateEstimateInfo(info, '$documentPath.info');
      final estimateId = info['id']! as String;
      if (!estimateIds.add(estimateId)) {
        _fail('$documentPath.info.id', 'duplicate id "$estimateId"');
      }
      final items = <EstimateItem>[];
      final itemsJson = _list(document, 'items', documentPath);
      for (var itemIndex = 0; itemIndex < itemsJson.length; itemIndex++) {
        final itemPath = '$documentPath.items[$itemIndex]';
        final item = _asStringMap(itemsJson[itemIndex], itemPath);
        _validateEstimateItem(item, itemPath);
        final itemId = item['id']! as String;
        if (!itemIds.add(itemId)) {
          _fail('$itemPath.id', 'duplicate id "$itemId"');
        }
        items.add(EstimateItem.fromJson(item));
      }
      estimates.add(
        EstimateDocument(info: EstimateInfo.fromJson(info), items: items),
      );
    }
    if (estimates.isEmpty && activeId.isNotEmpty) {
      _fail(
        '$path.activeEstimateId',
        'must be empty when there are no estimates',
      );
    }
    if (estimates.isNotEmpty && !estimateIds.contains(activeId)) {
      _fail('$path.activeEstimateId', 'does not reference an estimate');
    }
    final masters = <UnitPriceMaster>[];
    final masterIds = <String>{};
    final mastersJson = _list(json, 'unitPriceMasters', path);
    for (var index = 0; index < mastersJson.length; index++) {
      final itemPath = '$path.unitPriceMasters[$index]';
      final item = _asStringMap(mastersJson[index], itemPath);
      _validateUnitPriceMaster(item, itemPath);
      final id = item['id']! as String;
      if (!masterIds.add(id)) _fail('$itemPath.id', 'duplicate id "$id"');
      masters.add(UnitPriceMaster.fromJson(item));
    }
    return EstimateWorkspace(
      activeEstimateId: activeId,
      estimates: List.unmodifiable(estimates),
      unitPriceMasters: List.unmodifiable(masters),
    );
  }

  void _validateEstimateInfo(Map<String, Object?> json, String path) {
    _exactKeys(json, const {
      'id',
      'estimateName',
      'siteName',
      'clientName',
      'createdDate',
      'estimateNumber',
      'notes',
      'proviso',
      'validityPeriod',
      'constructionPeriod',
      'paymentTerms',
    }, path);
    _nonEmptyString(json, 'id', path);
    for (final key in const [
      'estimateName',
      'siteName',
      'clientName',
      'estimateNumber',
      'notes',
      'proviso',
      'validityPeriod',
      'constructionPeriod',
      'paymentTerms',
    ]) {
      _string(json, key, path);
    }
    _date(json, 'createdDate', path);
  }

  void _validateEstimateItem(Map<String, Object?> json, String path) {
    _exactKeys(json, const {
      'id',
      'createdAt',
      'constructionSymbol',
      'trade',
      'constructionLocation',
      'name',
      'specification',
      'quantity',
      'unit',
      'unitPrice',
      'description',
      'calculationBasis',
      'originalQuantity',
    }, path);
    _nonEmptyString(json, 'id', path);
    _date(json, 'createdAt', path);
    for (final key in const [
      'constructionSymbol',
      'trade',
      'constructionLocation',
      'name',
      'specification',
      'unit',
      'description',
      'calculationBasis',
    ]) {
      _string(json, key, path);
    }
    _nullableFiniteNumber(json, 'quantity', path);
    _nullableFiniteNumber(json, 'unitPrice', path);
    _nullableFiniteNumber(json, 'originalQuantity', path);
  }

  void _validateUnitPriceMaster(Map<String, Object?> json, String path) {
    _exactKeys(json, const {
      'id',
      'createdAt',
      'trade',
      'name',
      'specification',
      'unit',
      'unitPrice',
      'description',
    }, path);
    _nonEmptyString(json, 'id', path);
    _date(json, 'createdAt', path);
    for (final key in const [
      'trade',
      'name',
      'specification',
      'unit',
      'description',
    ]) {
      _string(json, key, path);
    }
    _nullableFiniteNumber(json, 'unitPrice', path);
  }

  void _validateProductivityRecord(Map<String, Object?> json, String path) {
    _exactKeys(json, const {
      'id',
      'createdAt',
      'trade',
      'taskName',
      'siteName',
      'workDate',
      'quantity',
      'unit',
      'workers',
      'workDays',
      'actualWorkHours',
      'actualLabor',
      'standardLaborRate',
      'standardProductivity',
      'actualLaborRate',
      'productivityPerLabor',
      'totalPersonHours',
      'hourlyProductivity',
      'productivityDifferencePercent',
      'conditions',
    }, path);
    _nonEmptyString(json, 'id', path);
    _date(json, 'createdAt', path);
    _date(json, 'workDate', path);
    for (final key in const [
      'trade',
      'taskName',
      'siteName',
      'unit',
      'conditions',
    ]) {
      _string(json, key, path);
    }
    for (final key in const [
      'quantity',
      'workers',
      'workDays',
      'actualLabor',
      'actualLaborRate',
      'productivityPerLabor',
    ]) {
      _finiteNumber(json, key, path);
    }
    if ((json['actualLabor']! as num).toDouble() <= 0) {
      _fail('$path.actualLabor', 'must be greater than zero');
    }
    for (final key in const [
      'actualWorkHours',
      'standardLaborRate',
      'standardProductivity',
      'totalPersonHours',
      'hourlyProductivity',
      'productivityDifferencePercent',
    ]) {
      _nullableFiniteNumber(json, key, path);
    }
  }

  void _exactKeys(Map<String, Object?> map, Set<String> expected, String path) {
    final missing = expected.difference(map.keys.toSet());
    final unknown = map.keys.toSet().difference(expected);
    if (missing.isNotEmpty) _fail(path, 'missing keys: ${missing.join(', ')}');
    if (unknown.isNotEmpty) _fail(path, 'unknown keys: ${unknown.join(', ')}');
  }

  void _keysWithOptional(
    Map<String, Object?> map,
    Set<String> required,
    Set<String> optional,
    String path,
  ) {
    final missing = required.difference(map.keys.toSet());
    final unknown = map.keys.toSet().difference(required.union(optional));
    if (missing.isNotEmpty) _fail(path, 'missing keys: ${missing.join(', ')}');
    if (unknown.isNotEmpty) _fail(path, 'unknown keys: ${unknown.join(', ')}');
  }

  Map<String, Object?> _mapValue(
    Map<String, Object?> map,
    String key,
    String path,
  ) => _asStringMap(_required(map, key, path), '$path.$key');

  List<Object?> _list(Map<String, Object?> map, String key, String path) {
    final value = _required(map, key, path);
    if (value is! List<Object?>) _fail('$path.$key', 'must be a list');
    return value;
  }

  List<String> _stringList(Map<String, Object?> map, String key, String path) {
    final values = _list(map, key, path);
    if (values.any((value) => value is! String)) {
      _fail('$path.$key', 'must contain only strings');
    }
    return values.cast<String>();
  }

  Object? _required(Map<String, Object?> map, String key, String path) {
    if (!map.containsKey(key)) _fail('$path.$key', 'is required');
    return map[key];
  }

  String _string(Map<String, Object?> map, String key, String path) {
    final value = _required(map, key, path);
    if (value is! String) _fail('$path.$key', 'must be a string');
    return value;
  }

  String _nonEmptyString(Map<String, Object?> map, String key, String path) {
    final value = _string(map, key, path);
    if (value.trim().isEmpty) _fail('$path.$key', 'must not be empty');
    return value;
  }

  void _nullableString(Map<String, Object?> map, String key, String path) {
    final value = _required(map, key, path);
    if (value != null && value is! String) {
      _fail('$path.$key', 'must be a string or null');
    }
  }

  int _integer(Map<String, Object?> map, String key, String path) {
    final value = _required(map, key, path);
    if (value is! int) _fail('$path.$key', 'must be an integer');
    return value;
  }

  void _rangedInteger(
    Map<String, Object?> map,
    String key,
    String path,
    int minimum,
    int maximum,
  ) {
    final value = _integer(map, key, path);
    if (value < minimum || value > maximum) {
      _fail('$path.$key', 'must be between $minimum and $maximum');
    }
  }

  double _finiteNumber(Map<String, Object?> map, String key, String path) {
    final value = _required(map, key, path);
    if (value is! num || !value.isFinite) {
      _fail('$path.$key', 'must be a finite number');
    }
    return value.toDouble();
  }

  void _nullableFiniteNumber(
    Map<String, Object?> map,
    String key,
    String path,
  ) {
    final value = _required(map, key, path);
    if (value != null && (value is! num || !value.isFinite)) {
      _fail('$path.$key', 'must be a finite number or null');
    }
  }

  bool _boolean(Map<String, Object?> map, String key, String path) {
    final value = _required(map, key, path);
    if (value is! bool) _fail('$path.$key', 'must be a boolean');
    return value;
  }

  DateTime _date(
    Map<String, Object?> map,
    String key,
    String path, {
    bool requireUtc = false,
  }) {
    final raw = _string(map, key, path);
    final value = DateTime.tryParse(raw);
    if (value == null || (requireUtc && (!value.isUtc || !raw.endsWith('Z')))) {
      _fail(
        '$path.$key',
        requireUtc ? 'must be a UTC ISO-8601 date' : 'must be an ISO-8601 date',
      );
    }
    return value;
  }

  void _enumName(
    Map<String, Object?> map,
    String key,
    String path,
    Set<String> allowed,
  ) {
    final value = _string(map, key, path);
    if (!allowed.contains(value)) {
      _fail('$path.$key', 'contains an unknown value');
    }
  }

  Never _fail(String path, String message) {
    throw BackupValidationException('$path: $message');
  }
}

Map<String, Object?> _asStringMap(Object? value, String path) {
  if (value is! Map<Object?, Object?>) {
    throw BackupValidationException('$path: must be an object');
  }
  if (value.keys.any((key) => key is! String)) {
    throw BackupValidationException('$path: object keys must be strings');
  }
  return value.map((key, value) => MapEntry(key as String, value));
}
