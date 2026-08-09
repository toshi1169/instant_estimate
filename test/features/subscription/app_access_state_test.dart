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
    );

    final restored = AppAccessState.fromJson(original.toJson());

    expect(restored.plan, AppAccessPlan.full);
    expect(restored.trialEndsAt, trialEndsAt);
    expect(restored.lastVerifiedAt, verifiedAt);
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
}
