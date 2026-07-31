import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/calculator/presentation/calculator_screen.dart';
import '../features/calculator/data/calculation_history_store.dart';
import '../features/onboarding/data/onboarding_preferences.dart';
import '../features/onboarding/presentation/occupation_selection_screen.dart';
import '../features/settings/data/app_settings_store.dart';

class InstantEstimateApp extends StatefulWidget {
  const InstantEstimateApp({
    required this.onboardingPreferences,
    this.calculationHistoryStore,
    this.appSettingsStore,
    super.key,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final AppSettingsStore? appSettingsStore;

  @override
  State<InstantEstimateApp> createState() => _InstantEstimateAppState();
}

class _InstantEstimateAppState extends State<InstantEstimateApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    unawaited(_loadThemeMode());
  }

  Future<void> _loadThemeMode() async {
    final store = widget.appSettingsStore;
    if (store == null) return;
    try {
      final themeMode = await store.loadThemeMode();
      if (mounted) setState(() => _themeMode = themeMode);
    } catch (_) {
      // 保存値を読めない場合は、安全な端末設定のまま起動する。
    }
  }

  void _changeThemeMode(ThemeMode themeMode) {
    setState(() => _themeMode = themeMode);
    final store = widget.appSettingsStore;
    if (store != null) unawaited(_saveThemeMode(store, themeMode));
  }

  Future<void> _saveThemeMode(
    AppSettingsStore store,
    ThemeMode themeMode,
  ) async {
    try {
      await store.saveThemeMode(themeMode);
    } catch (_) {
      // 表示切替は維持し、次回起動時は保存済み設定へ戻す。
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'インスタント見積',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: _StartupGate(
        onboardingPreferences: widget.onboardingPreferences,
        calculationHistoryStore: widget.calculationHistoryStore,
        themeMode: _themeMode,
        onThemeModeChanged: _changeThemeMode,
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({
    required this.onboardingPreferences,
    required this.calculationHistoryStore,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

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
          return CalculatorScreen(
            historyStore: widget.calculationHistoryStore,
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
          );
        }

        return OccupationSelectionScreen(
          onCompleted: (occupation) async {
            await widget.onboardingPreferences.saveOccupation(occupation);
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => CalculatorScreen(
                  historyStore: widget.calculationHistoryStore,
                  themeMode: widget.themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
