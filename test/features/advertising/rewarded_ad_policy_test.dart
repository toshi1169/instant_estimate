import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/domain/rewarded_ad_policy.dart';

void main() {
  test('動画広告の入口を3つの独立したグループへ分ける', () {
    expect(
      RewardedAdEntryPoint.convenientCalculation.group,
      RewardedAdGroup.convenientCalculations,
    );
    expect(
      RewardedAdEntryPoint.instantEstimate.group,
      RewardedAdGroup.estimateAndUnitPriceMaster,
    );
    expect(
      RewardedAdEntryPoint.unitPriceMaster.group,
      RewardedAdGroup.estimateAndUnitPriceMaster,
    );
    expect(RewardedAdEntryPoint.pdfExport.group, RewardedAdGroup.output);
    expect(RewardedAdEntryPoint.excelExport.group, RewardedAdGroup.output);
    expect(RewardedAdEntryPoint.printOutput.group, RewardedAdGroup.output);
    expect(maximumDailyRewardedAds, 3);
  });
}
