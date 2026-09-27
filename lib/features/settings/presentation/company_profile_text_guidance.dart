import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/presentation/text_guidance_metrics.dart';
import '../domain/company_profile.dart';

class CompanyProfileTextGuidanceMetrics {
  const CompanyProfileTextGuidanceMetrics({
    required this.characters,
    required this.lines,
    required this.longestLineCharacters,
    required this.characterLimit,
    required this.lineLimit,
  });

  factory CompanyProfileTextGuidanceMetrics.evaluate(
    String value,
    AppLanguage language,
    CompanyProfileSection section,
  ) {
    final metrics = TextGuidanceMetrics.fromText(value);
    return CompanyProfileTextGuidanceMetrics(
      characters: metrics.characters,
      lines: metrics.lines,
      longestLineCharacters: metrics.longestLineCharacters,
      characterLimit: companyProfileCharacterLimit(language, section),
      lineLimit: 1,
    );
  }

  final int characters;
  final int lines;
  final int longestLineCharacters;
  final int characterLimit;
  final int lineLimit;

  bool get exceeded => characters > characterLimit || lines > lineLimit;
}

int companyProfileCharacterLimit(
  AppLanguage language,
  CompanyProfileSection section,
) {
  if (section == CompanyProfileSection.postalCode ||
      section == CompanyProfileSection.phoneNumber) {
    return 24;
  }
  return switch (language) {
    AppLanguage.japanese ||
    AppLanguage.simplifiedChinese ||
    AppLanguage.traditionalChinese => 14,
    AppLanguage.myanmar => 20,
    AppLanguage.english ||
    AppLanguage.vietnamese ||
    AppLanguage.indonesian ||
    AppLanguage.filipino => 24,
  };
}

class CompanyProfileTextGuidance extends StatelessWidget {
  const CompanyProfileTextGuidance({
    required this.controller,
    required this.section,
    super.key,
  });

  final TextEditingController controller;
  final CompanyProfileSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final metrics = CompanyProfileTextGuidanceMetrics.evaluate(
          controller.text,
          l10n.appLanguage,
          section,
        );
        final color = metrics.exceeded
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;
        final style = theme.textTheme.bodySmall?.copyWith(color: color);
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                key: Key('companyProfileTextCounter-${section.name}'),
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 2,
                children: [
                  Text(
                    l10n.estimateTextCharacterCounter(
                      metrics.characters,
                      metrics.characterLimit,
                    ),
                    style: style,
                  ),
                  Text(
                    l10n.estimateTextLineCounter(
                      metrics.lines,
                      metrics.lineLimit,
                    ),
                    style: style,
                  ),
                ],
              ),
              if (metrics.exceeded) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.companyProfileTextGuidanceExceeded,
                  key: Key('companyProfileTextWarning-${section.name}'),
                  style: style,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
