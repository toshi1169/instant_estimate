import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/domain/app_access_plan.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/advertising/application/advertising_consent_manager.dart';
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
import '../features/subscription/domain/purchase_store.dart';
import '../features/backup/application/backup_restore_coordinator.dart';

class InstantEstimateApp extends StatefulWidget {
  const InstantEstimateApp({
    required this.onboardingPreferences,
    this.calculationHistoryStore,
    this.appSettingsStore,
    this.estimateItemStore,
    this.productivityRecordStore,
    this.accessStateStore,
    this.rewardedAdPresenter,
    this.advertisingConsentManager,
    this.enableGoogleMobileAds = false,
    this.purchaseStore,
    this.accessPlan = AppAccessPlan.free,
    this.backupRestoreCoordinator,
    super.key,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final AppSettingsStore? appSettingsStore;
  final EstimateItemStore? estimateItemStore;
  final ProductivityRecordStore? productivityRecordStore;
  final AppAccessStateStore? accessStateStore;
  final RewardedAdPresenter? rewardedAdPresenter;
  final AdvertisingConsentManager? advertisingConsentManager;
  final bool enableGoogleMobileAds;
  final PurchaseStore? purchaseStore;
  final AppAccessPlan accessPlan;
  final BackupRestoreCoordinator? backupRestoreCoordinator;

  @override
  State<InstantEstimateApp> createState() => _InstantEstimateAppState();
}

class _InstantEstimateAppState extends State<InstantEstimateApp>
    with WidgetsBindingObserver {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
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
  late bool _isRestoreRecoveryReady = widget.backupRestoreCoordinator == null;
  RestoreRecoveryResult _restoreRecoveryResult = RestoreRecoveryResult.none;
  late AdvertisingConsentState _advertisingConsentState =
      widget.advertisingConsentManager?.state.value ??
      const AdvertisingConsentState(canRequestAds: true);
  StreamSubscription<PurchaseEntitlementSnapshot>?
  _purchaseEntitlementSnapshotSubscription;
  bool _advertisingStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.advertisingConsentManager?.state.addListener(
      _handleAdvertisingConsentChanged,
    );
    if (widget.backupRestoreCoordinator == null) {
      unawaited(_loadSettings());
    } else {
      unawaited(_recoverAndLoadSettings());
    }
    unawaited(_initializeAccessAndPurchases());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.advertisingConsentManager?.state.removeListener(
      _handleAdvertisingConsentChanged,
    );
    unawaited(_purchaseEntitlementSnapshotSubscription?.cancel());
    widget.purchaseStore?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshEntitlementsAfterResume());
    }
  }

  Future<void> _refreshEntitlementsAfterResume() async {
    final purchaseStore = widget.purchaseStore;
    if (purchaseStore == null) return;
    PurchaseEntitlementSnapshot snapshot;
    try {
      snapshot = await purchaseStore.refreshEntitlements();
    } catch (_) {
      return;
    }
    await _applyEntitlementSnapshot(snapshot);
  }

  Future<void> _initializeAccessAndPurchases() async {
    await _loadAccessState();
    final purchaseStore = widget.purchaseStore;
    if (purchaseStore == null) {
      _startAdvertisingIfNeeded();
      return;
    }
    _purchaseEntitlementSnapshotSubscription = purchaseStore
        .entitlementSnapshots
        .listen((snapshot) => unawaited(_applyEntitlementSnapshot(snapshot)));
    await purchaseStore.initialize();
    final snapshot = await purchaseStore.refreshEntitlements();
    await _applyEntitlementSnapshot(snapshot);
    _startAdvertisingIfNeeded();
  }

  Future<void> _applyEntitlementSnapshot(
    PurchaseEntitlementSnapshot snapshot,
  ) async {
    if (!snapshot.isVerified) return;
    final updatedState = _accessState.reconcileVerifiedPlan(
      snapshot.effectivePlan,
      verifiedAt: DateTime.now(),
    );
    await _saveAndApplyAccessState(updatedState);
    _startAdvertisingIfNeeded();
  }

  void _startAdvertisingIfNeeded() {
    if (_advertisingStarted ||
        !widget.enableGoogleMobileAds ||
        !_accessPlan.showsAds) {
      return;
    }
    _advertisingStarted = true;
    unawaited(widget.advertisingConsentManager?.gatherConsent());
  }

  Future<void> _saveAndApplyAccessState(AppAccessState updatedState) async {
    final store = widget.accessStateStore;
    if (store != null) {
      try {
        await store.save(updatedState);
      } catch (_) {
        // ストアの購入結果は画面へ反映し、保存は次回の復元で再取得できる。
      }
    }
    if (!mounted) return;
    setState(() {
      _accessState = updatedState;
      _accessPlan = updatedState.effectivePlan();
      _rewardedAdAccessController.updateState(updatedState);
    });
  }

  void _handleAdvertisingConsentChanged() {
    if (!mounted) return;
    setState(() {
      _advertisingConsentState =
          widget.advertisingConsentManager?.state.value ??
          const AdvertisingConsentState(canRequestAds: true);
    });
  }

  Future<bool> _requestRewardedAdAccess(RewardedAdEntryPoint entryPoint) async {
    final consentManager = widget.advertisingConsentManager;
    if (widget.enableGoogleMobileAds &&
        consentManager != null &&
        !consentManager.state.value.canRequestAds) {
      await consentManager.gatherConsent();
      if (!consentManager.state.value.canRequestAds) {
        // 同意情報や広告を取得できない場合も、機能は利用可能にする。
        return true;
      }
    }
    final granted = await _rewardedAdAccessController.requestAccess(entryPoint);
    if (!mounted) return granted;
    setState(() {
      _accessState = _rewardedAdAccessController.state;
      _accessPlan = _accessState.effectivePlan();
    });
    return granted;
  }

  bool _isRewardedAdRequired(RewardedAdEntryPoint entryPoint) {
    return _rewardedAdAccessController.requiresAd(entryPoint);
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

  Future<void> _recoverAndLoadSettings() async {
    var result = RestoreRecoveryResult.rollbackFailed;
    try {
      result = await widget.backupRestoreCoordinator!
          .recoverInterruptedRestore();
    } catch (_) {
      result = RestoreRecoveryResult.rollbackFailed;
    }
    if (!mounted) return;
    setState(() {
      _restoreRecoveryResult = result;
      _isRestoreRecoveryReady = true;
    });
    await _loadSettings();
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
      scaffoldMessengerKey: _scaffoldMessengerKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: _settings.language.locale,
      supportedLocales: const [
        Locale('ja'),
        Locale('en'),
        Locale('zh', 'CN'),
        Locale('zh', 'TW'),
        Locale('vi'),
        Locale('id'),
        Locale('fil'),
        Locale('my'),
      ],
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
      themeMode: _isSettingsReady ? _settings.themeMode : ThemeMode.system,
      home: _isAccessStateReady && _isSettingsReady && _isRestoreRecoveryReady
          ? _restoreRecoveryResult == RestoreRecoveryResult.rollbackFailed
                ? const _RestoreRecoveryBlockedScreen()
                : _StartupGate(
                    onboardingPreferences: widget.onboardingPreferences,
                    calculationHistoryStore: widget.calculationHistoryStore,
                    estimateItemStore: widget.estimateItemStore,
                    productivityRecordStore: widget.productivityRecordStore,
                    accessPlan: _accessPlan,
                    settings: _settings,
                    onSettingsChanged: _changeSettings,
                    onRequestRewardedAdAccess: _requestRewardedAdAccess,
                    isRewardedAdRequired: _isRewardedAdRequired,
                    onShowAdvertisingPrivacyOptions:
                        _advertisingConsentState.privacyOptionsRequired
                        ? widget.advertisingConsentManager?.showPrivacyOptions
                        : null,
                    enableGoogleMobileAds:
                        widget.enableGoogleMobileAds &&
                        _advertisingConsentState.canRequestAds,
                    purchaseStore: widget.purchaseStore,
                    backupRestoreCoordinator: widget.backupRestoreCoordinator,
                    restoreRecoveryMessage:
                        _restoreRecoveryResult ==
                            RestoreRecoveryResult.rolledBack
                        ? AppLocalizations.of(
                            context,
                          ).restoreInterruptedRolledBack
                        : null,
                  )
          : Builder(
              builder: (context) =>
                  ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
            ),
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
    required this.isRewardedAdRequired,
    required this.onShowAdvertisingPrivacyOptions,
    required this.enableGoogleMobileAds,
    required this.purchaseStore,
    required this.backupRestoreCoordinator,
    required this.restoreRecoveryMessage,
  });

  final OnboardingPreferences onboardingPreferences;
  final CalculationHistoryStore? calculationHistoryStore;
  final EstimateItemStore? estimateItemStore;
  final ProductivityRecordStore? productivityRecordStore;
  final AppAccessPlan accessPlan;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<bool> Function(RewardedAdEntryPoint) onRequestRewardedAdAccess;
  final bool Function(RewardedAdEntryPoint) isRewardedAdRequired;
  final Future<void> Function()? onShowAdvertisingPrivacyOptions;
  final bool enableGoogleMobileAds;
  final PurchaseStore? purchaseStore;
  final BackupRestoreCoordinator? backupRestoreCoordinator;
  final String? restoreRecoveryMessage;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<_StartupStatus> _startupStatus = _loadStartupStatus();
  bool _restoreRecoveryMessageShown = false;

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
        final recoveryMessage = widget.restoreRecoveryMessage;
        if (recoveryMessage != null && !_restoreRecoveryMessageShown) {
          _restoreRecoveryMessageShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(recoveryMessage)));
          });
        }
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
            isRewardedAdRequired: widget.isRewardedAdRequired,
            onShowAdvertisingPrivacyOptions:
                widget.onShowAdvertisingPrivacyOptions,
            enableGoogleMobileAds: widget.enableGoogleMobileAds,
            purchaseStore: widget.purchaseStore,
            onboardingPreferences: widget.onboardingPreferences,
            backupRestoreCoordinator: widget.backupRestoreCoordinator,
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

class _RestoreRecoveryBlockedScreen extends StatelessWidget {
  const _RestoreRecoveryBlockedScreen();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  strings.restoreRollbackFailed,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
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
