import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class ResultDisplaySettingsScreen extends StatefulWidget {
  const ResultDisplaySettingsScreen({
    required this.improperFractionEnabled,
    required this.mixedFractionEnabled,
    required this.remainderEnabled,
    required this.onImproperFractionChanged,
    required this.onMixedFractionChanged,
    required this.onRemainderChanged,
    super.key,
  });

  final bool improperFractionEnabled;
  final bool mixedFractionEnabled;
  final bool remainderEnabled;
  final ValueChanged<bool> onImproperFractionChanged;
  final ValueChanged<bool> onMixedFractionChanged;
  final ValueChanged<bool> onRemainderChanged;

  @override
  State<ResultDisplaySettingsScreen> createState() =>
      _ResultDisplaySettingsScreenState();
}

class _ResultDisplaySettingsScreenState
    extends State<ResultDisplaySettingsScreen> {
  late bool _improperFractionEnabled = widget.improperFractionEnabled;
  late bool _mixedFractionEnabled = widget.mixedFractionEnabled;
  late bool _remainderEnabled = widget.remainderEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.resultDisplaySettings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    key: const Key('decimalResultSetting'),
                    leading: const Icon(Icons.numbers),
                    title: Text(strings.decimalResult),
                    subtitle: Text(strings.alwaysEnabled),
                    trailing: const Icon(Icons.check),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('improperFractionResultSetting'),
                    secondary: const Icon(Icons.horizontal_rule),
                    title: Text(strings.improperFractionResult),
                    value: _improperFractionEnabled,
                    onChanged: (value) {
                      setState(() => _improperFractionEnabled = value);
                      widget.onImproperFractionChanged(value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('remainderResultSetting'),
                    secondary: const Icon(Icons.more_horiz),
                    title: Text(strings.remainderResult),
                    value: _remainderEnabled,
                    onChanged: (value) {
                      setState(() => _remainderEnabled = value);
                      widget.onRemainderChanged(value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    key: const Key('mixedFractionResultSetting'),
                    secondary: const Icon(Icons.format_list_numbered),
                    title: Text(strings.mixedFractionResult),
                    value: _mixedFractionEnabled,
                    onChanged: (value) {
                      setState(() => _mixedFractionEnabled = value);
                      widget.onMixedFractionChanged(value);
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
