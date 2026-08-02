import 'package:flutter/foundation.dart';

import '../data/estimate_item_store.dart';
import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';

class EstimateController extends ChangeNotifier {
  EstimateController({this.store, DateTime? now})
    : _info = EstimateInfo.initial(now ?? DateTime.now());

  final EstimateItemStore? store;
  final List<EstimateItem> _items = [];
  EstimateInfo _info;
  bool _loaded = false;

  List<EstimateItem> get items => List.unmodifiable(_items);
  EstimateInfo get info => _info;
  bool get isLoaded => _loaded;
  double get totalAmount =>
      _items.fold(0, (total, item) => total + (item.amount ?? 0));

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    if (store == null) {
      notifyListeners();
      return;
    }
    try {
      final document = await store!.load();
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
    await store?.save(EstimateDocument(info: info, items: _items));
    _info = info;
    notifyListeners();
  }

  Future<void> _save(List<EstimateItem> items) {
    return store?.save(EstimateDocument(info: _info, items: items)) ??
        Future<void>.value();
  }
}
