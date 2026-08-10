import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/advertising/application/rewarded_ad_access_controller.dart';
import 'package:instant_estimate/features/advertising/domain/rewarded_ad_policy.dart';
import 'package:instant_estimate/features/subscription/data/app_access_state_store.dart';
import 'package:instant_estimate/features/subscription/domain/app_access_state.dart';

void main() {
  group('RewardedAdAccessController', () {
    test('同じグループは同日1回だけ広告を要求する', () async {
      final presenter = _FakePresenter();
      final store = _MemoryStore();
      final controller = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        store: store,
        now: () => DateTime(2026, 8, 10, 9),
      );

      expect(
        await controller.requestAccess(
          RewardedAdEntryPoint.convenientCalculation,
        ),
        isTrue,
      );
      expect(
        await controller.requestAccess(
          RewardedAdEntryPoint.convenientCalculation,
        ),
        isTrue,
      );

      expect(presenter.calls, [RewardedAdEntryPoint.convenientCalculation]);
      expect(store.saved, hasLength(1));
    });

    test('見積と単価マスタは同じグループで判定する', () async {
      final presenter = _FakePresenter();
      final controller = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        now: () => DateTime(2026, 8, 10),
      );

      await controller.requestAccess(RewardedAdEntryPoint.instantEstimate);
      await controller.requestAccess(RewardedAdEntryPoint.unitPriceMaster);

      expect(presenter.calls, [RewardedAdEntryPoint.instantEstimate]);
    });

    test('PDF・Excel・印刷は同じ出力グループで判定する', () async {
      final presenter = _FakePresenter();
      final controller = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        now: () => DateTime(2026, 8, 10),
      );

      await controller.requestAccess(RewardedAdEntryPoint.pdfExport);
      await controller.requestAccess(RewardedAdEntryPoint.excelExport);
      await controller.requestAccess(RewardedAdEntryPoint.printOutput);

      expect(presenter.calls, [RewardedAdEntryPoint.pdfExport]);
    });

    test('3グループはそれぞれ1回ずつ要求できる', () async {
      final presenter = _FakePresenter();
      final controller = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        now: () => DateTime(2026, 8, 10),
      );

      await controller.requestAccess(
        RewardedAdEntryPoint.convenientCalculation,
      );
      await controller.requestAccess(RewardedAdEntryPoint.instantEstimate);
      await controller.requestAccess(RewardedAdEntryPoint.excelExport);

      expect(presenter.calls, hasLength(maximumDailyRewardedAds));
    });

    test('日付が変わると同じグループを再度要求する', () async {
      var now = DateTime(2026, 8, 10, 23, 59);
      final presenter = _FakePresenter();
      final controller = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        now: () => now,
      );

      await controller.requestAccess(
        RewardedAdEntryPoint.convenientCalculation,
      );
      now = DateTime(2026, 8, 11);
      await controller.requestAccess(
        RewardedAdEntryPoint.convenientCalculation,
      );

      expect(presenter.calls, hasLength(2));
    });

    test('広告なし版と完全版は広告判定を通さない', () async {
      for (final plan in [AppAccessPlan.adFree, AppAccessPlan.full]) {
        final presenter = _FakePresenter();
        final controller = RewardedAdAccessController(
          initialState: AppAccessState(plan: plan),
          presenter: presenter,
          now: () => DateTime(2026, 8, 10),
        );

        expect(
          await controller.requestAccess(
            RewardedAdEntryPoint.convenientCalculation,
          ),
          isTrue,
        );
        expect(presenter.calls, isEmpty);
      }
    });

    test('広告取得失敗と表示失敗でも当日は利用できる', () async {
      for (final result in [
        RewardedAdResult.unavailable,
        RewardedAdResult.failed,
      ]) {
        final presenter = _FakePresenter(results: [result]);
        final store = _MemoryStore();
        final controller = RewardedAdAccessController(
          initialState: const AppAccessState(),
          presenter: presenter,
          store: store,
          now: () => DateTime(2026, 8, 10),
        );

        expect(
          await controller.requestAccess(RewardedAdEntryPoint.instantEstimate),
          isTrue,
        );
        expect(store.saved.single.rewardedAccessGroups, [
          RewardedAdGroup.estimateAndUnitPriceMaster.name,
        ]);
      }
    });

    test('広告を閉じた場合は利用を開始せず視聴済みにもしない', () async {
      final presenter = _FakePresenter(
        results: [RewardedAdResult.dismissed, RewardedAdResult.completed],
      );
      final store = _MemoryStore();
      final controller = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        store: store,
        now: () => DateTime(2026, 8, 10),
      );

      expect(
        await controller.requestAccess(RewardedAdEntryPoint.excelExport),
        isFalse,
      );
      expect(store.saved, isEmpty);
      expect(
        await controller.requestAccess(RewardedAdEntryPoint.excelExport),
        isTrue,
      );
      expect(presenter.calls, hasLength(2));
    });

    test('プレゼンターが例外になっても利用を妨げない', () async {
      final presenter = _FakePresenter(throwsError: true);
      final controller = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        now: () => DateTime(2026, 8, 10),
      );

      expect(
        await controller.requestAccess(RewardedAdEntryPoint.printOutput),
        isTrue,
      );
    });
  });
}

class _FakePresenter implements RewardedAdPresenter {
  _FakePresenter({List<RewardedAdResult>? results, this.throwsError = false})
    : _results = [...?results];

  final List<RewardedAdResult> _results;
  final bool throwsError;
  final List<RewardedAdEntryPoint> calls = [];

  @override
  Future<RewardedAdResult> show(RewardedAdEntryPoint entryPoint) async {
    calls.add(entryPoint);
    if (throwsError) throw StateError('ad error');
    if (_results.isEmpty) return RewardedAdResult.completed;
    return _results.removeAt(0);
  }
}

class _MemoryStore implements AppAccessStateStore {
  AppAccessState state = const AppAccessState();
  final List<AppAccessState> saved = [];

  @override
  Future<AppAccessState> load() async => state;

  @override
  Future<void> save(AppAccessState state) async {
    this.state = state;
    saved.add(state);
  }
}
