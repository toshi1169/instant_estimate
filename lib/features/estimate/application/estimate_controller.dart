import 'package:flutter/foundation.dart';

import '../data/estimate_item_store.dart';
import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';
import '../domain/estimate_workspace.dart';

class EstimateController extends ChangeNotifier {
  EstimateController({this.store, DateTime? now})
    : _info = EstimateInfo.initial(now ?? DateTime.now());

  final EstimateItemStore? store;
  final List<EstimateItem> _items = [];
  final List<EstimateDocument> _estimates = [];
  EstimateInfo _info;
  bool _loaded = false;

  List<EstimateItem> get items => List.unmodifiable(_items);
  EstimateInfo get info => _info;
  List<EstimateDocument> get estimates =>
      List.unmodifiable(_workspaceWithActive().estimates);
  bool get isLoaded => _loaded;
  double get totalAmount =>
      _items.fold(0, (total, item) => total + (item.amount ?? 0));

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

  Future<EstimateItem> add(EstimateItemDraft draft) async {
    final now = DateTime.now();
    final item = EstimateItem.fromDraft(
      draft,
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
    );
    final updated = [..._items, item];
    await _save(updated);
    _items
      ..clear()
      ..addAll(updated);
    notifyListeners();
    return item;
  }

  Future<EstimateItem> update(String id, EstimateItemDraft draft) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Estimate item was not found.');
    final current = _items[index];
    final updatedItem = EstimateItem.fromDraft(
      draft,
      id: current.id,
      createdAt: current.createdAt,
    );
    final updated = List<EstimateItem>.of(_items)..[index] = updatedItem;
    await _save(updated);
    _items
      ..clear()
      ..addAll(updated);
    notifyListeners();
    return updatedItem;
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
    if (_estimates.length >= 5) {
      throw StateError('Free estimate limit reached.');
    }
    final current = _currentDocument();
    final created = EstimateDocument(info: info, items: const []);
    final existing = _estimates.isEmpty ? [current] : _estimates;
    final estimates = [
      for (final estimate in existing)
        if (estimate.info.id == current.info.id) current else estimate,
      created,
    ];
    final workspace = EstimateWorkspace(
      activeEstimateId: created.info.id,
      estimates: estimates,
    );
    await store?.save(workspace);
    _replaceEstimates(estimates);
    _info = created.info;
    _items.clear();
    notifyListeners();
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
    );
    await store?.save(workspace);
    _replaceEstimates(estimates);
    _info = selected.info;
    _items
      ..clear()
      ..addAll(selected.items);
    notifyListeners();
  }

  Future<void> _save(List<EstimateItem> items) {
    return store?.save(_workspaceWithActive(items: items)) ??
        Future<void>.value();
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
    );
  }

  void _replaceEstimates(List<EstimateDocument> estimates) {
    _estimates
      ..clear()
      ..addAll(estimates);
  }
}
