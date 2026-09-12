import 'package:flutter/foundation.dart';

import '../../../core/domain/app_access_plan.dart';
import '../data/estimate_item_store.dart';
import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';
import '../domain/estimate_item_group.dart';
import '../domain/estimate_workspace.dart';
import '../domain/estimate_totals.dart';
import '../domain/unit_price_master.dart';

class EstimateController extends ChangeNotifier {
  EstimateController({
    this.store,
    AppAccessPlan accessPlan = AppAccessPlan.free,
    DateTime? now,
  }) : _info = EstimateInfo.initial(now ?? DateTime.now()) {
    _accessPlan = accessPlan;
  }

  final EstimateItemStore? store;
  late AppAccessPlan _accessPlan;
  final List<EstimateItem> _items = [];
  final List<EstimateDocument> _estimates = [];
  final List<UnitPriceMaster> _unitPriceMasters = [];
  EstimateInfo _info;
  bool _loaded = false;

  List<EstimateItem> get items => List.unmodifiable(_items);
  EstimateInfo get info => _info;
  List<EstimateDocument> get estimates => List.unmodifiable(_estimates);
  List<UnitPriceMaster> get unitPriceMasters =>
      List.unmodifiable(_unitPriceMasters);
  bool get isLoaded => _loaded;
  AppAccessPlan get accessPlan => _accessPlan;
  int? get estimateLimit => accessPlan.estimateLimit;
  int? get unitPriceMasterLimit => accessPlan.unitPriceMasterLimit;
  bool get canCreateEstimate =>
      estimateLimit == null || _estimates.length < estimateLimit!;
  bool get canAddUnitPriceMaster =>
      unitPriceMasterLimit == null ||
      _unitPriceMasters.length < unitPriceMasterLimit!;
  double get totalAmount =>
      _items.fold(0, (total, item) => total + (item.amount ?? 0));

  void updateAccessPlan(AppAccessPlan accessPlan) {
    if (_accessPlan == accessPlan) return;
    _accessPlan = accessPlan;
    notifyListeners();
  }

