import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({
    required this.selectedLanguage,
    required this.onCompleted,
    super.key,
  });

  final AppLanguage selectedLanguage;
  final Future<void> Function(AppLanguage language) onCompleted;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late AppLanguage _selected = widget.selectedLanguage;
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await widget.onCompleted(_selected);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.chooseLanguage)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.languageGuidance,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: RadioGroup<AppLanguage>(
                    groupValue: _selected,
                    onChanged: _isSaving
                        ? (_) {}
                        : (value) {
                            if (value != null) {
                              setState(() => _selected = value);
                            }
                          },
                    child: Column(
                      children: [
                        RadioListTile<AppLanguage>(
                          key: const Key('languageJapanese'),
                          value: AppLanguage.japanese,
                          title: const Text('日本語'),
                        ),
                        RadioListTile<AppLanguage>(
                          key: const Key('languageEnglish'),
                          value: AppLanguage.english,
                          title: const Text('English'),
                        ),
                        RadioListTile<AppLanguage>(
                          key: const Key('languageSimplifiedChinese'),
                          value: AppLanguage.simplifiedChinese,
                          title: const Text('简体中文'),
                        ),
                        RadioListTile<AppLanguage>(
                          key: const Key('languageTraditionalChinese'),
                          value: AppLanguage.traditionalChinese,
                          title: const Text('繁體中文'),
                        ),
                        RadioListTile<AppLanguage>(
                          key: const Key('languageVietnamese'),
                          value: AppLanguage.vietnamese,
                          title: const Text('Tiếng Việt'),
                        ),
                        RadioListTile<AppLanguage>(
                          key: const Key('languageIndonesian'),
                          value: AppLanguage.indonesian,
                          title: const Text('Bahasa Indonesia'),
                        ),
                        RadioListTile<AppLanguage>(
                          key: const Key('languageFilipino'),
                          value: AppLanguage.filipino,
                          title: const Text('Filipino'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FilledButton(
                key: const Key('completeLanguageSelection'),
                onPressed: _isSaving ? null : _continue,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
