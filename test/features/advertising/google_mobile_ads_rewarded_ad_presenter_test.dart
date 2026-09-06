import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/data/google_mobile_ads_rewarded_ad_presenter.dart';

void main() {
  group('RewardedAdIds', () {
    test('iOSとAndroidでは公式テスト広告IDを返す', () {
      expect(
        RewardedAdIds.forPlatform(TargetPlatform.iOS),
        'ca-app-pub-3940256099942544/1712485313',
      );
      expect(
        RewardedAdIds.forPlatform(TargetPlatform.android),
        'ca-app-pub-3940256099942544/5224354917',
      );
    });

    test('広告非対応の端末ではIDを返さない', () {
      expect(RewardedAdIds.forPlatform(TargetPlatform.macOS), isNull);
      expect(RewardedAdIds.forPlatform(TargetPlatform.windows), isNull);
      expect(RewardedAdIds.forPlatform(TargetPlatform.linux), isNull);
      expect(RewardedAdIds.forPlatform(TargetPlatform.fuchsia), isNull);
    });

    test('iOS Releaseでは3グループ共通の本番Rewarded広告IDを使用する', () {
      expect(
        RewardedAdIds.forPlatform(TargetPlatform.iOS, useProductionIds: true),
        'ca-app-pub-5377462997619054/4787410869',
      );
      expect(
        RewardedAdIds.forPlatform(TargetPlatform.iOS, useProductionIds: false),
        RewardedAdIds.iosTest,
      );
    });
  });
}
