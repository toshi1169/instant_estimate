import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/calculator/presentation/calculator_screen.dart';
import '../features/calculator/data/calculation_history_store.dart';
import '../features/onboarding/data/onboarding_preferences.dart';
import '../features/onboarding/presentation/occupation_selection_screen.dart';

class InstantEstimateApp extends StatelessWidget {
  const InstantEstimateApp({
    required this.onboardingPreferences,
    this.calculationHistoryStore,
    super.key,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'インスタント見積',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: _StartupGate(
        onboardingPreferences: onboardingPreferences,
        calculationHistoryStore: calculationHistoryStore,
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({
    required this.onboardingPreferences,
    required this.calculationHistoryStore,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<bool> _hasSelectedOccupation = widget.onboardingPreferences
      .hasSelectedOccupation();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSelectedOccupation,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(color: Colors.transparent);
        }

        if (snapshot.data!) {
          return CalculatorScreen(historyStore: widget.calculationHistoryStore);
        }

        return OccupationSelectionScreen(
          onCompleted: (occupation) async {
            await widget.onboardingPreferences.saveOccupation(occupation);
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => CalculatorScreen(
                  historyStore: widget.calculationHistoryStore,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
