import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';

Future<TestGesture> _startLongPress(
  WidgetTester tester,
  Offset position,
) async {
  final gesture = await tester.startGesture(position);
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
  return gesture;
}

Future<void> _pumpCalculator(
  WidgetTester tester,
  CalculatorController controller, {
  TargetPlatform platform = TargetPlatform.iOS,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      home: CalculatorScreen(controller: controller),
    ),
  );
  await tester.pump();
}

Offset _textCaretGlobalPosition(
  WidgetTester tester,
  Finder finder,
  int textOffset,
) {
  final widget = tester.widget<Text>(finder);
  final text = widget.data ?? widget.textSpan!.toPlainText();
  final style = widget.style ?? (widget.textSpan as TextSpan?)?.style;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final rect = tester.getRect(finder);
  final caret = painter.getOffsetForCaret(
    TextPosition(offset: textOffset),
    Rect.zero,
  );
  return Offset(
    rect.left + caret.dx * rect.width / painter.width,
    rect.center.dy,
  );
}

void main() {
  testWidgets('通常式を先頭から末尾まで長押しドラッグし拡大鏡を閉じる', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('12345+67890');
    await _pumpCalculator(tester, controller);

    final textRect = tester.getRect(find.textContaining('12345'));
    final gesture = await _startLongPress(
      tester,
      Offset(textRect.left + 1, textRect.center.dy),
    );

    expect(find.byKey(const Key('calculatorMagnifier')), findsOneWidget);
    expect(find.byType(CupertinoTextMagnifier), findsOneWidget);
    expect(controller.expressionPosition, const RawExpressionPosition(0));

    final expressionRect = tester.getRect(
      find.byKey(const Key('expressionText')),
    );
    await gesture.moveTo(Offset(expressionRect.right - 1, textRect.center.dy));
    await tester.pump();
    expect(
      controller.expressionPosition,
      RawExpressionPosition(controller.expression.length),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calculatorMagnifier')), findsNothing);
    expect(find.text('コピー'), findsNothing);
  });

  testWidgets('通常式を末尾から先頭へ逆方向ドラッグして入力位置を確定する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('12345');
    await _pumpCalculator(tester, controller);
    final rect = tester.getRect(find.text('12345'));

    final gesture = await _startLongPress(
      tester,
      Offset(rect.right - 1, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 1, rect.center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.expressionPosition, const RawExpressionPosition(0));
    controller.press('9');
    expect(controller.expression, '912345');
  });

  testWidgets('表示用空白を含む演算子の前後へドラッグできる', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('12+34');
    await _pumpCalculator(tester, controller);
    final text = find.text('12 + 34');
    final beforeOperator = _textCaretGlobalPosition(tester, text, 3);
    final afterOperator = _textCaretGlobalPosition(tester, text, 5);

    final gesture = await _startLongPress(tester, beforeOperator);
    expect(controller.expressionPosition, const RawExpressionPosition(2));

    await gesture.moveTo(afterOperator);
    await tester.pump();
    expect(controller.expressionPosition, const RawExpressionPosition(3));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('演算子・括弧・関数を含む縮小式でもドラッグ位置をrawへ変換する', (tester) async {
    final controller = CalculatorController();
    controller.insertFunction('sin');
    controller.pasteAtCaret('12345678901234567890');
    controller.press('()');
    controller.press('+');
    controller.press('3');
    await _pumpCalculator(tester, controller);

    final firstLine = tester.getRect(find.byKey(const Key('expressionLine-0')));
    var lastLineIndex = 0;
    while (find
        .byKey(Key('expressionLine-${lastLineIndex + 1}'))
        .evaluate()
        .isNotEmpty) {
      lastLineIndex++;
    }
    final lastLine = tester.getRect(
      find.byKey(Key('expressionLine-$lastLineIndex')),
    );
    final gesture = await _startLongPress(
      tester,
      Offset(firstLine.center.dx, firstLine.center.dy),
    );
    await gesture.moveTo(Offset(firstLine.left + 1, firstLine.center.dy));
    await tester.pump();
    expect(controller.caretPosition, lessThan(controller.expression.length));
    await gesture.moveTo(Offset(lastLine.right - 1, lastLine.center.dy));
    await tester.pump();
    expect(controller.caretPosition, controller.expression.length);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('分子から分母へ長押しドラッグして構造化位置を維持する', (tester) async {
    final controller = CalculatorController();
    for (final key in ['a/b', '1', '2', 'a/b', '3', '4']) {
      controller.press(key);
    }
    final marker = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single
        .marker;
    await _pumpCalculator(tester, controller);

    final numerator = tester.getRect(
      find.byKey(const Key('fractionNumeratorField')),
    );
    final denominator = tester.getRect(
      find.byKey(const Key('fractionDenominatorField')),
    );
    final gesture = await _startLongPress(tester, numerator.center);
    expect(
      controller.expressionPosition,
      isA<FractionExpressionPosition>()
          .having((value) => value.marker, 'marker', marker)
          .having((value) => value.field, 'field', FractionField.numerator),
    );

    await gesture.moveTo(denominator.center);
    await tester.pump();
    expect(
      controller.expressionPosition,
      isA<FractionExpressionPosition>()
          .having((value) => value.marker, 'marker', marker)
          .having((value) => value.field, 'field', FractionField.denominator),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('帯分数整数部と分数前後を長押しドラッグで移動できる', (tester) async {
    final controller = CalculatorController();
    for (final key in ['2', '0', 'a/b', '1', '2', 'a/b', '3', '4']) {
      controller.press(key);
    }
    final marker = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single
        .marker;
    await _pumpCalculator(tester, controller);

    final whole = tester.getRect(
      find.byKey(const Key('mixedFractionWholeNumber')),
    );
    final after = tester.getRect(find.byKey(const Key('fractionAfterTapArea')));
    final before = tester.getRect(
      find.byKey(const Key('fractionBeforeTapArea')),
    );
    final gesture = await _startLongPress(tester, whole.center);
    expect(
      controller.expressionPosition,
      isA<FractionExpressionPosition>().having(
        (value) => value.field,
        'field',
        FractionField.wholeNumber,
      ),
    );

    await gesture.moveTo(after.center);
    await tester.pump();
    expect(
      controller.expressionPosition,
      RawExpressionPosition(controller.expression.indexOf(marker) + 1),
    );
    await gesture.moveTo(before.center);
    await tester.pump();
    expect(
      controller.expressionPosition,
      RawExpressionPosition(controller.expression.indexOf(marker)),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('通常式と複数分数の間を長押しドラッグで往復できる', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('9×');
    for (final key in [
      'a/b',
      '1',
      'a/b',
      '2',
      'a/b',
      '+',
      'a/b',
      '3',
      'a/b',
      '4',
      'a/b',
    ]) {
      controller.press(key);
    }
    controller.pasteAtCaret('×8');
    final markers = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .map((segment) => segment.marker)
        .toList();
    await _pumpCalculator(tester, controller);

    final expression = find.byKey(const Key('expressionText'));
    final leadingText = tester.getRect(
      find.descendant(of: expression, matching: find.textContaining('9')),
    );
    final secondNumerator = tester.getRect(
      find.byKey(const Key('fractionNumeratorField')).at(1),
    );
    final trailingText = tester.getRect(
      find.descendant(of: expression, matching: find.textContaining('8')),
    );
    final gesture = await _startLongPress(tester, leadingText.center);

    await gesture.moveTo(secondNumerator.center);
    await tester.pump();
    expect(
      controller.expressionPosition,
      isA<FractionExpressionPosition>()
          .having((value) => value.marker, 'marker', markers.last)
          .having((value) => value.field, 'field', FractionField.numerator),
    );

    await gesture.moveTo(trailingText.center);
    await tester.pump();
    expect(controller.expressionPosition, isA<RawExpressionPosition>());
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('AndroidではMaterial拡大鏡を使用する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123');
    await _pumpCalculator(tester, controller, platform: TargetPlatform.android);
    final rect = tester.getRect(find.text('123'));
    final gesture = await _startLongPress(tester, rect.center);

    expect(find.byKey(const Key('calculatorMagnifier')), findsOneWidget);
    expect(find.byType(TextMagnifier), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('ダークテーマでもiOS拡大鏡を表示して画面端で切れない', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = CalculatorController()
      ..pasteAtCaret('12345678901234567890');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(platform: TargetPlatform.iOS),
        home: CalculatorScreen(controller: controller),
      ),
    );
    await tester.pump();
    final expressionRect = tester.getRect(
      find.byKey(const Key('expressionText')),
    );
    final gesture = await _startLongPress(
      tester,
      Offset(expressionRect.right - 1, expressionRect.top + 4),
    );

    expect(find.byType(CupertinoTextMagnifier), findsOneWidget);
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
