import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  static const _history = <({String expression, String result})>[
    (expression: '12.8 ÷ 4 =', result: '3.2'),
    (expression: '79.05 × 0.03 =', result: '2.3715'),
    (expression: '(9.3 × 8.5) × 0.5 =', result: '39.525'),
    (expression: '79.05 × 0.05 =', result: '3.9525'),
    (expression: '4 × 580 =', result: '2,320'),
  ];

  static const _keys = <_CalculatorKey>[
    _CalculatorKey.menu(),
    _CalculatorKey.text('^'),
    _CalculatorKey.settings(),
    _CalculatorKey.operator('←'),
    _CalculatorKey.fraction(),
    _CalculatorKey.text('()'),
    _CalculatorKey.text('%'),
    _CalculatorKey.operator('÷'),
    _CalculatorKey.text('7'),
    _CalculatorKey.text('8'),
    _CalculatorKey.text('9'),
    _CalculatorKey.operator('×'),
    _CalculatorKey.text('4'),
    _CalculatorKey.text('5'),
    _CalculatorKey.text('6'),
    _CalculatorKey.operator('−'),
    _CalculatorKey.text('1'),
    _CalculatorKey.text('2'),
    _CalculatorKey.text('3'),
    _CalculatorKey.operator('+'),
    _CalculatorKey.text('0'),
    _CalculatorKey.text('00'),
    _CalculatorKey.text('.'),
    _CalculatorKey.fractionToggle('='),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final gap = compact ? 4.0 : 6.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(gap, 4, gap, gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AdBanner(height: compact ? 50 : 58),
                  SizedBox(height: gap),
                  Expanded(
                    flex: 18,
                    child: const _HistoryPanel(key: Key('historyPanel')),
                  ),
                  SizedBox(height: gap),
                  Expanded(flex: 20, child: const _ExpressionPanel()),
                  SizedBox(height: gap),
                  Expanded(flex: 56, child: _Keypad(gap: gap)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              decoration: const BoxDecoration(
                color: AppColors.adLabelBackground,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
              ),
              alignment: Alignment.center,
              child: const Text(
                '広告\nスペース',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  height: 1.15,
                  fontSize: 13,
                ),
              ),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'プライムで広告を非表示に！',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size(74, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  '今すぐ\nアップグレード',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, height: 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.darkHistory
            : AppColors.lightHistory,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        itemCount: CalculatorScreen._history.length,
        itemBuilder: (context, reversedIndex) {
          final index = CalculatorScreen._history.length - 1 - reversedIndex;
          final item = CalculatorScreen._history[index];
          return SizedBox(
            height: 24,
            child: Row(
              children: [
                Icon(
                  Icons.more_vert,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${item.expression} '),
                        TextSpan(
                          text: item.result,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExpressionPanel extends StatelessWidget {
  const _ExpressionPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '(12.5 + 3.75) × 2.8 ÷ 4',
                maxLines: 1,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '=  11.375',
                maxLines: 1,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.accent,
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.gap});

  final double gap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: CalculatorScreen._keys.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        childAspectRatio: 1.52,
      ),
      itemBuilder: (context, index) {
        return _KeyButton(keyData: CalculatorScreen._keys[index]);
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.keyData});

  final _CalculatorKey keyData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGreen = keyData.kind == _KeyKind.operator;
    final isOrange = keyData.kind == _KeyKind.fractionToggle;

    final backgroundColor = switch (keyData.kind) {
      _KeyKind.operator => AppColors.accent,
      _KeyKind.fractionToggle => AppColors.fractionToggle,
      _ => isDark ? AppColors.darkKey : AppColors.lightKey,
    };

    final foregroundColor = isGreen || isOrange
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      label: keyData.semanticLabel,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: keyData.kind == _KeyKind.menu
                ? const BorderSide(color: AppColors.accent, width: 2)
                : BorderSide(
                    color: isDark
                        ? AppColors.darkKeyBorder
                        : AppColors.lightKeyBorder,
                  ),
          ),
        ),
        child: _KeyContent(keyData: keyData),
      ),
    );
  }
}

class _KeyContent extends StatelessWidget {
  const _KeyContent({required this.keyData});

  final _CalculatorKey keyData;

  @override
  Widget build(BuildContext context) {
    return switch (keyData.kind) {
      _KeyKind.menu => const Text(
        '•••',
        style: TextStyle(fontSize: 21, letterSpacing: 2),
      ),
      _KeyKind.settings => const Icon(Icons.settings, size: 29),
      _KeyKind.fraction => const _FractionGlyph(),
      _ => Text(
        keyData.label,
        style: TextStyle(
          fontSize: keyData.label.length > 1 ? 23 : 28,
          fontWeight: FontWeight.w400,
        ),
      ),
    };
  }
}

class _FractionGlyph extends StatelessWidget {
  const _FractionGlyph();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 26,
      height: 42,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('a', style: TextStyle(color: color, fontSize: 16, height: 0.9)),
          Container(
            width: 24,
            height: 1.4,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: color,
          ),
          Text('b', style: TextStyle(color: color, fontSize: 16, height: 0.9)),
        ],
      ),
    );
  }
}

enum _KeyKind { text, menu, settings, fraction, operator, fractionToggle }

class _CalculatorKey {
  const _CalculatorKey._(this.label, this.kind, {this.semanticLabel});

  const _CalculatorKey.text(String label)
    : this._(label, _KeyKind.text, semanticLabel: label);

  const _CalculatorKey.menu()
    : this._('…', _KeyKind.menu, semanticLabel: 'メニュー');

  const _CalculatorKey.settings()
    : this._('⚙', _KeyKind.settings, semanticLabel: '設定');

  const _CalculatorKey.fraction()
    : this._('a/b', _KeyKind.fraction, semanticLabel: 'a/b');

  const _CalculatorKey.operator(String label)
    : this._(label, _KeyKind.operator, semanticLabel: label);

  const _CalculatorKey.fractionToggle(String label)
    : this._(label, _KeyKind.fractionToggle, semanticLabel: label);

  final String label;
  final _KeyKind kind;
  final String? semanticLabel;
}
