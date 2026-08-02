import 'package:flutter/material.dart';

import '../../../core/domain/angle_unit.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.onSettingsChanged,
    required this.onClearHistory,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<void> Function() onClearHistory;

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
    final value = await _selectValue<AppThemeSelection>(
      context,
      title: 'テーマ',
      selected: _settings.theme,
      choices: const [
        (AppThemeSelection.system, '端末に合わせる'),
        (AppThemeSelection.light, '白'),
        (AppThemeSelection.gray, 'グレー'),
        (AppThemeSelection.dark, '黒'),
      ],
    );
    if (value != null) _update(_settings.copyWith(theme: value));
  }

  Future<void> _selectDecimalPlaces(BuildContext context) async {
    final value = await _selectValue<int>(
      context,
      title: '小数点以下の表示桁数',
      selected: _settings.decimalPlaces,
      choices: const [(1, '1桁'), (2, '2桁'), (3, '3桁'), (4, '4桁'), (5, '5桁')],
    );
    if (value != null) {
      _update(_settings.copyWith(decimalPlaces: value));
    }
  }

  Future<void> _selectRoundingMode(BuildContext context) async {
    final value = await _selectValue<CalculatorRoundingMode>(
      context,
      title: '丸め方法',
      selected: _settings.roundingMode,
      choices: const [
        (CalculatorRoundingMode.halfUp, '四捨五入'),
        (CalculatorRoundingMode.ceiling, '切上げ'),
        (CalculatorRoundingMode.floor, '切捨て'),
      ],
    );
    if (value != null) {
      _update(_settings.copyWith(roundingMode: value));
    }
  }

  Future<void> _selectAngleUnit(BuildContext context) async {
    final value = await _selectValue<AngleUnit>(
      context,
      title: '角度単位',
      selected: _settings.angleUnit,
      choices: const [
        (AngleUnit.degrees, '度（DEG）'),
        (AngleUnit.radians, 'ラジアン（RAD）'),
      ],
    );
    if (value != null) _update(_settings.copyWith(angleUnit: value));
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴をすべて削除'),
        content: const Text('スター付き以外の計算履歴をすべて削除します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await widget.onClearHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('計算履歴をすべて削除しました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('表示・計算', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  key: const Key('themeSetting'),
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('テーマ'),
                  subtitle: Text(_themeLabel(_settings.theme)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectTheme(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('decimalPlacesSetting'),
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('小数点以下の表示桁数'),
                  subtitle: Text('${_settings.decimalPlaces}桁'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectDecimalPlaces(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('roundingModeSetting'),
                  leading: const Icon(Icons.functions),
                  title: const Text('丸め方法'),
                  subtitle: Text(_roundingLabel(_settings.roundingMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectRoundingMode(context),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('angleUnitSetting'),
                  leading: const Icon(Icons.straighten_outlined),
                  title: const Text('角度単位'),
                  subtitle: Text(
                    _settings.angleUnit == AngleUnit.degrees
                        ? '度（DEG）'
                        : 'ラジアン（RAD）',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectAngleUnit(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('計算履歴', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  key: const Key('historySortSwitch'),
                  secondary: const Icon(Icons.sort),
                  title: const Text('履歴を昇順で表示'),
                  subtitle: Text(
                    _settings.historySortOrder == HistorySortOrder.ascending
                        ? '昇順（古い順）'
                        : '降順（新しい順）',
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
                  title: const Text('履歴削除時に確認する'),
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
                    '履歴をすべて削除',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _confirmClearHistory(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _themeLabel(AppThemeSelection value) => switch (value) {
  AppThemeSelection.system => '端末に合わせる',
  AppThemeSelection.light => '白',
  AppThemeSelection.gray => 'グレー',
  AppThemeSelection.dark => '黒',
};

String _roundingLabel(CalculatorRoundingMode value) => switch (value) {
  CalculatorRoundingMode.halfUp => '四捨五入',
  CalculatorRoundingMode.ceiling => '切上げ',
  CalculatorRoundingMode.floor => '切捨て',
};
