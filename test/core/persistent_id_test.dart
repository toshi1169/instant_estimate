import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/persistent_id.dart';
import 'package:instant_estimate/core/domain/persistent_id_repair.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';

void main() {
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('1000件以上を高速生成してもUUID v4は重複しない', () {
    final ids = {for (var i = 0; i < 2000; i++) PersistentId.create()};
    expect(ids, hasLength(2000));
    expect(ids.every(uuidV4.hasMatch), isTrue);
  });

  test('同一時刻・時計逆行はIDへ影響しない', () {
    final times = [
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2020, 1, 1),
    ];
    final ids = times.map((time) => EstimateInfo.initial(time).id).toSet();
    expect(ids, hasLength(3));
    expect(ids.every(uuidV4.hasMatch), isTrue);
  });

  test('既存IDとの衝突を避ける', () {
    final ids = <String>{};
    for (var i = 0; i < 1000; i++) {
      final id = PersistentId.create(excluding: ids);
      expect(ids.add(id), isTrue);
    }
  });

  test('旧数値IDとUUIDが混在しても正常IDを変えず、欠損・重複だけ修復', () {
    final workspace = <String, dynamic>{
      'activeEstimateId': '123456',
      'estimates': [
        {
          'info': {'id': '123456', 'estimateName': 'first'},
          'items': [
            {'id': 'old-item', 'name': 'A'},
            {'id': 'old-item', 'name': 'B'},
          ],
        },
        {
          'info': {'id': '123456', 'estimateName': 'second'},
          'items': [
            {'id': '', 'name': 'C'},
          ],
        },
      ],
      'unitPriceMasters': [
        {'id': '987654', 'name': 'first'},
        {'id': '987654', 'name': 'second'},
        {'name': 'third'},
      ],
    };
    expect(PersistentIdRepair.workspace(workspace), isTrue);
    final estimates = workspace['estimates'] as List;
    final first = estimates[0] as Map;
    final second = estimates[1] as Map;
    expect((first['info'] as Map)['id'], '123456');
    expect(uuidV4.hasMatch((second['info'] as Map)['id'] as String), isTrue);
    expect(workspace['activeEstimateId'], '123456');
    final items = [...(first['items'] as List), ...(second['items'] as List)];
    expect((items[0] as Map)['id'], 'old-item');
    expect(items.map((item) => (item as Map)['id']).toSet(), hasLength(3));
    expect(items.map((item) => (item as Map)['name']), ['A', 'B', 'C']);
    final masters = workspace['unitPriceMasters'] as List;
    expect((masters[0] as Map)['id'], '987654');
    expect(masters.map((item) => (item as Map)['id']).toSet(), hasLength(3));
    expect(PersistentIdRepair.workspace(workspace), isFalse);
  });

  test('歩掛と標準車両IDを含むカスタム車両の重複を非破壊修復', () {
    final records = <dynamic>[
      {'id': 'old', 'taskName': 'A'},
      {'id': 'old', 'taskName': 'B'},
    ];
    expect(PersistentIdRepair.productivity(records), isTrue);
    expect((records[0] as Map)['id'], 'old');
    expect((records[1] as Map)['id'], isNot('old'));
    expect(records.map((record) => (record as Map)['taskName']), ['A', 'B']);

    final settings = <String, dynamic>{
      'customTransportVehicles': [
        {'id': InitialTransportVehicles.defaultVehicleId, 'name': 'custom A'},
        {'id': 'custom-old', 'name': 'custom B'},
        {'id': 'custom-old', 'name': 'custom C'},
      ],
    };
    expect(PersistentIdRepair.settings(settings), isTrue);
    final vehicles = settings['customTransportVehicles'] as List;
    expect(
      (vehicles[0] as Map)['id'],
      isNot(InitialTransportVehicles.defaultVehicleId),
    );
    expect((vehicles[1] as Map)['id'], 'custom-old');
    expect(
      vehicles.map((vehicle) => (vehicle as Map)['id']).toSet(),
      hasLength(3),
    );
    expect(vehicles.map((vehicle) => (vehicle as Map)['name']), [
      'custom A',
      'custom B',
      'custom C',
    ]);
  });
}
