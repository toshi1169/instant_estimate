import 'package:flutter/material.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_localizations.dart';

enum EstimateTextGuidanceState { normal, caution, exceeded }

class EstimateTextGuidanceMetrics {
  const EstimateTextGuidanceMetrics({
    required this.characters,
    required this.lines,
    required this.longestLineCharacters,
    required this.characterLimit,
    required this.lineLimit,
    required this.state,
  });

  factory EstimateTextGuidanceMetrics.evaluate(
    String value,
    AppLanguage language,
  ) {
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final characters = normalized.characters.length;
    final longestLineCharacters = lines.fold<int>(
      0,
      (longest, line) =>
          line.characters.length > longest ? line.characters.length : longest,
    );

    final isCompactGuidance =
        language == AppLanguage.simplifiedChinese ||
        language == AppLanguage.myanmar;
    final isThirtyCharacterGuidance =
        language == AppLanguage.english ||
        language == AppLanguage.vietnamese ||
        language == AppLanguage.indonesian ||
        language == AppLanguage.filipino;
    final characterLimit = isCompactGuidance
        ? 20
        : isThirtyCharacterGuidance
        ? 30
        : 40;
    final lineLimit = isCompactGuidance ? 1 : 2;

    if (isCompactGuidance) {
      return EstimateTextGuidanceMetrics(
        characters: characters,
        lines: lines.length,
        longestLineCharacters: longestLineCharacters,
        characterLimit: characterLimit,
        lineLimit: lineLimit,
        state: lines.length >= 2 || characters >= 21
            ? EstimateTextGuidanceState.exceeded
            : EstimateTextGuidanceState.normal,
      );
    }

    final exceeded =
        lines.length >= 3 ||
        characters > characterLimit ||
        longestLineCharacters >= 29;
    final normal = lines.length == 1 && longestLineCharacters <= 20;
    return EstimateTextGuidanceMetrics(
      characters: characters,
      lines: lines.length,
      longestLineCharacters: longestLineCharacters,
      characterLimit: characterLimit,
      lineLimit: lineLimit,
      state: exceeded
          ? EstimateTextGuidanceState.exceeded
          : normal
          ? EstimateTextGuidanceState.normal
          : EstimateTextGuidanceState.caution,
    );
  }

  final int characters;
  final int lines;
  final int longestLineCharacters;
  final int characterLimit;
  final int lineLimit;
  final EstimateTextGuidanceState state;
}

class EstimateTextGuidance extends StatelessWidget {
  const EstimateTextGuidance({
    required this.controller,
    required this.counterKey,
    super.key,
  });

  final TextEditingController controller;
  final Key counterKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final metrics = EstimateTextGuidanceMetrics.evaluate(
          controller.text,
          l10n.appLanguage,
        );
        final color = switch (metrics.state) {
          EstimateTextGuidanceState.normal =>
            theme.colorScheme.onSurfaceVariant,
          EstimateTextGuidanceState.caution => theme.colorScheme.tertiary,
          EstimateTextGuidanceState.exceeded => theme.colorScheme.error,
        };
        final style = theme.textTheme.bodySmall?.copyWith(color: color);
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                key: counterKey,
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
              if (metrics.state == EstimateTextGuidanceState.exceeded) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.estimateTextGuidanceExceeded,
                  key: ValueKey('${counterKey.toString()}-warning'),
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
