import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _themeMode = widget.themeMode;

  void _selectTheme(ThemeMode themeMode) {
    setState(() => _themeMode = themeMode);
    widget.onThemeModeChanged(themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('表示', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _ThemeOption(
                  key: const Key('themeModeSystem'),
                  title: '端末設定に合わせる',
                  subtitle: 'iPhone・Androidの表示設定を使用',
                  icon: Icons.brightness_auto_outlined,
                  selected: _themeMode == ThemeMode.system,
                  onTap: () => _selectTheme(ThemeMode.system),
                ),
                const Divider(height: 1),
                _ThemeOption(
                  key: const Key('themeModeLight'),
                  title: 'ライト',
                  subtitle: '白背景で表示',
                  icon: Icons.light_mode_outlined,
                  selected: _themeMode == ThemeMode.light,
                  onTap: () => _selectTheme(ThemeMode.light),
                ),
                const Divider(height: 1),
                _ThemeOption(
                  key: const Key('themeModeDark'),
                  title: 'ダーク',
                  subtitle: '黒背景で表示',
                  icon: Icons.dark_mode_outlined,
                  selected: _themeMode == ThemeMode.dark,
                  onTap: () => _selectTheme(ThemeMode.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}
