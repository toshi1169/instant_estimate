import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/domain/app_access_plan.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/advertising/application/rewarded_ad_access_controller.dart';
import '../features/advertising/domain/rewarded_ad_policy.dart';
import '../features/calculator/data/calculation_history_store.dart';
import '../features/calculator/presentation/calculator_screen.dart';
import '../features/estimate/data/estimate_item_store.dart';
import '../features/onboarding/data/onboarding_preferences.dart';
import '../features/onboarding/presentation/language_selection_screen.dart';
import '../features/onboarding/presentation/occupation_selection_screen.dart';
import '../features/productivity/data/productivity_record_store.dart';
import '../features/settings/data/app_settings_store.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/subscription/data/app_access_state_store.dart';
import '../features/subscription/domain/app_access_state.dart';

class InstantEstimateApp extends StatefulWidget {
  const InstantEstimateApp({
    required this.onboardingPreferences,
    this.calculationHistoryStore,
    this.appSettingsStore,
    this.estimateItemStore,
    this.productivityRecordStore,
    this.accessStateStore,
    this.rewardedAdPresenter,
    this.enableGoogleMobileAds = false,
    this.accessPlan = AppAccessPlan.free,
    super.key,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final AppSettingsStore? appSettingsStore;
  final EstimateItemStore? estimateItemStore;
  final ProductivityRecordStore? productivityRecordStore;
  final AppAccessStateStore? accessStateStore;
  final RewardedAdPresenter? rewardedAdPresenter;
  final bool enableGoogleMobileAds;
  final AppAccessPlan accessPlan;

  @override
  State<InstantEstimateApp> createState() => _InstantEstimateAppState();
}

class _InstantEstimateAppState extends State<InstantEstimateApp> {
  AppSettings _settings = const AppSettings();
  late AppAccessPlan _accessPlan = widget.accessPlan;
  late AppAccessState _accessState = AppAccessState(plan: widget.accessPlan);
  late final RewardedAdAccessController _rewardedAdAccessController =
      RewardedAdAccessController(
        initialState: _accessState,
        store: widget.accessStateStore,
        presenter:
            widget.rewardedAdPresenter ??
            const UnavailableRewardedAdPresenter(),
      );
  late bool _isAccessStateReady = widget.accessStateStore == null;
  late bool _isSettingsReady = widget.appSettingsStore == null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
    unawaited(_loadAccessState());
  }

  Future<void> _loadAccessState() async {
    final store = widget.accessStateStore;
    if (store == null) return;
    var loadedState = const AppAccessState();
    try {
      loadedState = await store.load();
    } catch (_) {
      // 契約情報を読めない場合は、安全な無料版のまま起動する。
    }
    if (!mounted) return;
    setState(() {
      _accessState = loadedState;
      _rewardedAdAccessController.updateState(loadedState);
      _accessPlan = loadedState.effectivePlan();
      _isAccessStateReady = true;
    });
  }

  Future<void> _loadSettings() async {
    final store = widget.appSettingsStore;
    if (store == null) return;
    var loadedSettings = const AppSettings();
    try {
      loadedSettings = await store.load();
    } catch (_) {
      // 保存値を読めない場合は、安全な初期設定のまま起動する。
    }
    if (!mounted) return;
    setState(() {
      _settings = loadedSettings;
      _isSettingsReady = true;
    });
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
      title: 'Instant Estimate',
      debugShowCheckedModeBanner: false,
      locale: _settings.language.locale,
      supportedLocales: const [Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _settings.theme == AppThemeSelection.gray
          ? AppTheme.gray
          : AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _settings.themeMode,
      home: _isAccessStateReady && _isSettingsReady
          ? _StartupGate(
              onboardingPreferences: widget.onboardingPreferences,
              calculationHistoryStore: widget.calculationHistoryStore,
              estimateItemStore: widget.estimateItemStore,
              productivityRecordStore: widget.productivityRecordStore,
              accessPlan: _accessPlan,
              settings: _settings,
              onSettingsChanged: _changeSettings,
              onRequestRewardedAdAccess:
                  _rewardedAdAccessController.requestAccess,
              enableGoogleMobileAds: widget.enableGoogleMobileAds,
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
    required this.onRequestRewardedAdAccess,
    required this.enableGoogleMobileAds,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final EstimateItemStore? estimateItemStore;
  final ProductivityRecordStore? productivityRecordStore;
  final AppAccessPlan accessPlan;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<bool> Function(RewardedAdEntryPoint) onRequestRewardedAdAccess;
  final bool enableGoogleMobileAds;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<_StartupStatus> _startupStatus = _loadStartupStatus();

  Future<_StartupStatus> _loadStartupStatus() async {
    final preferences = widget.onboardingPreferences;
    final hasSelectedLanguage = preferences is LanguageOnboardingPreferences
        ? await (preferences as LanguageOnboardingPreferences)
              .hasSelectedLanguage()
        : true;
    final hasSelectedOccupation = await preferences.hasSelectedOccupation();
    return _StartupStatus(
      hasSelectedLanguage: hasSelectedLanguage,
      hasSelectedOccupation: hasSelectedOccupation,
    );
  }

  void _replaceStatus(_StartupStatus status) {
    setState(() {
      _startupStatus = Future.value(status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupStatus>(
      future: _startupStatus,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(color: Colors.transparent);
        }

        final status = snapshot.data!;
        if (!status.hasSelectedLanguage) {
          return LanguageSelectionScreen(
            selectedLanguage: widget.settings.language,
            onCompleted: (language) async {
              widget.onSettingsChanged(
                widget.settings.copyWith(language: language),
              );
              final preferences = widget.onboardingPreferences;
              if (preferences is LanguageOnboardingPreferences) {
                await (preferences as LanguageOnboardingPreferences)
                    .saveLanguage(language.name);
              }
              if (!mounted) return;
              _replaceStatus(status.copyWith(hasSelectedLanguage: true));
            },
          );
        }

        if (status.hasSelectedOccupation) {
          return CalculatorScreen(
            historyStore: widget.calculationHistoryStore,
            estimateItemStore: widget.estimateItemStore,
            productivityRecordStore: widget.productivityRecordStore,
            accessPlan: widget.accessPlan,
            settings: widget.settings,
            onSettingsChanged: widget.onSettingsChanged,
            onRequestRewardedAdAccess: widget.onRequestRewardedAdAccess,
            enableGoogleMobileAds: widget.enableGoogleMobileAds,
          );
        }

        return OccupationSelectionScreen(
          onCompleted: (occupation) async {
            await widget.onboardingPreferences.saveOccupation(occupation);
            if (!mounted) return;
            _replaceStatus(status.copyWith(hasSelectedOccupation: true));
          },
        );
      },
    );
  }
}

class _StartupStatus {
  const _StartupStatus({
    required this.hasSelectedLanguage,
    required this.hasSelectedOccupation,
  });

  final bool hasSelectedLanguage;
  final bool hasSelectedOccupation;

  _StartupStatus copyWith({
    bool? hasSelectedLanguage,
    bool? hasSelectedOccupation,
  }) {
    return _StartupStatus(
      hasSelectedLanguage: hasSelectedLanguage ?? this.hasSelectedLanguage,
      hasSelectedOccupation:
          hasSelectedOccupation ?? this.hasSelectedOccupation,
    );
  }
}
