import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_document.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';

class _MemoryEstimateItemStore implements EstimateItemStore {
  EstimateDocument document = EstimateDocument(
    info: EstimateInfo.initial(DateTime(2026, 8, 2)),
    items: const [],
  );

  List<EstimateItem> get items => document.items;

  @override
  Future<EstimateDocument> load() async => document;

  @override
  Future<void> save(EstimateDocument document) async {
    this.document = EstimateDocument(
      info: document.info,
      items: List.of(document.items),
    );
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

    await restored.updateInfo(
      restored.info.copyWith(
        estimateName: '○○邸 外構工事',
        siteName: '○○邸',
        clientName: '○○様',
        estimateNumber: '2026-001',
        notes: '概算',
      ),
    );
    expect(store.document.info.estimateName, '○○邸 外構工事');

    final infoRestored = EstimateController(store: store);
    await infoRestored.load();
    expect(infoRestored.info.siteName, '○○邸');
    expect(infoRestored.items.single.name, '根切り');

    await infoRestored.update(
      infoRestored.items.single.id,
      infoRestored.items.single.toDraft().copyWith(unitPrice: 5000),
    );
    expect(infoRestored.totalAmount, 12500);
    expect(store.items.single.unitPrice, 5000);

    await infoRestored.delete(infoRestored.items.single.id);
    expect(infoRestored.items, isEmpty);
    expect(store.items, isEmpty);
    expect(store.document.info.estimateName, '○○邸 外構工事');
  });
}
