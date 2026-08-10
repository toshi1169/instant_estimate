import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'features/advertising/data/google_mobile_ads_rewarded_ad_presenter.dart';
import 'features/calculator/data/calculation_history_store.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'features/settings/data/app_settings_store.dart';
import 'features/estimate/data/estimate_item_store.dart';
import 'features/productivity/data/productivity_record_store.dart';
import 'features/subscription/data/app_access_state_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android)) {
    unawaited(MobileAds.instance.initialize());
  }
  runApp(
    InstantEstimateApp(
      onboardingPreferences: PlatformOnboardingPreferences(),
      calculationHistoryStore: PlatformCalculationHistoryStore(),
      appSettingsStore: PlatformAppSettingsStore(),
      estimateItemStore: PlatformEstimateItemStore(),
      productivityRecordStore: PlatformProductivityRecordStore(),
      accessStateStore: PlatformAppAccessStateStore(),
      rewardedAdPresenter: const GoogleMobileAdsRewardedAdPresenter(),
    ),
  );
}
