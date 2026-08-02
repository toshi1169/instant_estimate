import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

class _MemoryEstimateItemStore implements EstimateItemStore {
  List<EstimateItem> items = [];

  @override
  Future<List<EstimateItem>> load() async => List.of(items);

  @override
  Future<void> save(List<EstimateItem> items) async {
    this.items = List.of(items);
  }
}

void main() {
  test('見積明細を保存し新しいコントローラーで復元できる', () async {
    final store = _MemoryEstimateItemStore();
    final first = EstimateController(store: store);
    await first.load();
    await first.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2.5,
        unit: 'm³',
        unitPrice: 4000,
        calculationBasis: '5 × 1 × 0.5 = 2.5',
      ),
    );

    expect(first.items, hasLength(1));
    expect(first.totalAmount, 10000);

    final restored = EstimateController(store: store);
    await restored.load();
    expect(restored.items.single.name, '根切り');
    expect(restored.items.single.calculationBasis, '5 × 1 × 0.5 = 2.5');
    expect(restored.totalAmount, 10000);
  });
}
