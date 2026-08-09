import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/productivity/application/productivity_controller.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_calculator.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_record.dart';

void main() {
  test('必要人工・必要日数・延べ作業時間を計算する', () {
    final result = ProductivityCalculator.plan(
      quantity: 120,
      standardLaborRate: 0.05,
      workers: 3,
      hoursPerDay: 8,
    );
    expect(result.requiredLabor, 6);
    expect(result.requiredDays, 2);
    expect(result.totalWorkHours, 16);
  });

  test('施工実績から実績歩掛・生産性・効率差を計算する', () {
    final result = ProductivityCalculator.actual(
      quantity: 120,
      workers: 3,
      workDays: 2,
      standardLaborRate: 0.06,
    );
    expect(result.actualLabor, 6);
    expect(result.actualLaborRate, 0.05);
    expect(result.productivityPerLabor, 20);
    expect(result.laborRateDifference, closeTo(-0.01, 0.000001));
    expect(result.efficiencyDifferencePercent, closeTo(20, 0.000001));
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
