import 'package:flutter/material.dart';

import '../../../core/domain/app_access_plan.dart';
import '../../../core/domain/angle_unit.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_localizations.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.onSettingsChanged,
    required this.onClearHistory,
    this.accessPlan = AppAccessPlan.free,
    this.onShowAdvertisingPrivacyOptions,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<void> Function() onClearHistory;
  final AppAccessPlan accessPlan;
  final Future<void> Function()? onShowAdvertisingPrivacyOptions;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings = widget.settings;

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _settings = widget.settings;
  }

  void _update(AppSettings settings) {
    setState(() => _settings = settings);
    widget.onSettingsChanged(settings);
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final choice in choices)
              ListTile(
                title: Text(choice.$2),
                trailing: choice.$1 == selected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(choice.$1),
              ),
            const SizedBox(height: 8),
          ],
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
      ],
    );
    if (value != null) _update(_settings.copyWith(language: value));
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
                  }),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectLanguage(context),
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
                ),
                const Divider(height: 1),
                _PurchaseStatusTile(
                  key: const Key('purchaseStatusFull'),
                  icon: Icons.workspace_premium_outlined,
                  title: strings.fullPlan,
                  status: _fullPlanStatus(widget.accessPlan, strings),
                  active: widget.accessPlan == AppAccessPlan.full,
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
        ],
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
    super.key,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool active;

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
