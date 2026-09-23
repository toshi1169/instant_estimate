import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 電卓上部の履歴を、解の右端を最優先にして1行表示する。
class CalculatorHistoryLine extends StatelessWidget {
  const CalculatorHistoryLine({
    required this.expression,
    required this.result,
    super.key,
  });

  final String expression;
  final String result;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15) ??
        const TextStyle(fontSize: 15);
    final resultStyle = baseStyle.copyWith(color: AppColors.accent);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);
    final fullLabel = '$expression = $result';

    return Semantics(
      label: fullLabel,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final span = _fitHistoryText(
            expression: expression,
            result: result,
            maxWidth: constraints.maxWidth,
            baseStyle: baseStyle,
            resultStyle: resultStyle,
            textDirection: textDirection,
            textScaler: textScaler,
            locale: locale,
          );
          return Text.rich(
            span,
            key: const Key('calculatorHistoryVisibleText'),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: baseStyle,
          );
        },
      ),
    );
  }
}

TextSpan _fitHistoryText({
  required String expression,
  required String result,
  required double maxWidth,
  required TextStyle baseStyle,
  required TextStyle resultStyle,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required Locale? locale,
}) {
  TextSpan span(String leading, [String? answer]) => TextSpan(
    style: baseStyle,
    children: [
      if (leading.isNotEmpty) TextSpan(text: leading),
      if (answer != null) TextSpan(text: answer, style: resultStyle),
    ],
  );

  bool fits(InlineSpan candidate) {
    final painter = TextPainter(
      text: candidate,
      maxLines: 1,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    )..layout();
    return painter.width <= maxWidth;
  }

  final full = span('$expression = ', result);
  if (fits(full)) return full;

  final expressionRunes = expression.runes.toList(growable: false);
  final naturalStarts = <int>[];
  final otherStarts = <int>[];
  for (var index = 1; index < expressionRunes.length; index++) {
    final current = String.fromCharCode(expressionRunes[index]);
    final previous = String.fromCharCode(expressionRunes[index - 1]);
    final isNatural = _isOperator(current) || previous.trim().isEmpty;
    (isNatural ? naturalStarts : otherStarts).add(index);
  }

  TextSpan? fittingSuffix(Iterable<int> starts) {
    for (final start in starts) {
      final suffix = String.fromCharCodes(
        expressionRunes.skip(start),
      ).trimLeft();
      if (suffix.isEmpty) continue;
      final candidate = span('… $suffix = ', result);
      if (fits(candidate)) return candidate;
    }
    return null;
  }

  final naturalSuffix = fittingSuffix(naturalStarts);
  if (naturalSuffix != null) return naturalSuffix;
  final arbitrarySuffix = fittingSuffix(otherStarts);
  if (arbitrarySuffix != null) return arbitrarySuffix;

  final expressionOmitted = span('… = ', result);
  if (fits(expressionOmitted)) return expressionOmitted;

  final resultOnly = span('', result);
  if (fits(resultOnly)) return resultOnly;

  final resultRunes = result.runes.toList(growable: false);
  for (var start = 1; start < resultRunes.length; start++) {
    final suffix = String.fromCharCodes(resultRunes.skip(start));
    final candidate = span('…', suffix);
    if (fits(candidate)) return candidate;
  }

  // 通常の端末幅では到達しないが、極端な制約でも右端を描画基準にする。
  return resultOnly;
}

bool _isOperator(String character) => const {
  '+',
  '-',
  '−',
  '×',
  '÷',
  '*',
  '/',
  '^',
  '%',
  '(',
}.contains(character);
