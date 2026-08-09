import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/app_access_plan.dart';
import '../core/theme/app_theme.dart';
import '../features/calculator/presentation/calculator_screen.dart';
import '../features/calculator/data/calculation_history_store.dart';
import '../features/onboarding/data/onboarding_preferences.dart';
import '../features/onboarding/presentation/occupation_selection_screen.dart';
import '../features/settings/data/app_settings_store.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/estimate/data/estimate_item_store.dart';
import '../features/productivity/data/productivity_record_store.dart';
import '../features/subscription/data/app_access_state_store.dart';

class InstantEstimateApp extends StatefulWidget {
  const InstantEstimateApp({
    required this.onboardingPreferences,
    this.calculationHistoryStore,
    this.appSettingsStore,
    this.estimateItemStore,
    this.productivityRecordStore,
    this.accessStateStore,
    this.accessPlan = AppAccessPlan.free,
    super.key,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final AppSettingsStore? appSettingsStore;
  final EstimateItemStore? estimateItemStore;
  final ProductivityRecordStore? productivityRecordStore;
  final AppAccessStateStore? accessStateStore;
  final AppAccessPlan accessPlan;

  @override
  State<InstantEstimateApp> createState() => _InstantEstimateAppState();
}

class _InstantEstimateAppState extends State<InstantEstimateApp> {
  AppSettings _settings = const AppSettings();
  late AppAccessPlan _accessPlan = widget.accessPlan;
  late bool _isAccessStateReady = widget.accessStateStore == null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
    unawaited(_loadAccessState());
  }

  Future<void> _loadAccessState() async {
    final store = widget.accessStateStore;
    if (store == null) return;
    var loadedPlan = AppAccessPlan.free;
    try {
      final state = await store.load();
      loadedPlan = state.effectivePlan();
    } catch (_) {
      // 契約情報を読めない場合は、安全な無料版のまま起動する。
    }
    if (!mounted) return;
    setState(() {
      _accessPlan = loadedPlan;
      _isAccessStateReady = true;
    });
  }

  Future<void> _loadSettings() async {
    final store = widget.appSettingsStore;
    if (store == null) return;
    try {
      final settings = await store.load();
      if (mounted) setState(() => _settings = settings);
    } catch (_) {
      // 保存値を読めない場合は、安全な初期設定のまま起動する。
    }
  }

  void _changeSettings(AppSettings settings) {
    setState(() => _settings = settings);
    final store = widget.appSettingsStore;
    if (store != null) unawaited(_saveSettings(store, settings));
  }

  Future<void> _saveSettings(
    AppSettingsStore store,
    AppSettings settings,
  ) async {
    try {
      await store.save(settings);
    } catch (_) {
      // 表示切替は維持し、次回起動時は保存済み設定へ戻す。
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'インスタント見積',
      debugShowCheckedModeBanner: false,
      theme: _settings.theme == AppThemeSelection.gray
          ? AppTheme.gray
          : AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _settings.themeMode,
      home: _isAccessStateReady
          ? _StartupGate(
              onboardingPreferences: widget.onboardingPreferences,
              calculationHistoryStore: widget.calculationHistoryStore,
              estimateItemStore: widget.estimateItemStore,
              productivityRecordStore: widget.productivityRecordStore,
              accessPlan: _accessPlan,
              settings: _settings,
              onSettingsChanged: _changeSettings,
            )
          : const ColoredBox(color: Colors.transparent),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({
    required this.onboardingPreferences,
    required this.calculationHistoryStore,
    required this.estimateItemStore,
    required this.productivityRecordStore,
    required this.accessPlan,
    required this.settings,
    required this.onSettingsChanged,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final EstimateItemStore? estimateItemStore;
  final ProductivityRecordStore? productivityRecordStore;
  final AppAccessPlan accessPlan;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

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
            estimateItemStore: widget.estimateItemStore,
            productivityRecordStore: widget.productivityRecordStore,
            accessPlan: widget.accessPlan,
            settings: widget.settings,
            onSettingsChanged: widget.onSettingsChanged,
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
                  estimateItemStore: widget.estimateItemStore,
                  productivityRecordStore: widget.productivityRecordStore,
                  accessPlan: widget.accessPlan,
                  settings: widget.settings,
                  onSettingsChanged: widget.onSettingsChanged,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
