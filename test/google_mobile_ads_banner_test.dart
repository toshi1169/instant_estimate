import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/presentation/google_mobile_ads_banner.dart';

void main() {
  test('Google公式のOS別テストバナーIDを選択する', () {
    expect(
      GoogleMobileAdsBannerIds.forPlatform(TargetPlatform.iOS),
      GoogleMobileAdsBannerIds.iosTest,
    );
    expect(
      GoogleMobileAdsBannerIds.forPlatform(TargetPlatform.android),
      GoogleMobileAdsBannerIds.androidTest,
    );
  });

  test('未対応OSではバナー広告を読み込まない', () {
    expect(GoogleMobileAdsBannerIds.forPlatform(TargetPlatform.macOS), isNull);
  });

  test('iOS Releaseでは本番バナー広告IDを使用する', () {
    expect(
      GoogleMobileAdsBannerIds.forPlatform(
        TargetPlatform.iOS,
        useProductionIds: true,
      ),
      'ca-app-pub-5377462997619054/6124543262',
    );
    expect(
      GoogleMobileAdsBannerIds.forPlatform(
        TargetPlatform.iOS,
        useProductionIds: false,
      ),
      GoogleMobileAdsBannerIds.iosTest,
    );
  });
}
