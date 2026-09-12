import 'package:flutter/foundation.dart';
import '../../../core/domain/app_access_plan.dart';
import '../data/productivity_record_store.dart';
import '../domain/productivity_record.dart';

class ProductivityLimitException implements Exception {
  const ProductivityLimitException(this.limit);
  final int limit;
}

class ProductivityController extends ChangeNotifier {
  factory ProductivityController({
    ProductivityRecordStore? store,
    AppAccessPlan accessPlan = AppAccessPlan.free,
  }) => ProductivityController._(
    store ?? MemoryProductivityRecordStore(),
    accessPlan,
  );

  ProductivityController._(this.store, this._accessPlan);
  final ProductivityRecordStore store;
  AppAccessPlan _accessPlan;
  final List<ProductivityRecord> _records = [];
  bool _loaded = false;
  AppAccessPlan get accessPlan => _accessPlan;
  int get recordLimit => accessPlan.productivityRecordLimit;
  bool get canAdd => _records.length < recordLimit;
  bool get isLoaded => _loaded;
  List<ProductivityRecord> get records => List.unmodifiable(_records);

  void updateAccessPlan(AppAccessPlan accessPlan) {
    if (_accessPlan == accessPlan) return;
    _accessPlan = accessPlan;
    notifyListeners();
  }

  List<ProductivitySummary> get summaries {
    final grouped = <String, List<ProductivityRecord>>{};
    for (final record in _records) {
      grouped.putIfAbsent(record.groupKey, () => []).add(record);
    }
    return grouped.values.map(ProductivitySummary.fromRecords).toList()
      ..sort((a, b) => a.trade.compareTo(b.trade));
  }

  Future<void> load() async {
    if (_loaded) return;
    _records
      ..clear()
      ..addAll(await store.load());
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() async {
    final records = await store.load();
    _records
      ..clear()
      ..addAll(records);
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(ProductivityRecord record) async {
    if (!canAdd) throw ProductivityLimitException(recordLimit);
    final updated = [..._records, record];
    await store.save(updated);
    _records
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final updated = _records.where((record) => record.id != id).toList();
    if (updated.length == _records.length) return;
    await store.save(updated);
    _records
      ..clear()
      ..addAll(updated);
    notifyListeners();
  }
}
