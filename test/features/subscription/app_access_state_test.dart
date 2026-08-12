import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/subscription/domain/app_access_state.dart';

void main() {
  test('契約状態を保存用データへ変換して復元できる', () {
    final trialEndsAt = DateTime.utc(2026, 8, 16, 12);
    final verifiedAt = DateTime.utc(2026, 8, 9, 12);
    final original = AppAccessState(
      plan: AppAccessPlan.full,
      trialEndsAt: trialEndsAt,
      lastVerifiedAt: verifiedAt,
      rewardedAccessDay: '2026-08-09',
      rewardedAccessGroups: const ['convenientCalculations', 'output'],
    );

    final restored = AppAccessState.fromJson(original.toJson());

    expect(restored.plan, AppAccessPlan.full);
    expect(restored.trialEndsAt, trialEndsAt);
    expect(restored.lastVerifiedAt, verifiedAt);
    expect(restored.rewardedAccessDay, '2026-08-09');
    expect(restored.rewardedAccessGroups, const [
      'convenientCalculations',
      'output',
    ]);
  });

  test('7日間体験の期間中だけ完全版を有効にする', () {
    final state = AppAccessState(
      plan: AppAccessPlan.full,
      trialEndsAt: DateTime.utc(2026, 8, 16),
    );

    expect(
      state.effectivePlan(now: DateTime.utc(2026, 8, 15)),
      AppAccessPlan.full,
    );
    expect(state.isTrialActive(now: DateTime.utc(2026, 8, 15)), isTrue);
    expect(
      state.effectivePlan(now: DateTime.utc(2026, 8, 16)),
      AppAccessPlan.free,
    );
    expect(state.isTrialActive(now: DateTime.utc(2026, 8, 16)), isFalse);
  });

  test('不明な保存プランは無料版へ安全に戻す', () {
    final state = AppAccessState.fromJson(const {'plan': 'unknown'});

    expect(state.plan, AppAccessPlan.free);
    expect(state.effectivePlan(), AppAccessPlan.free);
  });

  test('再検証によりfullからfreeへダウングレードできる', () {
    const state = AppAccessState(plan: AppAccessPlan.full);
    final verifiedAt = DateTime.utc(2026, 8, 12);

    final reconciled = state.reconcileVerifiedPlan(
      AppAccessPlan.free,
      verifiedAt: verifiedAt,
    );

    expect(reconciled.plan, AppAccessPlan.free);
    expect(reconciled.lastVerifiedAt, verifiedAt);
  });

  test('再検証によりfullから所有済みadFreeへダウングレードできる', () {
    const state = AppAccessState(plan: AppAccessPlan.full);

    final reconciled = state.reconcileVerifiedPlan(
      AppAccessPlan.adFree,
      verifiedAt: DateTime.utc(2026, 8, 12),
    );

    expect(reconciled.plan, AppAccessPlan.adFree);
  });

  test('再検証時は期限切れ体験期間を消去する', () {
    final state = AppAccessState(
      plan: AppAccessPlan.full,
      trialEndsAt: DateTime.utc(2026, 8, 1),
    );

    final reconciled = state.reconcileVerifiedPlan(
      AppAccessPlan.free,
      verifiedAt: DateTime.utc(2026, 8, 12),
    );

    expect(reconciled.trialEndsAt, isNull);
  });

  test('壊れた広告保存値は空の状態へ安全に戻す', () {
    final state = AppAccessState.fromJson(const {
      'plan': 'free',
      'rewardedAccessDay': 20260809,
      'rewardedAccessGroups': 'output',
    });

    expect(state.rewardedAccessDay, isNull);
    expect(state.rewardedAccessGroups, isEmpty);
  });
}
