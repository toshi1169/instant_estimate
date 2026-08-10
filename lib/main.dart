import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/advertising/data/google_mobile_ads_consent_manager.dart';
import 'features/advertising/data/google_mobile_ads_rewarded_ad_presenter.dart';
import 'features/calculator/data/calculation_history_store.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'features/settings/data/app_settings_store.dart';
import 'features/estimate/data/estimate_item_store.dart';
import 'features/productivity/data/productivity_record_store.dart';
import 'features/subscription/data/app_access_state_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    InstantEstimateApp(
      onboardingPreferences: PlatformOnboardingPreferences(),
      calculationHistoryStore: PlatformCalculationHistoryStore(),
      appSettingsStore: PlatformAppSettingsStore(),
      estimateItemStore: PlatformEstimateItemStore(),
      productivityRecordStore: PlatformProductivityRecordStore(),
      accessStateStore: PlatformAppAccessStateStore(),
      rewardedAdPresenter: const GoogleMobileAdsRewardedAdPresenter(),
      advertisingConsentManager: GoogleMobileAdsConsentManager(),
      enableGoogleMobileAds: true,
    ),
  );
}
