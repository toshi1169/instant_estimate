import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/presentation/google_mobile_ads_banner.dart';

void main() {
  test('Google公式のOS別テストバナーIDを選択する', () {
    expect(
      GoogleMobileAdsBannerTestIds.forPlatform(TargetPlatform.iOS),
      GoogleMobileAdsBannerTestIds.ios,
    );
    expect(
      GoogleMobileAdsBannerTestIds.forPlatform(TargetPlatform.android),
      GoogleMobileAdsBannerTestIds.android,
    );
  });

  test('未対応OSではバナー広告を読み込まない', () {
    expect(
      GoogleMobileAdsBannerTestIds.forPlatform(TargetPlatform.macOS),
      isNull,
    );
  });
}
