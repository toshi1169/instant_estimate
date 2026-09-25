import 'package:flutter/material.dart';

import '../../../core/domain/app_access_plan.dart';
import '../../../core/domain/angle_unit.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_localizations.dart';
import '../domain/app_settings.dart';
import '../domain/company_profile.dart';
import '../../estimate/domain/estimate_quantity.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../../onboarding/domain/occupation.dart';
import '../../onboarding/presentation/occupation_selection_screen.dart';
import '../../help/presentation/disclaimer_screen.dart';
import '../../help/presentation/support_links_section.dart';
import '../../subscription/domain/purchase_store.dart';
import '../../subscription/presentation/access_plan_screen.dart';
import '../../backup/application/backup_snapshot_factory.dart';
import '../../backup/application/backup_restore_coordinator.dart';
import '../../backup/presentation/backup_screen.dart';
import 'button_settings_screen.dart';
import 'company_profile_editor_screen.dart';
import 'result_display_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.onSettingsChanged,
    required this.onClearHistory,
    this.onboardingPreferences,
    this.accessPlan = AppAccessPlan.free,
    this.purchaseStore,
    this.onShowAdvertisingPrivacyOptions,
    this.backupSnapshotFactory,
    this.backupRestoreCoordinator,
    this.onBackupRestored,
    this.supportLinkLauncher,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<void> Function() onClearHistory;
  final OnboardingPreferences? onboardingPreferences;
  final AppAccessPlan accessPlan;
  final PurchaseStore? purchaseStore;
  final Future<void> Function()? onShowAdvertisingPrivacyOptions;
  final BackupSnapshotFactory? backupSnapshotFactory;
  final BackupRestoreCoordinator? backupRestoreCoordinator;
  final Future<void> Function(AppSettings settings)? onBackupRestored;
  final SupportLinkLauncher? supportLinkLauncher;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings = widget.settings;
  Occupation? _occupation;

  @override
  void initState() {
    super.initState();
    _loadOccupation();
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _settings = widget.settings;
  }

  void _update(AppSettings settings) {
    setState(() => _settings = settings);
    widget.onSettingsChanged(settings);
  }

  Future<void> _loadOccupation() async {
    final preferences = widget.onboardingPreferences;
    if (preferences == null) return;
    String? stored;
    try {
      stored = await preferences.loadOccupation();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _occupation = Occupation.fromStoredValue(stored));
  }

  Future<void> _selectOccupation(BuildContext context) async {
    final preferences = widget.onboardingPreferences;
    if (preferences == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => OccupationSelectionScreen(
          initialOccupation: _occupation,
          isEditing: true,
          onCompleted: (storageKey) async {
            await preferences.saveOccupation(storageKey);
            if (!routeContext.mounted) return;
            Navigator.of(routeContext).pop();
          },
        ),
      ),
    );
    if (!mounted) return;
    await _loadOccupation();
  }

  Future<T?> _selectValue<T>(
    BuildContext context, {
    required String title,
    required T selected,
    required List<(T, String)> choices,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: choices.length,
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    return ListTile(
                      title: Text(choice.$2),
                      trailing: choice.$1 == selected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(choice.$1),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTheme(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final value = await _selectValue<AppThemeSelection>(
      context,
      title: strings.theme,
      selected: _settings.theme,
      choices: [
        (AppThemeSelection.system, strings.systemTheme),
        (AppThemeSelection.light, strings.whiteTheme),
        (AppThemeSelection.gray, strings.grayTheme),
        (AppThemeSelection.dark, strings.blackTheme),
      ],
    );
    if (value != null) _update(_settings.copyWith(theme: value));
  }

  Future<void> _selectDecimalPlaces(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final value = await _selectValue<int>(
      context,
      title: strings.decimalPlaces,
      selected: _settings.decimalPlaces,
      choices: [
        for (var count = 1; count <= 5; count++) (count, strings.digits(count)),
      ],
    );
    if (value != null) {
      _update(_settings.copyWith(decimalPlaces: value));
    }
  }

  Future<void> _selectRoundingMode(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final value = await _selectValue<CalculatorRoundingMode>(
      context,
      title: strings.roundingMethod,
      selected: _settings.roundingMode,
      choices: [
        (CalculatorRoundingMode.halfUp, strings.roundHalfUp),
        (CalculatorRoundingMode.ceiling, strings.roundUp),
        (CalculatorRoundingMode.floor, strings.roundDown),
      ],
    );
    if (value != null) {
      _update(_settings.copyWith(roundingMode: value));
    }
  }

  Future<void> _selectEstimateDecimalPlaces(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final value = await _selectValue<int>(
      context,
      title: strings.estimateQuantityDecimalPlaces,
      selected: _settings.estimateDecimalPlaces,
      choices: [
        for (var count = 1; count <= 5; count++) (count, strings.digits(count)),
      ],
    );
    if (value != null) {
      _update(_settings.copyWith(estimateDecimalPlaces: value));
    }
  }

  Future<void> _selectEstimateRoundingMode(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final value = await _selectValue<EstimateQuantityRoundingMode>(
      context,
      title: strings.estimateQuantityRoundingMethod,
      selected: _settings.estimateRoundingMode,
      choices: [
        (EstimateQuantityRoundingMode.halfUp, strings.roundHalfUp),
        (EstimateQuantityRoundingMode.ceiling, strings.roundUp),
        (EstimateQuantityRoundingMode.floor, strings.roundDown),
      ],
    );
    if (value != null) {
      _update(_settings.copyWith(estimateRoundingMode: value));
    }
  }

  Future<void> _selectAngleUnit(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final value = await _selectValue<AngleUnit>(
      context,
      title: strings.angleUnit,
      selected: _settings.angleUnit,
      choices: [
        (AngleUnit.degrees, strings.degrees),
        (AngleUnit.radians, strings.radians),
      ],
    );
    if (value != null) _update(_settings.copyWith(angleUnit: value));
  }

  Future<void> _selectLanguage(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final value = await _selectValue<AppLanguage>(
      context,
      title: strings.language,
      selected: _settings.language,
      choices: [
        (AppLanguage.japanese, strings.japanese),
        (AppLanguage.english, strings.english),
        (AppLanguage.simplifiedChinese, strings.simplifiedChinese),
        (AppLanguage.traditionalChinese, strings.traditionalChinese),
        (AppLanguage.vietnamese, strings.vietnamese),
        (AppLanguage.indonesian, strings.indonesian),
        (AppLanguage.filipino, strings.filipino),
        (AppLanguage.myanmar, strings.myanmar),
      ],
    );
    if (value != null) _update(_settings.copyWith(language: value));
  }

  Future<void> _editCompanyProfile(BuildContext context) async {
    final profile = await Navigator.of(context).push(
      MaterialPageRoute<CompanyProfile>(
        builder: (_) => CompanyProfileEditorScreen(
          initialProfile: _settings.companyProfile,
        ),
      ),
    );
    if (profile != null && context.mounted) {
      _update(_settings.copyWith(companyProfile: profile));
    }
  }

  Future<void> _editButtonSettings(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ButtonSettingsScreen(
          tapSoundEnabled: _settings.calculatorTapSoundEnabled,
          hapticsEnabled: _settings.calculatorHapticsEnabled,
          onTapSoundChanged: (value) =>
              _update(_settings.copyWith(calculatorTapSoundEnabled: value)),
          onHapticsChanged: (value) =>
              _update(_settings.copyWith(calculatorHapticsEnabled: value)),
        ),
      ),
    );
  }

  Future<void> _editResultDisplaySettings(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResultDisplaySettingsScreen(
          improperFractionEnabled: _settings.improperFractionResultEnabled,
          mixedFractionEnabled: _settings.mixedFractionResultEnabled,
          remainderEnabled: _settings.remainderResultEnabled,
          onImproperFractionChanged: (value) =>
              _update(_settings.copyWith(improperFractionResultEnabled: value)),
          onMixedFractionChanged: (value) =>
              _update(_settings.copyWith(mixedFractionResultEnabled: value)),
          onRemainderChanged: (value) =>
              _update(_settings.copyWith(remainderResultEnabled: value)),
        ),
      ),
    );
  }

  Future<void> _openDisclaimer(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const DisclaimerScreen()),
    );
  }

  void _openSourceLicenses(BuildContext context) {
    final strings = AppLocalizations.of(context);
    showLicensePage(context: context, applicationName: strings.appTitle);
  }

  Future<void> _openBackup(BuildContext context) {
    final factory = widget.backupSnapshotFactory;
    if (factory == null) return Future.value();
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BackupScreen(
          snapshotFactory: factory,
          settings: _settings,
          restoreCoordinator: widget.backupRestoreCoordinator,
          onRestored: (settings) async {
            if (!mounted) return;
            setState(() => _settings = settings);
            widget.onSettingsChanged(settings);
            await _loadOccupation();
            await widget.onBackupRestored?.call(settings);
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.clearAllHistory),
        content: Text(strings.clearHistoryQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await widget.onClearHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.historyCleared)));
  }

  Future<void> _showAdvertisingPrivacyOptions(BuildContext context) async {
    final showOptions = widget.onShowAdvertisingPrivacyOptions;
    if (showOptions == null) return;
    try {
      await showOptions();
    } catch (_) {
      if (!context.mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.text('広告のプライバシー設定を開けませんでした'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            strings.displayAndCalculation,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const Key('languageSetting'),
                  leading: const Icon(Icons.language_outlined),
                  title: Text(strings.language),
                  subtitle: Text(switch (_settings.language) {
                    AppLanguage.japanese => '日本語',
                    AppLanguage.english => 'English',
                    AppLanguage.simplifiedChinese => '简体中文',
                    AppLanguage.traditionalChinese => '繁體中文',
                    AppLanguage.vietnamese => 'Tiếng Việt',
                    AppLanguage.indonesian => 'Bahasa Indonesia',
                    AppLanguage.filipino => 'Filipino',
                    AppLanguage.myanmar => 'မြန်မာ',
                  }),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectLanguage(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('occupationSetting'),
                  leading: const Icon(Icons.engineering_outlined),
                  title: Text(strings.mainOccupation),
                  subtitle: Text(
                    _occupation == null
                        ? strings.notRegistered
                        : strings.occupation(_occupation!.legacyLabel),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onboardingPreferences == null
                      ? null
                      : () => _selectOccupation(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('themeSetting'),
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(strings.theme),
                  subtitle: Text(_themeLabel(_settings.theme, strings)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectTheme(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('buttonSettings'),
                  leading: const Icon(Icons.touch_app_outlined),
                  title: Text(strings.buttonSettings),
                  subtitle: Text(
                    '${strings.calculatorTapSound}: '
                    '${_settings.calculatorTapSoundEnabled ? 'ON' : 'OFF'}  '
                    '${strings.calculatorTapHaptics}: '
                    '${_settings.calculatorHapticsEnabled ? 'ON' : 'OFF'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editButtonSettings(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('decimalPlacesSetting'),
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(strings.decimalPlaces),
                  subtitle: Text(strings.digits(_settings.decimalPlaces)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectDecimalPlaces(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('roundingModeSetting'),
                  leading: const Icon(Icons.functions),
                  title: Text(strings.roundingMethod),
                  subtitle: Text(
                    _roundingLabel(_settings.roundingMode, strings),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectRoundingMode(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('resultDisplaySetting'),
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(strings.resultDisplaySettings),
                  subtitle: Text(
                    strings.resultDisplaySummary(
                      improperFraction: _settings.improperFractionResultEnabled,
                      mixedFraction: _settings.mixedFractionResultEnabled,
                      remainder: _settings.remainderResultEnabled,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _editResultDisplaySettings(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('angleUnitSetting'),
                  leading: const Icon(Icons.straighten_outlined),
                  title: Text(strings.angleUnit),
                  subtitle: Text(
                    _settings.angleUnit == AngleUnit.degrees
                        ? strings.degrees
                        : strings.radians,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectAngleUnit(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.companyProfile,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: const Key('companyProfileSetting'),
              leading: const Icon(Icons.business_outlined),
              title: Text(strings.companyProfile),
              subtitle: Text(
                _settings.companyProfile.companyName.isEmpty
                    ? strings.notRegistered
                    : _settings.companyProfile.companyName,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editCompanyProfile(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.instantEstimateSettings,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const Key('estimateDecimalPlacesSetting'),
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(strings.estimateQuantityDecimalPlaces),
                  subtitle: Text(
                    strings.digits(_settings.estimateDecimalPlaces),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectEstimateDecimalPlaces(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('estimateRoundingModeSetting'),
                  leading: const Icon(Icons.request_quote_outlined),
                  title: Text(strings.estimateQuantityRoundingMethod),
                  subtitle: Text(switch (_settings.estimateRoundingMode) {
                    EstimateQuantityRoundingMode.halfUp => strings.roundHalfUp,
                    EstimateQuantityRoundingMode.ceiling => strings.roundUp,
                    EstimateQuantityRoundingMode.floor => strings.roundDown,
                  }),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectEstimateRoundingMode(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.text('購入状況'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _PurchaseStatusTile(
                  key: const Key('purchaseStatusAdFree'),
                  icon: Icons.block_outlined,
                  title: strings.adFreePlan,
                  status: _adFreeStatus(widget.accessPlan, strings),
                  active: widget.accessPlan != AppAccessPlan.free,
                  onTap: () => _openAccessPlan(context, AppAccessPlan.adFree),
                ),
                const Divider(height: 1),
                _PurchaseStatusTile(
                  key: const Key('purchaseStatusFull'),
                  icon: Icons.workspace_premium_outlined,
                  title: strings.fullPlan,
                  status: _fullPlanStatus(widget.accessPlan, strings),
                  active: widget.accessPlan == AppAccessPlan.full,
                  onTap: () => _openAccessPlan(context, AppAccessPlan.full),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            strings.calculationHistory,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('historySortSwitch'),
                  secondary: const Icon(Icons.sort),
                  title: Text(strings.ascendingHistory),
                  subtitle: Text(
                    _settings.historySortOrder == HistorySortOrder.ascending
                        ? strings.ascendingOldest
                        : strings.descendingNewest,
                  ),
                  value:
                      _settings.historySortOrder == HistorySortOrder.ascending,
                  onChanged: (ascending) => _update(
                    _settings.copyWith(
                      historySortOrder: ascending
                          ? HistorySortOrder.ascending
                          : HistorySortOrder.descending,
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  key: const Key('historyDeleteConfirmationSwitch'),
                  secondary: const Icon(Icons.help_outline),
                  title: Text(strings.confirmHistoryDeletion),
                  value: _settings.confirmHistoryDeletion,
                  onChanged: (value) => _update(
                    _settings.copyWith(confirmHistoryDeletion: value),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('clearAllHistorySetting'),
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    strings.clearAllHistory,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _confirmClearHistory(context),
                ),
              ],
            ),
          ),
          if (widget.onShowAdvertisingPrivacyOptions != null) ...[
            const SizedBox(height: 24),
            Text(
              strings.text('プライバシー'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                key: const Key('advertisingPrivacyOptionsSetting'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(strings.text('広告のプライバシー設定')),
                subtitle: Text(strings.text('広告に関する同意内容を確認・変更します')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAdvertisingPrivacyOptions(context),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: const Key('dataBackupSetting'),
              leading: const Icon(Icons.backup_outlined),
              title: Text(strings.dataBackup),
              subtitle: Text(strings.dataBackupSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.backupSnapshotFactory == null
                  ? null
                  : () => _openBackup(context),
            ),
          ),
          const SizedBox(height: 24),
          SupportLinksSection(
            key: const Key('settingsSupportSection'),
            linkLauncher: widget.supportLinkLauncher,
          ),
          const SizedBox(height: 24),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: const Key('disclaimerSetting'),
              leading: const Icon(Icons.gavel_outlined),
              title: Text(strings.disclaimerTitle),
              subtitle: Text(strings.disclaimerSettingsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openDisclaimer(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              key: const Key('openSourceLicensesSetting'),
              leading: const Icon(Icons.article_outlined),
              title: Text(strings.openSourceLicenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSourceLicenses(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAccessPlan(BuildContext context, AppAccessPlan plan) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccessPlanScreen(
          plan: plan,
          currentPlan: widget.accessPlan,
          purchaseStore: widget.purchaseStore,
        ),
      ),
    );
  }
}

String _themeLabel(AppThemeSelection value, AppLocalizations strings) =>
    switch (value) {
      AppThemeSelection.system => strings.systemTheme,
      AppThemeSelection.light => strings.whiteTheme,
      AppThemeSelection.gray => strings.grayTheme,
      AppThemeSelection.dark => strings.blackTheme,
    };

String _roundingLabel(CalculatorRoundingMode value, AppLocalizations strings) =>
    switch (value) {
      CalculatorRoundingMode.halfUp => strings.roundHalfUp,
      CalculatorRoundingMode.ceiling => strings.roundUp,
      CalculatorRoundingMode.floor => strings.roundDown,
    };

class _PurchaseStatusTile extends StatelessWidget {
  const _PurchaseStatusTile({
    required this.icon,
    required this.title,
    required this.status,
    required this.active,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        status,
        style: TextStyle(
          color: active ? colors.primary : colors.onSurfaceVariant,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: Icon(
        active ? Icons.check_circle : Icons.remove_circle_outline,
        color: active ? colors.primary : colors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

String _adFreeStatus(AppAccessPlan plan, AppLocalizations strings) =>
    switch (plan) {
      AppAccessPlan.free => strings.text('未購入'),
      AppAccessPlan.adFree => strings.text('購入済み'),
      AppAccessPlan.full => strings.text('完全版特典で有効'),
    };

String _fullPlanStatus(AppAccessPlan plan, AppLocalizations strings) =>
    plan == AppAccessPlan.full ? strings.text('契約中') : strings.text('未契約');
