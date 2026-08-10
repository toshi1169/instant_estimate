import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/data/google_mobile_ads_rewarded_ad_presenter.dart';

void main() {
  group('RewardedAdTestIds', () {
    test('iOSとAndroidでは公式テスト広告IDを返す', () {
      expect(
        RewardedAdTestIds.forPlatform(TargetPlatform.iOS),
        'ca-app-pub-3940256099942544/1712485313',
      );
      expect(
        RewardedAdTestIds.forPlatform(TargetPlatform.android),
        'ca-app-pub-3940256099942544/5224354917',
      );
    });

    test('広告非対応の端末ではIDを返さない', () {
      expect(RewardedAdTestIds.forPlatform(TargetPlatform.macOS), isNull);
      expect(RewardedAdTestIds.forPlatform(TargetPlatform.windows), isNull);
      expect(RewardedAdTestIds.forPlatform(TargetPlatform.linux), isNull);
      expect(RewardedAdTestIds.forPlatform(TargetPlatform.fuchsia), isNull);
    });
  });
}
