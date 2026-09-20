import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/data/google_mobile_ads_rewarded_ad_presenter.dart';
import 'package:instant_estimate/features/advertising/presentation/google_mobile_ads_banner.dart';

void main() {
  const formalApplicationId = 'com.matsumotoboundary.constructioncalc';
  const googleAndroidTestAppId = 'ca-app-pub-3940256099942544~3347511713';

  test('Android advertising configuration uses the formal application ID', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/'
      'com/matsumotoboundary/constructioncalc/MainActivity.kt',
    ).readAsStringSync();

    expect(gradle, contains('namespace = "$formalApplicationId"'));
    expect(gradle, contains('applicationId = "$formalApplicationId"'));
    expect(activity, contains('package $formalApplicationId'));
    expect(gradle, isNot(contains('com.example.instant_estimate')));
  });

  test('Android manifest keeps the Google test AdMob application ID', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('android:name="com.google.android.gms.ads.APPLICATION_ID"'),
    );
    expect(manifest, contains('android:value="$googleAndroidTestAppId"'));
    expect(manifest, isNot(contains('ca-app-pub-5377462997619054')));
  });

  test('Android uses Google test ad units even in release builds', () {
    for (final useProductionIds in [false, true]) {
      expect(
        GoogleMobileAdsBannerIds.forPlatform(
          TargetPlatform.android,
          useProductionIds: useProductionIds,
        ),
        GoogleMobileAdsBannerIds.androidTest,
      );
      expect(
        RewardedAdIds.forPlatform(
          TargetPlatform.android,
          useProductionIds: useProductionIds,
        ),
        RewardedAdIds.androidTest,
      );
    }
  });
}
