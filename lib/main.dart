import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/calculator/data/calculation_history_store.dart';
import 'features/onboarding/data/onboarding_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    InstantEstimateApp(
      onboardingPreferences: PlatformOnboardingPreferences(),
      calculationHistoryStore: PlatformCalculationHistoryStore(),
    ),
  );
}