  int get subtotalAmount => estimateSubtotal(_items);
  int get taxAmount => estimateTax(subtotalAmount);
  int get grandTotalAmount => subtotalAmount + taxAmount;
  List<EstimateItemGroup> get groups {
    final locationsBySymbol = _constructionLocationsBySymbol(_items);
    final grouped = <(String, String), List<EstimateItem>>{};
    for (final item in _items) {
      final symbol = item.constructionSymbol.trim();
      grouped
          .putIfAbsent((
            symbol,
            symbol.isEmpty
                ? item.constructionLocation.trim()
                : locationsBySymbol[symbol] ?? item.constructionLocation.trim(),
          ), () => [])
          .add(item);
    }
    return [
      for (final entry in grouped.entries)
        EstimateItemGroup(
          constructionSymbol: entry.key.$1,
          constructionLocation: entry.key.$2,
          items: List.unmodifiable(entry.value),
        ),
    ];
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    if (store == null) {
      _estimates
        ..clear()
        ..add(_currentDocument());
      notifyListeners();
      return;
    }
    try {
      final workspace = await store!.load();
      _estimates
        ..clear()
        ..addAll(workspace.estimates);
      _unitPriceMasters
        ..clear()
        ..addAll(workspace.unitPriceMasters);
      if (_estimates.isEmpty) {
        _info = EstimateInfo.initial(DateTime.now());
        _items.clear();
        notifyListeners();
        return;
      }
      final document = _estimates.firstWhere(
        (estimate) => estimate.info.id == workspace.activeEstimateId,
        orElse: () => _estimates.first,
      );
      _info = document.info;
      _items
        ..clear()
        ..addAll(document.items);
    } catch (_) {
      _loaded = false;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  Future<EstimateItem> add(EstimateItemDraft draft) async {
    final now = DateTime.now();
    final resolvedDraft = _resolveConstructionLocation(draft);
    final item = EstimateItem.fromDraft(
      resolvedDraft,
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
    );
    final updated = _synchronizeConstructionLocation([..._items, item], item);
    await _save(updated);
    _items
      ..clear()
      ..addAll(updated);
    notifyListeners();
    return updated.firstWhere((candidate) => candidate.id == item.id);
  }

  EstimateItem? findDuplicate(EstimateItemDraft draft) {
    final calculationBasis = _normalizedText(draft.calculationBasis);
    for (final item in _items.reversed) {
      if (calculationBasis.isNotEmpty &&
          _normalizedText(item.calculationBasis) == calculationBasis) {
        return item;
      }
      if (calculationBasis.isEmpty &&
          _normalizedText(item.calculationBasis).isEmpty &&
          _normalizedText(item.constructionSymbol) ==
              _normalizedText(draft.constructionSymbol) &&
          _normalizedText(item.trade) == _normalizedText(draft.trade) &&
          _normalizedText(item.constructionLocation) ==
              _normalizedText(draft.constructionLocation) &&
          _normalizedText(item.name) == _normalizedText(draft.name) &&
          _normalizedText(item.specification) ==
              _normalizedText(draft.specification) &&
          item.quantity == draft.quantity &&
          _normalizedText(item.unit) == _normalizedText(draft.unit) &&
          item.unitPrice == draft.unitPrice &&
          _normalizedText(item.description) ==
              _normalizedText(draft.description)) {
        return item;
      }
    }
    return null;
  }

  EstimateItem? findQuantityMergeCandidate(EstimateItemDraft draft) {
    final name = _normalizedText(draft.name);
    final unit = _normalizedText(draft.unit);
    final constructionLocation = _normalizedText(draft.constructionLocation);
    final constructionSymbol = _normalizedText(draft.constructionSymbol);
    if (name.isEmpty ||
        unit.isEmpty ||
        draft.quantity == null ||
        draft.unitPrice == null) {
      return null;
    }
    for (final item in _items.reversed) {
      if (item.quantity != null &&
          item.unitPrice == draft.unitPrice &&
          _normalizedText(item.constructionSymbol) == constructionSymbol &&
          _normalizedText(item.constructionLocation) == constructionLocation &&
          _normalizedText(item.name) == name &&
          _normalizedText(item.unit) == unit) {
        return item;
      }
    }
    return null;
  }

  Future<EstimateItem> mergeQuantity(
    String id,
    EstimateItemDraft incoming,
  ) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Estimate item was not found.');
    final current = _items[index];
    final currentQuantity = current.quantity;
    final incomingQuantity = incoming.quantity;
    if (currentQuantity == null || incomingQuantity == null) {
      throw StateError('Estimate quantity was not found.');
    }
    final currentBasis = current.calculationBasis.trim();
    final incomingBasis = incoming.calculationBasis.trim();
    final mergedBasis = switch ((currentBasis, incomingBasis)) {
      ('', final value) => value,
      (final value, '') => value,
      (final first, final second) => '$first\n＋ $second',
    };
    final mergedOriginalQuantity =
        current.originalQuantity != null && incoming.originalQuantity != null
        ? current.originalQuantity! + incoming.originalQuantity!
        : null;
    return update(
      id,
      EstimateItemDraft(
        constructionSymbol: current.constructionSymbol,
        trade: current.trade,
        constructionLocation: current.constructionLocation,
        name: current.name,
        specification: current.specification,
        quantity: currentQuantity + incomingQuantity,
        unit: current.unit,
        unitPrice: current.unitPrice,
        description: current.description,
        calculationBasis: mergedBasis,
        originalQuantity: mergedOriginalQuantity,
      ),
    );
  }

  Future<EstimateItem> update(String id, EstimateItemDraft draft) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Estimate item was not found.');
    final current = _items[index];
    final resolvedDraft = _resolveConstructionLocation(
      draft,
      excludingItemId: id,
    );
    final updatedItem = EstimateItem.fromDraft(
      resolvedDraft,
      id: current.id,
      createdAt: current.createdAt,
    );
    final replaced = List<EstimateItem>.of(_items)..[index] = updatedItem;
    final updated = _synchronizeConstructionLocation(replaced, updatedItem);
    await _save(updated);
    _items
      ..clear()
      ..addAll(updated);
    notifyListeners();
    return updated.firstWhere((candidate) => candidate.id == id);
  }

  Future<void> delete(String id) async {
    final updated = _items.where((item) => item.id != id).toList();
    if (updated.length == _items.length) return;
    await _save(updated);
    _items
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }

  Future<void> updateInfo(EstimateInfo info) async {
    final workspace = _workspaceWithActive(info: info);
    await store?.save(workspace);
    _replaceEstimates(workspace.estimates);
    _info = info;
    notifyListeners();
  }

  Future<void> createEstimate(EstimateInfo info) async {
    if (!canCreateEstimate) {
      throw StateError('Free estimate limit reached.');
    }
    final created = EstimateDocument(info: info, items: const []);
    final current = _currentDocument();
    final existing = _estimates;
    final estimates = [
      for (final estimate in existing)
        if (estimate.info.id == current.info.id) current else estimate,
      created,
    ];
    final workspace = EstimateWorkspace(
      activeEstimateId: created.info.id,
      estimates: estimates,
      unitPriceMasters: _unitPriceMasters,
    );
    await store?.save(workspace);
    _replaceEstimates(estimates);
    _info = created.info;
    _items.clear();
    notifyListeners();
  }

