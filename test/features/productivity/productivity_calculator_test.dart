import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/productivity/application/productivity_controller.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_calculator.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_record.dart';

void main() {
  test('施工量400・1人1日100で必要人工は4', () {
    final result = ProductivityCalculator.plan(
      quantity: 400,
      dailyProductivity: 100,
    );
    expect(result.requiredLabor, 4);
    expect(result.requiredDays, isNull);
    expect(result.teamDailyProductivity, isNull);
  });

  test('作業人数1人なら必要日数は4日', () {
    final result = ProductivityCalculator.plan(
      quantity: 400,
      dailyProductivity: 100,
      workers: 1,
    );
    expect(result.requiredLabor, 4);
    expect(result.requiredDays, 4);
    expect(result.teamDailyProductivity, 100);
  });

  test('作業人数2人なら必要日数2日・チーム施工量200', () {
    final result = ProductivityCalculator.plan(
      quantity: 400,
      dailyProductivity: 100,
      workers: 2,
    );
    expect(result.requiredLabor, 4);
    expect(result.requiredDays, 2);
    expect(result.teamDailyProductivity, 200);
  });

  test('施工量550・2人なら必要日数は2.75日', () {
    final result = ProductivityCalculator.plan(
      quantity: 550,
      dailyProductivity: 100,
      workers: 2,
    );
    expect(result.requiredDays, 2.75);
  });

  test('施工実績から人工・生産性・歩掛・人時生産性を計算する', () {
    final result = ProductivityCalculator.actual(
      quantity: 400,
      workers: 2,
      workDays: 2,
      hoursPerDay: 8,
    );
    expect(result.actualLabor, 4);
    expect(result.actualProductivity, 100);
    expect(result.actualLaborRate, 0.01);
    expect(result.totalPersonHours, 32);
    expect(result.hourlyProductivity, 12.5);
  });

  test('基準生産性100・実績120なら生産性差はプラス20パーセント', () {
    final result = ProductivityCalculator.actual(
      quantity: 480,
      workers: 2,
      workDays: 2,
      baselineProductivity: 100,
    );
    expect(result.actualProductivity, 120);
    expect(result.productivityDifferencePercent, closeTo(20, 0.000001));
  });

  test('同一作業の複数実績を個別保持して集計する', () async {
    final controller = ProductivityController(
      store: MemoryProductivityRecordStore(),
    );
    await controller.load();
    await controller.add(_record('1', 0.05, 20, standard: 0.06));
    await controller.add(_record('2', 0.057, 17.54));
    await controller.add(_record('3', 0.046, 21.74));
    await controller.add(_record('4', 0.052, 19.23));

    expect(controller.records, hasLength(4));
    expect(controller.summaries, hasLength(1));
    final summary = controller.summaries.single;
    expect(summary.recordCount, 4);
    expect(summary.standardLaborRate, 0.06);
    expect(summary.standardProductivity, closeTo(16.6666667, 0.000001));
    expect(summary.averageActualLaborRate, closeTo(0.05125, 0.000001));
    expect(summary.minimumLaborRate, 0.046);
    expect(summary.maximumLaborRate, 0.057);
  });

  test('無料版は5件、完全版は100件を上限とする', () async {
    final free = ProductivityController(store: MemoryProductivityRecordStore());
    await free.load();
    for (var index = 0; index < 5; index++) {
      await free.add(_record('$index', 0.05, 20));
    }
    expect(free.canAdd, isFalse);
    expect(
      () => free.add(_record('6', 0.05, 20)),
      throwsA(isA<ProductivityLimitException>()),
    );

    final full = ProductivityController(
      store: MemoryProductivityRecordStore(),
      accessPlan: AppAccessPlan.full,
    );
    expect(full.recordLimit, 100);
  });
}

ProductivityRecord _record(
  String id,
  double rate,
  double productivity, {
  double? standard,
}) => ProductivityRecord(
  id: id,
  createdAt: DateTime(2026, 8, int.parse(id) + 1),
  trade: '型枠工事',
  taskName: '基礎立上り型枠',
  siteName: '$id現場',
  workDate: DateTime(2026, 8, 1),
  quantity: 120,
  unit: 'm²',
  workers: 3,
  workDays: 2,
  actualLabor: 6,
  standardLaborRate: standard,
  actualLaborRate: rate,
  productivityPerLabor: productivity,
);
