import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../application/calculator_controller.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({this.controller, super.key});

  final CalculatorController? controller;

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
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final CalculatorController _controller =
      widget.controller ?? CalculatorController();
  late final bool _ownsController = widget.controller == null;

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _pressKey(_CalculatorKey key) {
    if (const {_KeyKind.menu, _KeyKind.settings}.contains(key.kind)) {
      return;
    }
    _controller.press(key.label);
  }

  Future<void> _showCalculationMenu() async {
    final action = await showModalBottomSheet<_CalculationMenuAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _CalculationMenuSheet(),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _CalculationMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: _controller.clipboardText));
        _showMessage('コピーしました');
      case _CalculationMenuAction.cut:
        await Clipboard.setData(
          ClipboardData(text: _controller.displayExpression),
        );
        _controller.clear();
        _showMessage('カットしました');
      case _CalculationMenuAction.paste:
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (!mounted) return;
        final pasted = _controller.pasteAtCaret(data?.text ?? '');
        _showMessage(pasted ? 'ペーストしました' : '貼り付けできる計算式がありません');
      case _CalculationMenuAction.clear:
        _controller.clear();
      case _CalculationMenuAction.sendToEstimate:
        await _showEstimateTransferSheet();
    }
  }

  Future<void> _showEstimateTransferSheet() async {
    if (_controller.expression.isEmpty) {
      _showMessage('見積へ送る計算式がありません');
      return;
    }

    final request = await showModalBottomSheet<_EstimateTransferRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EstimateTransferSheet(controller: _controller),
    );
    if (request == null || !mounted) return;

    _showMessage(
      '「${request.content.label}」を「${request.destination.label}」へ送る準備をしました',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
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
                      child: _HistoryPanel(
                        key: const Key('historyPanel'),
                        history: _controller.history,
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      flex: 20,
                      child: _ExpressionPanel(
                        controller: _controller,
                        onLongPress: _showCalculationMenu,
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      flex: 56,
                      child: _Keypad(
                        gap: gap,
                        canCycleFraction: _controller.canCycleFraction,
                        onPressed: _pressKey,
                        onBackLongPressed: _controller.clearLeftOfCaret,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
  const _HistoryPanel({required this.history, super.key});

  final List<CalculationHistoryEntry> history;

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
        itemCount: history.length,
        itemBuilder: (context, reversedIndex) {
          final index = history.length - 1 - reversedIndex;
          final item = history[index];
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
                        TextSpan(text: '${item.expression} = '),
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
  const _ExpressionPanel({required this.controller, required this.onLongPress});

  final CalculatorController controller;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      key: const Key('calculationSpace'),
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: DecoratedBox(
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
              Expanded(child: _EditableExpressionLine(controller: controller)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    controller.state == CalculatorState.error
                        ? controller.errorMessage!
                        : '=  ${controller.result}',
                    key: const Key('resultText'),
                    maxLines: 1,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: controller.state == CalculatorState.error
                          ? theme.colorScheme.error
                          : AppColors.accent,
                      fontSize: controller.state == CalculatorState.error
                          ? 23
                          : 42,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CalculationMenuAction { copy, cut, paste, clear, sendToEstimate }

class _CalculationMenuSheet extends StatelessWidget {
  const _CalculationMenuSheet();

  @override
  Widget build(BuildContext context) {
    const items = <(_CalculationMenuAction, IconData, String)>[
      (_CalculationMenuAction.copy, Icons.copy_outlined, 'コピー'),
      (_CalculationMenuAction.cut, Icons.content_cut, 'カット'),
      (_CalculationMenuAction.paste, Icons.content_paste, 'ペースト'),
      (_CalculationMenuAction.clear, Icons.delete_outline, '消去'),
      (
        _CalculationMenuAction.sendToEstimate,
        Icons.receipt_long_outlined,
        '見積へ送る',
      ),
    ];

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final item in items)
            ListTile(
              leading: Icon(item.$2),
              title: Text(item.$3),
              onTap: () => Navigator.of(context).pop(item.$1),
            ),
        ],
      ),
    );
  }
}

enum _EstimateContent {
  expression('式'),
  result('解'),
  expressionAndResult('式＋解');

  const _EstimateContent(this.label);
  final String label;
}

enum _EstimateDestination {
  name('名称'),
  specification('仕様'),
  quantity('数量'),
  description('摘要');

  const _EstimateDestination(this.label);
  final String label;
}

class _EstimateTransferRequest {
  const _EstimateTransferRequest({
    required this.content,
    required this.destination,
  });

  final _EstimateContent content;
  final _EstimateDestination destination;
}

class _EstimateTransferSheet extends StatefulWidget {
  const _EstimateTransferSheet({required this.controller});

  final CalculatorController controller;

  @override
  State<_EstimateTransferSheet> createState() => _EstimateTransferSheetState();
}

class _EstimateTransferSheetState extends State<_EstimateTransferSheet> {
  _EstimateContent _content = _EstimateContent.expressionAndResult;
  _EstimateDestination _destination = _EstimateDestination.description;

  String get _preview {
    return switch (_content) {
      _EstimateContent.expression => widget.controller.estimateExpressionText,
      _EstimateContent.result => widget.controller.estimateResultText,
      _EstimateContent.expressionAndResult =>
        '${widget.controller.estimateExpressionText} = '
            '${widget.controller.estimateResultText}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('見積へ送る', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('送信内容'),
            const SizedBox(height: 8),
            SegmentedButton<_EstimateContent>(
              segments: [
                for (final content in _EstimateContent.values)
                  ButtonSegment(value: content, label: Text(content.label)),
              ],
              selected: {_content},
              onSelectionChanged: (selection) {
                setState(() => _content = selection.first);
              },
            ),
            const SizedBox(height: 16),
            const Text('送信先'),
            const SizedBox(height: 8),
            DropdownButtonFormField<_EstimateDestination>(
              initialValue: _destination,
              items: [
                for (final destination in _EstimateDestination.values)
                  DropdownMenuItem(
                    value: destination,
                    child: Text(destination.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _destination = value);
              },
            ),
            const SizedBox(height: 16),
            Text('送信内容の確認', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_preview),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _EstimateTransferRequest(
                          content: _content,
                          destination: _destination,
                        ),
                      );
                    },
                    child: const Text('次へ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableExpressionLine extends StatelessWidget {
  const _EditableExpressionLine({required this.controller});

  final CalculatorController controller;
  static const double _expressionFontSize = 42;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = controller.formattedExpression;

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = theme.textTheme.headlineMedium!.copyWith(
          fontSize: _expressionFontSize,
          fontWeight: FontWeight.w400,
        );
        final painter = TextPainter(
          text: TextSpan(text: formatted.text, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        void moveCaret(TapDownDetails details) {
          final startX = constraints.maxWidth - painter.width;
          final localX = (details.localPosition.dx - startX).clamp(
            0.0,
            painter.width,
          );
          final position = painter.getPositionForOffset(Offset(localX, 0));
          controller.moveCaretToDisplayOffset(position.offset);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: moveCaret,
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text.rich(
                  key: const Key('expressionText'),
                  TextSpan(
                    style: style,
                    children: [
                      for (final segment in controller.displaySegments)
                        switch (segment) {
                          ExpressionTextSegment() => TextSpan(
                            text: segment.text,
                          ),
                          ExpressionCaretSegment() => const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2),
                              child: SizedBox(
                                key: Key('calculatorCaret'),
                                width: 2,
                                height: 46,
                                child: ColoredBox(color: AppColors.accent),
                              ),
                            ),
                          ),
                          ExpressionFractionSegment() => WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _InlineFraction(
                              segment: segment,
                              fontSize: _expressionFontSize,
                              onWholeNumberTap: () {
                                controller.moveCaretBeforeFraction(
                                  segment.marker,
                                );
                              },
                              onFieldTap: (field) {
                                controller.activateFraction(
                                  segment.marker,
                                  field,
                                );
                              },
                            ),
                          ),
                        },
                    ],
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InlineFraction extends StatelessWidget {
  const _InlineFraction({
    required this.segment,
    required this.fontSize,
    required this.onWholeNumberTap,
    required this.onFieldTap,
  });

  final ExpressionFractionSegment segment;
  final double fontSize;
  final VoidCallback onWholeNumberTap;
  final ValueChanged<FractionField> onFieldTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final fractionFontSize = fontSize;
    final fractionWidth = _fractionWidth(
      context,
      values: [segment.numerator, segment.denominator],
      fontSize: fractionFontSize,
      reserveCaret: segment.activeField != null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (segment.wholeNumber.isNotEmpty) ...[
            GestureDetector(
              key: const Key('mixedFractionWholeNumber'),
              behavior: HitTestBehavior.opaque,
              onTap: onWholeNumberTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  segment.wholeNumber,
                  style: TextStyle(color: textColor, fontSize: fontSize),
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
          SizedBox(
            width: fractionWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FractionFieldDisplay(
                  value: segment.numerator,
                  active: segment.activeField == FractionField.numerator,
                  fontSize: fractionFontSize,
                  onTap: () => onFieldTap(FractionField.numerator),
                ),
                Container(
                  width: fractionWidth,
                  height: 1.5,
                  color: AppColors.accent,
                ),
                _FractionFieldDisplay(
                  value: segment.denominator,
                  active: segment.activeField == FractionField.denominator,
                  fontSize: fractionFontSize,
                  onTap: () => onFieldTap(FractionField.denominator),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _fractionWidth(
    BuildContext context, {
    required List<String> values,
    required double fontSize,
    required bool reserveCaret,
  }) {
    final style = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: fontSize,
      height: 1,
    );
    var widest = 0.0;
    for (final value in values) {
      final painter = TextPainter(
        text: TextSpan(text: value.isEmpty ? '□' : value, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
    }
    return (widest + (reserveCaret ? 8 : 0) + 8).clamp(34.0, 240.0);
  }
}

class _FractionFieldDisplay extends StatelessWidget {
  const _FractionFieldDisplay({
    required this.value,
    required this.active,
    required this.fontSize,
    required this.onTap,
  });

  final String value;
  final bool active;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: fontSize * 1.05,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value.isEmpty ? '□' : value,
              style: TextStyle(
                color: value.isEmpty
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : textColor,
                fontSize: fontSize,
                height: 1,
              ),
            ),
            if (active)
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: SizedBox(
                  width: 1.5,
                  height: 26,
                  child: ColoredBox(color: AppColors.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.gap,
    required this.canCycleFraction,
    required this.onPressed,
    required this.onBackLongPressed,
  });

  final double gap;
  final bool canCycleFraction;
  final ValueChanged<_CalculatorKey> onPressed;
  final VoidCallback onBackLongPressed;

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
        final keyData = CalculatorScreen._keys[index];
        return _KeyButton(
          keyData: keyData,
          useFractionToggleColor:
              keyData.kind == _KeyKind.fractionToggle && canCycleFraction,
          onPressed: () => onPressed(keyData),
          onLongPressed: keyData.label == '←' ? onBackLongPressed : null,
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.keyData,
    required this.useFractionToggleColor,
    required this.onPressed,
    this.onLongPressed,
  });

  final _CalculatorKey keyData;
  final bool useFractionToggleColor;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGreen = keyData.kind == _KeyKind.operator;
    final isOrange = useFractionToggleColor;

    final backgroundColor = isOrange
        ? AppColors.fractionToggle
        : switch (keyData.kind) {
            _KeyKind.operator || _KeyKind.fractionToggle => AppColors.accent,
            _ => isDark ? AppColors.darkKey : AppColors.lightKey,
          };

    final foregroundColor = isGreen || isOrange
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      label: keyData.semanticLabel,
      child: FilledButton(
        onPressed: onPressed,
        onLongPress: onLongPressed,
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
