import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/occupation.dart';

class OccupationSelectionScreen extends StatefulWidget {
  const OccupationSelectionScreen({
    required this.onCompleted,
    this.initialOccupation,
    this.isEditing = false,
    super.key,
  });

  final Future<void> Function(String occupation) onCompleted;
  final Occupation? initialOccupation;
  final bool isEditing;

  @override
  State<OccupationSelectionScreen> createState() =>
      _OccupationSelectionScreenState();
}

class _OccupationSelectionScreenState extends State<OccupationSelectionScreen> {
  late Occupation? _selectedOccupation = widget.initialOccupation;
  bool _isSaving = false;

  Future<void> _continue() async {
    final occupation = _selectedOccupation;
    if (occupation == null || _isSaving) return;

    setState(() => _isSaving = true);
    await widget.onCompleted(occupation.storageKey);
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
                child: RadioGroup<Occupation>(
                  groupValue: _selectedOccupation,
                  onChanged: _isSaving
                      ? (_) {}
                      : (value) {
                          setState(() => _selectedOccupation = value);
                        },
                  child: ListView.separated(
                    itemCount: Occupation.values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final occupation = Occupation.values[index];
                      return RadioListTile<Occupation>(
                        value: occupation,
                        title: Text(strings.occupation(occupation.legacyLabel)),
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
                    : Text(
                        widget.isEditing
                            ? strings.saveOccupation
                            : strings.startWithOccupation,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
