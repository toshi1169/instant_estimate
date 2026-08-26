import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class ButtonSettingsScreen extends StatefulWidget {
  const ButtonSettingsScreen({
    required this.tapSoundEnabled,
    required this.hapticsEnabled,
    required this.onTapSoundChanged,
    required this.onHapticsChanged,
    super.key,
  });

  final bool tapSoundEnabled;
  final bool hapticsEnabled;
  final ValueChanged<bool> onTapSoundChanged;
  final ValueChanged<bool> onHapticsChanged;

  @override
  State<ButtonSettingsScreen> createState() => _ButtonSettingsScreenState();
}

class _ButtonSettingsScreenState extends State<ButtonSettingsScreen> {
  late bool _tapSoundEnabled = widget.tapSoundEnabled;
  late bool _hapticsEnabled = widget.hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.buttonSettings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('calculatorTapSoundSetting'),
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: Text(strings.calculatorTapSound),
                    value: _tapSoundEnabled,
                    onChanged: (value) {
                      setState(() => _tapSoundEnabled = value);
                      widget.onTapSoundChanged(value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('calculatorHapticsSetting'),
                    secondary: const Icon(Icons.vibration_outlined),
                    title: Text(strings.calculatorTapHaptics),
                    value: _hapticsEnabled,
                    onChanged: (value) {
                      setState(() => _hapticsEnabled = value);
                      widget.onHapticsChanged(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
