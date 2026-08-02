import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/calculator/data/calculation_history_store.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'features/settings/data/app_settings_store.dart';
import 'features/estimate/data/estimate_item_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    InstantEstimateApp(
      onboardingPreferences: PlatformOnboardingPreferences(),
      calculationHistoryStore: PlatformCalculationHistoryStore(),
      appSettingsStore: PlatformAppSettingsStore(),
      estimateItemStore: PlatformEstimateItemStore(),
    ),
  );
}
