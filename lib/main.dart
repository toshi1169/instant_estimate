import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/domain/app_access_plan.dart';
import 'core/platform/app_orientation.dart';
import 'core/licenses/third_party_licenses.dart';
import 'features/advertising/data/google_mobile_ads_consent_manager.dart';
import 'features/advertising/data/google_mobile_ads_rewarded_ad_presenter.dart';
import 'features/calculator/data/calculation_history_store.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'features/settings/data/app_settings_store.dart';
import 'features/estimate/data/estimate_item_store.dart';
import 'features/productivity/data/productivity_record_store.dart';
import 'features/subscription/data/app_access_state_store.dart';
import 'features/subscription/data/in_app_purchase_store.dart';
import 'features/backup/application/backup_restore_coordinator.dart';
import 'features/backup/application/backup_snapshot_factory.dart';
import 'features/backup/data/backup_restore_journal_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerThirdPartyLicenses();
  await configureAppOrientation();
  const profileScreenshotFullAccess = kProfileMode;
  final onboardingPreferences = PlatformOnboardingPreferences();
  final calculationHistoryStore = PlatformCalculationHistoryStore();
  final appSettingsStore = PlatformAppSettingsStore();
  final estimateItemStore = PlatformEstimateItemStore();
  final productivityRecordStore = PlatformProductivityRecordStore();
  final snapshotFactory = BackupSnapshotFactory(
    historyStore: calculationHistoryStore,
    estimateStore: estimateItemStore,
    productivityStore: productivityRecordStore,
    onboardingPreferences: onboardingPreferences,
  );
  final restoreCoordinator = BackupRestoreCoordinator(
    snapshotFactory: snapshotFactory,
    settingsStore: appSettingsStore,
    historyStore: calculationHistoryStore,
    estimateStore: estimateItemStore,
    productivityStore: productivityRecordStore,
    onboardingPreferences: onboardingPreferences,
    journalStore: PlatformBackupRestoreJournalStore(),
  );
  runApp(
    InstantEstimateApp(
      onboardingPreferences: onboardingPreferences,
      calculationHistoryStore: calculationHistoryStore,
      appSettingsStore: appSettingsStore,
      estimateItemStore: estimateItemStore,
      productivityRecordStore: productivityRecordStore,
      backupRestoreCoordinator: restoreCoordinator,
      accessStateStore: profileScreenshotFullAccess
          ? null
          : PlatformAppAccessStateStore(),
      rewardedAdPresenter: profileScreenshotFullAccess
          ? null
          : const GoogleMobileAdsRewardedAdPresenter(),
      advertisingConsentManager: profileScreenshotFullAccess
          ? null
          : GoogleMobileAdsConsentManager(),
      enableGoogleMobileAds: !profileScreenshotFullAccess,
      purchaseStore: profileScreenshotFullAccess ? null : InAppPurchaseStore(),
      accessPlan: profileScreenshotFullAccess
          ? AppAccessPlan.full
          : AppAccessPlan.free,
    ),
  );
}