  Future<EstimateDocument> duplicateEstimate(String id) async {
    if (!canCreateEstimate) {
      throw StateError('Free estimate limit reached.');
    }
    final currentWorkspace = _workspaceWithActive();
    final source = currentWorkspace.estimates.firstWhere(
      (estimate) => estimate.info.id == id,
      orElse: () => throw StateError('Estimate was not found.'),
    );
    final now = DateTime.now();
    final copyId = now.microsecondsSinceEpoch.toString();
    final copiedInfo = EstimateInfo(
      id: copyId,
      estimateName: '${source.info.displayName}（コピー）',
      siteName: source.info.siteName,
      clientName: source.info.clientName,
      createdDate: DateTime(now.year, now.month, now.day),
      estimateNumber: '',
      notes: source.info.notes,
      proviso: source.info.proviso,
      validityPeriod: source.info.validityPeriod,
      constructionPeriod: source.info.constructionPeriod,
      paymentTerms: source.info.paymentTerms,
    );
    final copiedItems = [
      for (var index = 0; index < source.items.length; index++)
        EstimateItem.fromDraft(
          source.items[index].toDraft(),
          id: '$copyId-$index',
          createdAt: now.add(Duration(microseconds: index)),
        ),
    ];
    final copied = EstimateDocument(info: copiedInfo, items: copiedItems);
    final estimates = [...currentWorkspace.estimates, copied];
    final workspace = EstimateWorkspace(
      activeEstimateId: copiedInfo.id,
      estimates: estimates,
      unitPriceMasters: _unitPriceMasters,
    );
    await store?.save(workspace);
    _replaceEstimates(estimates);
    _info = copiedInfo;
    _items
      ..clear()
      ..addAll(copiedItems);
    notifyListeners();
    return copied;
  }

  Future<void> selectEstimate(String id) async {
    if (id == _info.id) return;
    final selected = _estimates.firstWhere(
      (estimate) => estimate.info.id == id,
      orElse: () => throw StateError('Estimate was not found.'),
    );
    final estimates = [
      for (final estimate in _estimates)
        if (estimate.info.id == _info.id) _currentDocument() else estimate,
    ];
    final workspace = EstimateWorkspace(
      activeEstimateId: selected.info.id,
      estimates: estimates,
      unitPriceMasters: _unitPriceMasters,
    );
    await store?.save(workspace);
    _replaceEstimates(estimates);
    _info = selected.info;
    _items
      ..clear()
      ..addAll(selected.items);
    notifyListeners();
  }

  Future<void> deleteEstimate(String id) async {
    final currentWorkspace = _workspaceWithActive();
    if (currentWorkspace.estimates.length <= 1) {
      throw StateError('The final estimate cannot be deleted.');
    }
    final remaining = currentWorkspace.estimates
        .where((estimate) => estimate.info.id != id)
        .toList(growable: false);
    if (remaining.length == currentWorkspace.estimates.length) return;
    final activeId = id == _info.id ? remaining.first.info.id : _info.id;
    final active = remaining.firstWhere(
      (estimate) => estimate.info.id == activeId,
    );
    final workspace = EstimateWorkspace(
      activeEstimateId: activeId,
      estimates: remaining,
      unitPriceMasters: _unitPriceMasters,
    );
    await store?.save(workspace);
    _replaceEstimates(remaining);
    _info = active.info;
    _items
      ..clear()
      ..addAll(active.items);
    notifyListeners();
  }

  Future<void> _save(List<EstimateItem> items) async {
    final workspace = _workspaceWithActive(items: items);
    await store?.save(workspace);
    _replaceEstimates(workspace.estimates);
  }

  EstimateItemDraft _resolveConstructionLocation(
    EstimateItemDraft draft, {
    String? excludingItemId,
  }) {
    final symbol = draft.constructionSymbol.trim();
    final requestedLocation = draft.constructionLocation.trim();
    if (symbol.isEmpty || requestedLocation.isNotEmpty) {
      return draft.copyWith(
        constructionSymbol: symbol,
        constructionLocation: requestedLocation,
      );
    }
    final existingLocation = _items
        .where((item) => item.id != excludingItemId)
        .where(
          (item) =>
              _normalizedText(item.constructionSymbol) ==
                  _normalizedText(symbol) &&
              item.constructionLocation.trim().isNotEmpty,
        )
        .map((item) => item.constructionLocation.trim())
        .firstOrNull;
    return draft.copyWith(
      constructionSymbol: symbol,
      constructionLocation: existingLocation ?? '',
    );
  }

  List<EstimateItem> _synchronizeConstructionLocation(
    List<EstimateItem> items,
    EstimateItem savedItem,
  ) {
    final symbol = savedItem.constructionSymbol.trim();
    if (symbol.isEmpty) return items;
    final location = savedItem.constructionLocation.trim();
    return [
      for (final item in items)
        if (_normalizedText(item.constructionSymbol) ==
                _normalizedText(symbol) &&
            item.constructionLocation.trim() != location)
          EstimateItem.fromDraft(
            item.toDraft().copyWith(constructionLocation: location),
            id: item.id,
            createdAt: item.createdAt,
          )
        else
          item,
    ];
  }

