import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_document.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_workspace.dart';
import 'package:instant_estimate/features/estimate/domain/unit_price_master.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_record.dart';
import 'package:instant_estimate/features/settings/data/app_settings_store.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const estimateChannel = MethodChannel('jp.instant_estimate/estimate_items');
  const recordChannel = MethodChannel(
    'jp.instant_estimate/productivity_records',
  );
  const settingsChannel = MethodChannel('jp.instant_estimate/app_settings');

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(estimateChannel, null);
    messenger.setMockMethodCallHandler(recordChannel, null);
    messenger.setMockMethodCallHandler(settingsChannel, null);
  });

  test('見積・明細の重複修復を保存してから返し、再読込と1件削除でも安定', () async {
    final info = EstimateInfo.initial(DateTime.utc(2026, 1, 1));
    final item = EstimateItem.fromDraft(
      const EstimateItemDraft(name: 'one'),
      id: 'old-item',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final master = UnitPriceMaster.fromDraft(
      const UnitPriceMasterDraft(name: 'master one'),
      id: 'same-master',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final raw = EstimateWorkspace(
      activeEstimateId: 'old-estimate',
      estimates: [
        EstimateDocument(
          info: EstimateInfo.fromJson({...info.toJson(), 'id': 'old-estimate'}),
          items: [
            item,
            EstimateItem.fromJson({...item.toJson(), 'name': 'two'}),
          ],
        ),
        EstimateDocument(
          info: EstimateInfo.fromJson({
            ...info.toJson(),
            'id': 'old-estimate',
            'estimateName': 'second',
          }),
          items: const [],
        ),
      ],
      unitPriceMasters: [
        master,
        UnitPriceMaster.fromJson({...master.toJson(), 'name': 'master two'}),
      ],
    );
    var stored = jsonEncode(raw.toJson());
    var saves = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(estimateChannel, (call) async {
          if (call.method == 'loadEstimateItems') return stored;
          if (call.method == 'saveEstimateItems') {
            stored = (call.arguments as Map)['items'] as String;
            saves++;
          }
          return null;
        });
    final store = PlatformEstimateItemStore();
    final repaired = await store.load();
    expect(saves, 1);
    expect(repaired.estimates, hasLength(2));
    expect(repaired.estimates.first.info.id, 'old-estimate');
    expect(repaired.estimates.last.info.id, isNot('old-estimate'));
    expect(repaired.activeEstimateId, 'old-estimate');
    expect(
      repaired.estimates.first.items.map((item) => item.id).toSet(),
      hasLength(2),
    );
    expect(repaired.estimates.first.items.map((item) => item.name), [
      'one',
      'two',
    ]);
    expect(repaired.unitPriceMasters, hasLength(2));
    expect(repaired.unitPriceMasters.first.id, 'same-master');
    expect(repaired.unitPriceMasters.last.id, isNot('same-master'));
    final again = await store.load();
    expect(saves, 1);
    expect(again.toJson(), repaired.toJson());

    final controller = EstimateController(
      store: store,
      accessPlan: AppAccessPlan.full,
    );
    await controller.load();
    await controller.delete(controller.items.first.id);
    expect(controller.items.single.name, 'two');
    expect((await store.load()).estimates.first.items.single.name, 'two');
    await controller.deleteUnitPriceMaster(
      controller.unitPriceMasters.first.id,
    );
    expect(controller.unitPriceMasters.single.name, 'master two');
  });

  test('見積ID修復の保存失敗は通常読込を中断し元データを維持', () async {
    final info = EstimateInfo.initial(DateTime.utc(2026, 1, 1));
    final workspace = EstimateWorkspace(
      activeEstimateId: 'same',
      estimates: [
        for (var i = 0; i < 2; i++)
          EstimateDocument(
            info: EstimateInfo.fromJson({...info.toJson(), 'id': 'same'}),
            items: const [],
          ),
      ],
    );
    final original = jsonEncode(workspace.toJson());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(estimateChannel, (call) async {
          if (call.method == 'loadEstimateItems') return original;
          throw PlatformException(code: 'WRITE_FAILED');
        });
    final controller = EstimateController(store: PlatformEstimateItemStore());
    await expectLater(controller.load(), throwsA(isA<PlatformException>()));
    expect(controller.isLoaded, isFalse);
    expect(controller.estimates, isEmpty);
    expect(jsonDecode(original)['estimates'], hasLength(2));
  });

  test('歩掛重複を保存後に返し、再読込でIDが変わらない', () async {
    final record = ProductivityRecord(
      id: 'legacy',
      createdAt: DateTime.utc(2026, 1, 1),
      trade: '土工',
      taskName: 'first',
      siteName: 'site',
      workDate: DateTime.utc(2026, 1, 1),
      quantity: 1,
      unit: 'm',
      workers: 1,
      workDays: 1,
      actualLabor: 1,
      actualLaborRate: 1,
      productivityPerLabor: 1,
    );
    var stored = jsonEncode([
      record.toJson(),
      {...record.toJson(), 'taskName': 'second'},
    ]);
    var saves = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, (call) async {
          if (call.method == 'loadProductivityRecords') return stored;
          if (call.method == 'saveProductivityRecords') {
            stored = (call.arguments as Map)['records'] as String;
            saves++;
          }
          return null;
        });
    final store = PlatformProductivityRecordStore();
    final records = await store.load();
    expect(saves, 1);
    expect(records, hasLength(2));
    expect(records.first.id, 'legacy');
    expect(records.last.id, isNot('legacy'));
    expect(records.map((r) => r.taskName), ['first', 'second']);
    expect((await store.load()).map((r) => r.id), records.map((r) => r.id));
    expect(saves, 1);
  });

  test('歩掛修復の保存失敗は読込失敗とし元レコードを保持', () async {
    final record = ProductivityRecord(
      id: 'duplicate',
      createdAt: DateTime.utc(2026, 1, 1),
      trade: '土工',
      taskName: 'first',
      siteName: 'site',
      workDate: DateTime.utc(2026, 1, 1),
      quantity: 1,
      unit: 'm',
      workers: 1,
      workDays: 1,
      actualLabor: 1,
      actualLaborRate: 1,
      productivityPerLabor: 1,
    );
    final original = jsonEncode([
      record.toJson(),
      {...record.toJson(), 'taskName': 'second'},
    ]);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recordChannel, (call) async {
          if (call.method == 'loadProductivityRecords') return original;
          throw PlatformException(code: 'WRITE_FAILED');
        });
    await expectLater(
      PlatformProductivityRecordStore().load(),
      throwsA(isA<PlatformException>()),
    );
    expect((jsonDecode(original) as List).length, 2);
  });

  test('設定内の標準車両ID衝突を保存後に返す', () async {
    final settings = AppSettings(
      customTransportVehicles: [
        const TransportVehicle(
          id: 'dump_4t',
          name: 'my truck',
          initialCapacityCubicMeters: 1,
          isCustom: true,
        ),
      ],
    );
    var stored = jsonEncode(settings.toJson());
    var saves = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(settingsChannel, (call) async {
          if (call.method == 'loadSettings') return stored;
          if (call.method == 'saveSettings') {
            stored = (call.arguments as Map)['settings'] as String;
            saves++;
          }
          return null;
        });
    final store = PlatformAppSettingsStore();
    final loaded = await store.load();
    expect(loaded.customTransportVehicles, hasLength(1));
    expect(
      loaded.customTransportVehicles.single.id,
      isNot(InitialTransportVehicles.defaultVehicleId),
    );
    expect(loaded.customTransportVehicles.single.name, 'my truck');
    expect(saves, 1);
    expect(
      (await store.load()).customTransportVehicles.single.id,
      loaded.customTransportVehicles.single.id,
    );
    expect(saves, 1);
  });
}
