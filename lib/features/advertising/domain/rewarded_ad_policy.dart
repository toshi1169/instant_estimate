enum RewardedAdEntryPoint {
  convenientCalculation,
  instantEstimate,
  unitPriceMaster,
  pdfExport,
  excelExport,
  printOutput,
}

enum RewardedAdGroup {
  convenientCalculations,
  estimateAndUnitPriceMaster,
  output,
}

extension RewardedAdEntryPointPolicy on RewardedAdEntryPoint {
  RewardedAdGroup get group => switch (this) {
    RewardedAdEntryPoint.convenientCalculation =>
      RewardedAdGroup.convenientCalculations,
    RewardedAdEntryPoint.instantEstimate ||
    RewardedAdEntryPoint.unitPriceMaster =>
      RewardedAdGroup.estimateAndUnitPriceMaster,
    RewardedAdEntryPoint.pdfExport ||
    RewardedAdEntryPoint.excelExport ||
    RewardedAdEntryPoint.printOutput => RewardedAdGroup.output,
  };
}

/// 各グループは1日1回までなので、無料版の動画広告は最大3回/日となる。
const int maximumDailyRewardedAds = 3;
