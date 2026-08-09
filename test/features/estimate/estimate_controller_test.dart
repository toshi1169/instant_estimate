import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_document.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_workspace.dart';
import 'package:instant_estimate/features/estimate/domain/unit_price_master.dart';

class _MemoryEstimateItemStore implements EstimateItemStore {
  late EstimateWorkspace workspace;

  _MemoryEstimateItemStore() {
    final document = EstimateDocument(
      info: EstimateInfo.initial(DateTime(2026, 8, 2)),
      items: const [],
    );
    workspace = EstimateWorkspace(
      activeEstimateId: document.info.id,
      estimates: [document],
    );
  }

  EstimateDocument get document => workspace.estimates.firstWhere(
    (estimate) => estimate.info.id == workspace.activeEstimateId,
  );

  List<EstimateItem> get items => document.items;

  @override
  Future<EstimateWorkspace> load() async => workspace;

  @override
  Future<void> save(EstimateWorkspace workspace) async {
    this.workspace = EstimateWorkspace(
      activeEstimateId: workspace.activeEstimateId,
      estimates: [
        for (final document in workspace.estimates)
          EstimateDocument(info: document.info, items: List.of(document.items)),
      ],
      unitPriceMasters: List.of(workspace.unitPriceMasters),
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

  test('同じ計算根拠または同じ手入力内容の見積明細を重複候補として検出できる', () async {
    final controller = EstimateController();
    await controller.load();
    final calculated = await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2.5,
        unit: 'm³',
        unitPrice: 4000,
        calculationBasis: '5 × 1 × 0.5 = 2.5',
      ),
    );
    final manual = await controller.add(
      const EstimateItemDraft(
        trade: '外構工事',
        name: 'フェンス',
        specification: 'H800',
        quantity: 5,
        unit: 'm',
        unitPrice: 6000,
        description: '材料施工共',
      ),
    );

    expect(
      controller
          .findDuplicate(
            const EstimateItemDraft(
              trade: '土工事',
              name: '掘削へ変更',
              quantity: 3,
              unit: 'm³',
              calculationBasis: ' 5   × 1 × 0.5 = 2.5 ',
            ),
          )
          ?.id,
      calculated.id,
    );
    expect(
      controller
          .findDuplicate(
            const EstimateItemDraft(
              trade: ' 外構工事 ',
              name: 'フェンス',
              specification: 'H800',
              quantity: 5,
              unit: 'm',
              unitPrice: 6000,
              description: '材料施工共',
            ),
          )
          ?.id,
      manual.id,
    );
    expect(
      controller.findDuplicate(
        const EstimateItemDraft(
          trade: '外構工事',
          name: 'フェンス',
          specification: 'H800',
          quantity: 6,
          unit: 'm',
          unitPrice: 6000,
          description: '材料施工共',
        ),
      ),
      isNull,
    );
  });

  test('名称・単位・単価が同じ明細を検出して数量と計算根拠を加算できる', () async {
    final controller = EstimateController();
    await controller.load();
    final existing = await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 7.2,
        unit: 'm³',
        unitPrice: 4500,
        calculationBasis: '12 × 1.2 × 0.5 = 7.2',
        originalQuantity: 7.2,
      ),
    );
    const incoming = EstimateItemDraft(
      trade: '別工種でも候補になる',
      name: ' 根切り ',
      quantity: 3.5,
      unit: 'm³',
      unitPrice: 4500,
      calculationBasis: '7 × 1 × 0.5 = 3.5',
      originalQuantity: 3.5,
    );

    expect(controller.findQuantityMergeCandidate(incoming)?.id, existing.id);
    final merged = await controller.mergeQuantity(existing.id, incoming);

