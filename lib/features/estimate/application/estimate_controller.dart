import 'package:flutter/foundation.dart';

import '../data/estimate_item_store.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';

class EstimateController extends ChangeNotifier {
  EstimateController({this.store});

  final EstimateItemStore? store;
  final List<EstimateItem> _items = [];
  bool _loaded = false;

  List<EstimateItem> get items => List.unmodifiable(_items);
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
      _items
        ..clear()
        ..addAll(await store!.load());
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
    await store?.save(updated);
    _items
      ..clear()
      ..addAll(updated);
    notifyListeners();
    return item;
  }
}
