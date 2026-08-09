import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class OccupationSelectionScreen extends StatefulWidget {
  const OccupationSelectionScreen({required this.onCompleted, super.key});

  final Future<void> Function(String occupation) onCompleted;

  @override
  State<OccupationSelectionScreen> createState() =>
      _OccupationSelectionScreenState();
}

class _OccupationSelectionScreenState extends State<OccupationSelectionScreen> {
  static const _occupations = <String>[
    '建築監督',
    '土木監督',
    '建築基礎',
    '外構',
    '内装',
    '多能工',
    'その他',
  ];

  String? _selectedOccupation;
  bool _isSaving = false;

  Future<void> _continue() async {
    final occupation = _selectedOccupation;
    if (occupation == null || _isSaving) return;

    setState(() => _isSaving = true);
    await widget.onCompleted(occupation);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.occupationTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.occupationPrompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                strings.occupationGuidance,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RadioGroup<String>(
                  groupValue: _selectedOccupation,
                  onChanged: _isSaving
                      ? (_) {}
                      : (value) {
                          setState(() => _selectedOccupation = value);
                        },
                  child: ListView.separated(
                    itemCount: _occupations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final occupation = _occupations[index];
                      return RadioListTile<String>(
                        value: occupation,
                        title: Text(strings.occupation(occupation)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedOccupation == null ? null : _continue,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(strings.startWithOccupation),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
