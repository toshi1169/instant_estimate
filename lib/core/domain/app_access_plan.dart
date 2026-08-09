enum AppAccessPlan { free, adFree, full }

extension AppAccessPlanDetails on AppAccessPlan {
  String get displayName => switch (this) {
    AppAccessPlan.free => '無料版',
    AppAccessPlan.adFree => '広告なし版',
    AppAccessPlan.full => '完全版',
  };

  String get priceLabel => switch (this) {
    AppAccessPlan.free => '無料',
    AppAccessPlan.adFree => '¥300（買い切り）',
    AppAccessPlan.full => '¥500／月',
  };

  bool get showsAds => this == AppAccessPlan.free;
  bool get hasSevenDayTrial => this == AppAccessPlan.full;

  int? get estimateLimit => this == AppAccessPlan.full ? null : 5;
  int? get unitPriceMasterLimit => this == AppAccessPlan.full ? null : 10;
  int get productivityRecordLimit => this == AppAccessPlan.full ? 100 : 5;
}
