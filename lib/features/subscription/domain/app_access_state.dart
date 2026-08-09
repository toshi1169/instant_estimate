import '../../../core/domain/app_access_plan.dart';

class AppAccessState {
  const AppAccessState({
    this.plan = AppAccessPlan.free,
    this.trialEndsAt,
    this.lastVerifiedAt,
  });

  factory AppAccessState.fromJson(Map<String, Object?> json) {
    return AppAccessState(
      plan: appAccessPlanFromStorageName(json['plan'] as String?),
      trialEndsAt: _parseDate(json['trialEndsAt']),
      lastVerifiedAt: _parseDate(json['lastVerifiedAt']),
    );
  }

  final AppAccessPlan plan;
  final DateTime? trialEndsAt;
  final DateTime? lastVerifiedAt;

  AppAccessPlan effectivePlan({DateTime? now}) {
    if (plan != AppAccessPlan.full || trialEndsAt == null) return plan;
    return (now ?? DateTime.now()).isBefore(trialEndsAt!)
        ? AppAccessPlan.full
        : AppAccessPlan.free;
  }

  bool isTrialActive({DateTime? now}) {
    return plan == AppAccessPlan.full &&
        trialEndsAt != null &&
        (now ?? DateTime.now()).isBefore(trialEndsAt!);
  }

  Map<String, Object?> toJson() => {
    'plan': plan.name,
    'trialEndsAt': trialEndsAt?.toIso8601String(),
    'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
  };
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
