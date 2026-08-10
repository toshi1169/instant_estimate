import '../../../core/domain/app_access_plan.dart';

class AppAccessState {
  const AppAccessState({
    this.plan = AppAccessPlan.free,
    this.trialEndsAt,
    this.lastVerifiedAt,
    this.rewardedAccessDay,
    this.rewardedAccessGroups = const [],
  });

  factory AppAccessState.fromJson(Map<String, Object?> json) {
    return AppAccessState(
      plan: appAccessPlanFromStorageName(json['plan'] as String?),
      trialEndsAt: _parseDate(json['trialEndsAt']),
      lastVerifiedAt: _parseDate(json['lastVerifiedAt']),
      rewardedAccessDay: _parseString(json['rewardedAccessDay']),
      rewardedAccessGroups: _parseStringList(json['rewardedAccessGroups']),
    );
  }

  final AppAccessPlan plan;
  final DateTime? trialEndsAt;
  final DateTime? lastVerifiedAt;
  final String? rewardedAccessDay;
  final List<String> rewardedAccessGroups;

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

  AppAccessState copyWith({
    AppAccessPlan? plan,
    DateTime? trialEndsAt,
    DateTime? lastVerifiedAt,
    String? rewardedAccessDay,
    List<String>? rewardedAccessGroups,
  }) {
    return AppAccessState(
      plan: plan ?? this.plan,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      rewardedAccessDay: rewardedAccessDay ?? this.rewardedAccessDay,
      rewardedAccessGroups: rewardedAccessGroups ?? this.rewardedAccessGroups,
    );
  }

  Map<String, Object?> toJson() => {
    'plan': plan.name,
    'trialEndsAt': trialEndsAt?.toIso8601String(),
    'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
    'rewardedAccessDay': rewardedAccessDay,
    'rewardedAccessGroups': rewardedAccessGroups,
  };
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String? _parseString(Object? value) {
  return value is String && value.isNotEmpty ? value : null;
}

List<String> _parseStringList(Object? value) {
  if (value is! List) return const [];
  return List.unmodifiable(value.whereType<String>());
}