    expect(controller.items, hasLength(1));
    expect(merged.quantity, closeTo(10.7, 0.000001));
    expect(merged.originalQuantity, closeTo(10.7, 0.000001));
    expect(merged.trade, '土工事');
    expect(merged.calculationBasis, contains('12 × 1.2 × 0.5 = 7.2'));
    expect(merged.calculationBasis, contains('7 × 1 × 0.5 = 3.5'));
    expect(
      controller.findQuantityMergeCandidate(incoming.copyWith(unitPrice: 4600)),
      isNull,
    );
  });

  test('複数の見積を作成して選択中の見積と明細を復元できる', () async {
    final store = _MemoryEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.updateInfo(
      controller.info.copyWith(estimateName: '1件目の見積'),
    );
    await controller.add(const EstimateItemDraft(name: '1件目の明細'));

    final secondInfo = EstimateInfo.initial(
      DateTime(2026, 8, 3),
    ).copyWith(estimateName: '2件目の見積');
    await controller.createEstimate(secondInfo);
    expect(controller.estimates, hasLength(2));
    expect(controller.info.estimateName, '2件目の見積');
    expect(controller.items, isEmpty);
    await controller.add(const EstimateItemDraft(name: '2件目の明細'));

    final firstId = controller.estimates.first.info.id;
    await controller.selectEstimate(firstId);
    expect(controller.info.estimateName, '1件目の見積');
    expect(controller.items.single.name, '1件目の明細');

    final restored = EstimateController(store: store);
    await restored.load();
    expect(restored.info.estimateName, '1件目の見積');
    expect(restored.estimates, hasLength(2));
    await restored.selectEstimate(secondInfo.id);
    expect(restored.items.single.name, '2件目の明細');

    await restored.deleteEstimate(secondInfo.id);
    expect(restored.estimates, hasLength(1));
    expect(restored.info.estimateName, '1件目の見積');
    expect(restored.items.single.name, '1件目の明細');
    expect(store.workspace.estimates, hasLength(1));
    await expectLater(
      restored.deleteEstimate(restored.info.id),
      throwsStateError,
    );
  });

  test('無料版では見積を5件まで作成できる', () async {
    final controller = EstimateController();
    await controller.load();
    for (var day = 3; day <= 6; day++) {
      await controller.createEstimate(
        EstimateInfo.initial(DateTime(2026, 8, day)),
      );
    }
    expect(controller.estimates, hasLength(5));
    await expectLater(
      controller.createEstimate(EstimateInfo.initial(DateTime(2026, 8, 7))),
      throwsStateError,
    );
    await expectLater(
      controller.duplicateEstimate(controller.info.id),
      throwsStateError,
    );
  });

  test('完全版では見積件数を制限しない', () async {
    final controller = EstimateController(accessPlan: AppAccessPlan.full);
    await controller.load();
    for (var day = 2; day <= 7; day++) {
      await controller.createEstimate(
        EstimateInfo.initial(DateTime(2026, 8, day)),
      );
    }
    expect(controller.estimates, hasLength(7));
    expect(controller.estimateLimit, isNull);
  });

  test('無料版の単価マスタは10件まで、完全版は無制限に追加できる', () async {
    final free = EstimateController();
    await free.load();
    for (var index = 0; index < 10; index++) {
      await free.addUnitPriceMaster(
        UnitPriceMasterDraft(name: '項目$index', unitPrice: index + 1),
      );
    }
    expect(free.canAddUnitPriceMaster, isFalse);
    await expectLater(
      free.addUnitPriceMaster(
        const UnitPriceMasterDraft(name: '上限超過', unitPrice: 100),
      ),
      throwsStateError,
    );

    final full = EstimateController(accessPlan: AppAccessPlan.full);
    await full.load();
    for (var index = 0; index < 11; index++) {
      await full.addUnitPriceMaster(
        UnitPriceMasterDraft(name: '項目$index', unitPrice: index + 1),
      );
    }
    expect(full.unitPriceMasters, hasLength(11));
    expect(full.unitPriceMasterLimit, isNull);
  });

  test('見積全体を別IDで複製してコピーを追加先にできる', () async {
    final store = _MemoryEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.updateInfo(
      controller.info.copyWith(
        estimateName: '○○邸 外構工事',
        siteName: '○○邸',
        clientName: '○○様',
        estimateNumber: '2026-001',
        notes: '既存見積',
      ),
    );
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2,
        unit: 'm³',
        unitPrice: 4000,
      ),
    );
    final sourceInfoId = controller.info.id;
    final sourceItemId = controller.items.single.id;

    final copied = await controller.duplicateEstimate(sourceInfoId);

    expect(controller.estimates, hasLength(2));
    expect(controller.info.id, copied.info.id);
    expect(copied.info.id, isNot(sourceInfoId));
    expect(copied.info.estimateName, '○○邸 外構工事（コピー）');
    expect(copied.info.siteName, '○○邸');
    expect(copied.info.clientName, '○○様');
    expect(copied.info.estimateNumber, isEmpty);
    expect(copied.info.notes, '既存見積');
    expect(copied.items.single.id, isNot(sourceItemId));
    expect(copied.items.single.name, '根切り');
    expect(copied.totalAmount, 8000);
    expect(store.workspace.activeEstimateId, copied.info.id);

    await controller.selectEstimate(sourceInfoId);
    expect(controller.info.estimateName, '○○邸 外構工事');
    expect(controller.items.single.id, sourceItemId);
  });

  test('明細を工種ごとにまとめて小計を計算できる', () async {
    final controller = EstimateController();
    await controller.load();
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2,
        unitPrice: 4000,
      ),
    );
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '埋戻し',
        quantity: 1,
        unitPrice: 3000,
      ),
    );
    await controller.add(
      const EstimateItemDraft(
        trade: '型枠工事',
        name: '基礎型枠',
        quantity: 5,
        unitPrice: 6000,
      ),
    );
    await controller.add(
      const EstimateItemDraft(name: '諸経費', quantity: 1, unitPrice: 500),
    );

    expect(controller.groups, hasLength(3));
    expect(controller.groups[0].displayName, '土工事');
    expect(controller.groups[0].items, hasLength(2));
    expect(controller.groups[0].subtotal, 11000);
    expect(controller.groups[1].displayName, '型枠工事');
    expect(controller.groups[1].subtotal, 30000);
    expect(controller.groups[2].displayName, '工種未設定');
    expect(controller.groups[2].subtotal, 500);
    expect(controller.totalAmount, 41500);
  });

  test('単価マスタを登録・編集・削除して再起動後も復元できる', () async {
    final store = _MemoryEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();

    final registered = await controller.addUnitPriceMaster(
      const UnitPriceMasterDraft(
        trade: '土工事',
        name: '根切り',
        specification: '機械掘削',
        unit: 'm³',
        unitPrice: 4500,
        description: '小運搬別途',
      ),
    );

    final restored = EstimateController(store: store);
    await restored.load();
    expect(restored.unitPriceMasters, hasLength(1));
    expect(restored.unitPriceMasters.single.name, '根切り');
    expect(restored.unitPriceMasters.single.unitPrice, 4500);

    await restored.updateUnitPriceMaster(
      registered.id,
      const UnitPriceMasterDraft(
        trade: '土工事',
        name: '根切り',
        specification: '機械掘削',
        unit: 'm³',
        unitPrice: 5000,
        description: '小運搬含む',
      ),
    );
    expect(restored.unitPriceMasters.single.unitPrice, 5000);
    expect(store.workspace.unitPriceMasters.single.description, '小運搬含む');

    await restored.deleteUnitPriceMaster(registered.id);
    expect(restored.unitPriceMasters, isEmpty);
    expect(store.workspace.unitPriceMasters, isEmpty);
  });

  test('見積明細の内容を単価マスタへ登録し同じ内容の重複を防ぐ', () async {
    final store = _MemoryEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    const draft = EstimateItemDraft(
      trade: ' 土工事 ',
      name: '根切り',
      specification: '機械掘削',
      quantity: 3,
      unit: 'm³',
      unitPrice: 4500,
      description: '小運搬別途',
    );

    expect(
      await controller.addEstimateItemToUnitPriceMasterIfAbsent(draft),
      isTrue,
    );
    expect(
      await controller.addEstimateItemToUnitPriceMasterIfAbsent(
        const EstimateItemDraft(
          trade: '土工事',
          name: ' 根切り ',
          specification: '機械掘削',
          unit: 'm³',
          unitPrice: 4500,
          description: '小運搬別途',
        ),
      ),
      isFalse,
    );
    expect(controller.unitPriceMasters, hasLength(1));
    expect(store.workspace.unitPriceMasters, hasLength(1));
  });
}