  Future<UnitPriceMaster> addUnitPriceMaster(UnitPriceMasterDraft draft) async {
    if (!canAddUnitPriceMaster) {
      throw StateError('Free unit price master limit reached.');
    }
    final now = DateTime.now();
    final price = UnitPriceMaster.fromDraft(
      draft,
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
    );
    final updated = [..._unitPriceMasters, price];
    await store?.save(_workspaceWithActive(unitPriceMasters: updated));
    _replaceUnitPriceMasters(updated);
    notifyListeners();
    return price;
  }

  Future<bool> addEstimateItemToUnitPriceMasterIfAbsent(
    EstimateItemDraft draft,
  ) async {
    final name = draft.name.trim();
    final unitPrice = draft.unitPrice;
    if (name.isEmpty || unitPrice == null) return false;
    final masterDraft = UnitPriceMasterDraft(
      trade: draft.trade.trim(),
      name: name,
      specification: draft.specification.trim(),
      unit: draft.unit.trim(),
      unitPrice: unitPrice,
      description: draft.description.trim(),
    );
    if (_unitPriceMasters.any(
      (price) => _hasSameUnitPriceMasterContent(price, masterDraft),
    )) {
      return false;
    }
    await addUnitPriceMaster(masterDraft);
    return true;
  }

  Future<void> updateUnitPriceMaster(
    String id,
    UnitPriceMasterDraft draft,
  ) async {
    final index = _unitPriceMasters.indexWhere((price) => price.id == id);
    if (index < 0) throw StateError('Unit price was not found.');
    final current = _unitPriceMasters[index];
    final updatedPrice = UnitPriceMaster.fromDraft(
      draft,
      id: current.id,
      createdAt: current.createdAt,
    );
    final updated = List<UnitPriceMaster>.of(_unitPriceMasters)
      ..[index] = updatedPrice;
    await store?.save(_workspaceWithActive(unitPriceMasters: updated));
    _replaceUnitPriceMasters(updated);
    notifyListeners();
  }

  Future<void> deleteUnitPriceMaster(String id) async {
    final updated = _unitPriceMasters
        .where((price) => price.id != id)
        .toList(growable: false);
    if (updated.length == _unitPriceMasters.length) return;
    await store?.save(_workspaceWithActive(unitPriceMasters: updated));
    _replaceUnitPriceMasters(updated);
    notifyListeners();
  }

  EstimateDocument _currentDocument({
    EstimateInfo? info,
    List<EstimateItem>? items,
  }) => EstimateDocument(
    info: info ?? _info,
    items: List.unmodifiable(items ?? _items),
  );

  EstimateWorkspace _workspaceWithActive({
    EstimateInfo? info,
    List<EstimateItem>? items,
    List<UnitPriceMaster>? unitPriceMasters,
  }) {
    final active = _currentDocument(info: info, items: items);
    final estimates = _estimates.isEmpty
        ? [active]
        : [
            for (final estimate in _estimates)
              if (estimate.info.id == _info.id) active else estimate,
          ];
    return EstimateWorkspace(
      activeEstimateId: active.info.id,
      estimates: estimates,
      unitPriceMasters: List.unmodifiable(
        unitPriceMasters ?? _unitPriceMasters,
      ),
    );
  }

  void _replaceEstimates(List<EstimateDocument> estimates) {
    _estimates
      ..clear()
      ..addAll(estimates);
  }

  void _replaceUnitPriceMasters(List<UnitPriceMaster> unitPriceMasters) {
    _unitPriceMasters
      ..clear()
      ..addAll(unitPriceMasters);
  }
}

String _normalizedText(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

Map<String, String> _constructionLocationsBySymbol(
  Iterable<EstimateItem> items,
) {
  final locations = <String, String>{};
  for (final item in items) {
    final symbol = item.constructionSymbol.trim();
    final location = item.constructionLocation.trim();
    if (symbol.isNotEmpty && location.isNotEmpty) {
      locations.putIfAbsent(symbol, () => location);
    }
  }
  return locations;
}

bool _hasSameUnitPriceMasterContent(
  UnitPriceMaster price,
  UnitPriceMasterDraft draft,
) =>
    _normalized(price.trade) == _normalized(draft.trade) &&
    _normalized(price.name) == _normalized(draft.name) &&
    _normalized(price.specification) == _normalized(draft.specification) &&
    _normalized(price.unit) == _normalized(draft.unit) &&
    price.unitPrice == draft.unitPrice &&
    _normalized(price.description) == _normalized(draft.description);

String _normalized(String value) => value.trim().toLowerCase();
