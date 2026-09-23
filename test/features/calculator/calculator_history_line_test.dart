import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/theme/app_colors.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_history_line.dart';

void main() {
  testWidgets('短い履歴は式と解を全文表示して右詰めを維持する', (tester) async {
    await _pumpLine(tester, width: 330, expression: '123 + 456', result: '579');

    expect(_visibleText(tester), '123 + 456 = 579');
    final text = _text(tester);
    expect(text.textAlign, TextAlign.right);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.clip);
    expect(text.textSpan?.style?.fontSize, 15);
    expect(_resultSpan(text).style?.color, AppColors.accent);
  });

  testWidgets('長い式は自然な境界から左側だけを省略し解と等号を残す', (tester) async {
    const result = '45,740,479';
    await _pumpLine(
      tester,
      width: _textWidth('… + 7864 × 4896 = $result') + 0.1,
      expression: '12345678901234567890 + 7864 × 4896',
      result: result,
    );

    final visible = _visibleText(tester);
    expect(visible, startsWith('… '));
    expect(visible, contains('× 4896'));
    expect(visible, endsWith(' = 45,740,479'));
    expect(visible, isNot(contains('123456789')));
  });

  testWidgets('式を表示できない幅では省略記号と等号と解を表示する', (tester) async {
    const result = '45,740,479';
    await _pumpLine(
      tester,
      width: 225,
      expression: '123456789 + 7864 × 4896',
      result: result,
    );

    expect(_visibleText(tester), '… = 45,740,479');
  });

  testWidgets('等号を含めると収まらない場合は解全体を優先する', (tester) async {
    const result = '45,740,479';
    await _pumpLine(
      tester,
      width: 165,
      expression: '123456789 + 7864 × 4896',
      result: result,
    );

    expect(_visibleText(tester), '45,740,479');
  });

  testWidgets('解だけでも長い場合は左側を省略して解の右端を残す', (tester) async {
    const result = '12,345,678,901,234,567,890';
    await _pumpLine(tester, width: 100, expression: '1 ÷ 3', result: result);

    final visible = _visibleText(tester);
    expect(visible, startsWith('…'));
    expect(visible, isNot(contains('=')));
    expect(result, endsWith(visible.substring(1)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantic labelは表示を省略しても完全な式と解を保持する', (tester) async {
    const expression = '123456789 + 7864 × 4896';
    const result = '45,740,479';
    await _pumpLine(tester, width: 120, expression: expression, result: result);

    expect(_visibleText(tester), isNot('$expression = $result'));
    expect(
      tester.getSemantics(find.byKey(const Key('testedHistoryLine'))).label,
      '$expression = $result',
    );
  });

  for (final width in [330.0, 275.0]) {
    testWidgets('${width.toInt()}pxの履歴表示領域で横overflowしない', (tester) async {
      await _pumpLine(
        tester,
        width: width,
        expression: '12345678901234567890 + 7864 × 4896',
        result: '45,740,479',
      );

      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.byKey(const Key('calculatorHistoryVisibleText')))
            .width,
        lessThanOrEqualTo(width),
      );
      expect(_visibleText(tester), endsWith('45,740,479'));
    });
  }
}

Future<void> _pumpLine(
  WidgetTester tester, {
  required double width,
  required String expression,
  required String result,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 24,
            child: CalculatorHistoryLine(
              key: const Key('testedHistoryLine'),
              expression: expression,
              result: result,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Text _text(WidgetTester tester) => tester.widget<Text>(
  find.byKey(const Key('calculatorHistoryVisibleText')),
);

String _visibleText(WidgetTester tester) =>
    _text(tester).textSpan!.toPlainText();

TextSpan _resultSpan(Text text) {
  final root = text.textSpan! as TextSpan;
  return root.children!.whereType<TextSpan>().last;
}

double _textWidth(String value) {
  final painter = TextPainter(
    text: TextSpan(text: value, style: const TextStyle(fontSize: 15)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return painter.width;
}
