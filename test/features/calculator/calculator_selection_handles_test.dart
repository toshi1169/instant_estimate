import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';

Future<void> _pumpCalculator(
  WidgetTester tester,
  CalculatorController controller, {
  Size size = const Size(390, 844),
  double textScale = 1,
  TargetPlatform platform = TargetPlatform.iOS,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness, platform: platform),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: CalculatorScreen(controller: controller),
    ),
  );
  await tester.pump();
}

Offset _characterCenter(WidgetTester tester, Finder finder, String target) {
  final widget = tester.widget<Text>(finder);
  final text = widget.data!;
  final index = text.indexOf(target);
  expect(index, isNonNegative);
  final painter = TextPainter(
    text: TextSpan(text: text, style: widget.style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: index, extentOffset: index + 1),
  );
  final rect = tester.getRect(finder);
  final box = boxes.single;
  return Offset(
    rect.left + box.toRect().center.dx * rect.width / painter.width,
    rect.center.dy,
  );
}

Future<void> _doubleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(position);
  await tester.pumpAndSettle();
}

Finder _expressionTextContaining(String value) => find.descendant(
  of: find.byKey(const Key('expressionText')),
  matching: find.byWidgetPredicate(
    (widget) => widget is Text && (widget.data?.contains(value) ?? false),
  ),
);

void _enterFraction(
  CalculatorController controller,
  String numerator,
  String denominator, {
  String wholeNumber = '',
}) {
  for (final digit in wholeNumber.split('')) {
    controller.press(digit);
  }
  controller.press('a/b');
  for (final digit in numerator.split('')) {
    controller.press(digit);
  }
  controller.press('a/b');
  for (final digit in denominator.split('')) {
    controller.press(digit);
  }
  controller.press('a/b');
}

void _expectHandles() {
  expect(
    find.byKey(const Key('calculatorSelectionBaseHandle')),
    findsOneWidget,
  );
  expect(
    find.byKey(const Key('calculatorSelectionExtentHandle')),
    findsOneWidget,
  );
}

void main() {
  testWidgets('ダブルタップした通常式の数値部分だけを選択する', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('123456789+429÷25-54668558');
    await _pumpCalculator(tester, controller);

    final expression = _expressionTextContaining('429');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '429'));

    expect(controller.selectedClipboardText, '429');
    expect(find.byKey(const Key('calculatorCaret')), findsNothing);
    _expectHandles();
    expect(tester.takeException(), isNull);
  });

  testWidgets('小数点を含む数値全体を選択し演算子は選択しない', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+42.75÷5');
    await _pumpCalculator(tester, controller);
    var expression = _expressionTextContaining('42.75');

    await _doubleTapAt(tester, _characterCenter(tester, expression, '42.75'));
    expect(controller.selectedClipboardText, '42.75');

    controller.clearSelection();
    await tester.pump();
    expression = _expressionTextContaining('+');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '+'));
    expect(controller.selection, isNull);
    expect(find.byKey(const Key('calculatorCaret')), findsOneWidget);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
  });

  testWidgets('分子・分母・帯分数整数部をfield内でダブルタップ選択する', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '34', '56', wholeNumber: '12');
    await _pumpCalculator(tester, controller);

    for (final entry in const [
      (Key('mixedFractionWholeNumber'), '12', FractionField.wholeNumber),
      (Key('fractionNumeratorField'), '34', FractionField.numerator),
      (Key('fractionDenominatorField'), '56', FractionField.denominator),
    ]) {
      await _doubleTapAt(tester, tester.getCenter(find.byKey(entry.$1)));
      expect(controller.selectedClipboardText, entry.$2);
      expect(
        controller.selection!.base,
        isA<FractionExpressionPosition>().having(
          (position) => position.field,
          'field',
          entry.$3,
        ),
      );
      _expectHandles();
    }
  });

  testWidgets('分数fieldの選択ハンドルを外へ広げると分数全体へsnapする', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('7+');
    _enterFraction(controller, '23', '45');
    controller.pasteAtCaret('+9');
    await _pumpCalculator(tester, controller);

    await _doubleTapAt(
      tester,
      tester.getCenter(find.byKey(const Key('fractionNumeratorField'))),
    );
    expect(controller.selectedClipboardText, '23');

    final handle = find.byKey(const Key('calculatorSelectionBaseHandle'));
    final leadingText = _expressionTextContaining('7');
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveTo(tester.getCenter(leadingText));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.selection!.base, isA<RawExpressionPosition>());
    expect(controller.selection!.extent, isA<RawExpressionPosition>());
    expect(controller.selectedClipboardText, contains('23/45'));
    expect(find.byKey(const Key('selectedFractionNode')), findsOneWidget);
  });

  testWidgets('baseとextentが逆向きでも両端ハンドルを表示する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('12345');
    controller.selectRange(
      const RawExpressionPosition(5),
      const RawExpressionPosition(1),
    );
    await _pumpCalculator(tester, controller);

    expect(controller.selectedClipboardText, '2345');
    _expectHandles();
    expect(tester.takeException(), isNull);
  });

  testWidgets('通常式から複数の構造化分数まで選択描画する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('7+');
    _enterFraction(controller, '1', '2');
    controller.press('+');
    _enterFraction(controller, '3', '4');
    controller.pasteAtCaret('+9');
    controller.selectRange(
      const RawExpressionPosition(0),
      RawExpressionPosition(controller.expression.length),
    );
    await _pumpCalculator(tester, controller);

    expect(controller.selectedClipboardText, '7+1/2+3/4+9');
    expect(find.byKey(const Key('selectedFractionNode')), findsNWidgets(2));
    _expectHandles();
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px・大文字・ダークテーマ・Androidでも選択表示が画面内に収まる', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('12345678901234567890+42.75');
    await _pumpCalculator(
      tester,
      controller,
      size: const Size(320, 1200),
      textScale: 1.6,
      platform: TargetPlatform.android,
      brightness: Brightness.dark,
    );
    // The existing fixed-height calculator controls report one baseline
    // overflow at this accessibility scale. Selection must not add another.
    expect(tester.takeException(), isA<FlutterError>());

    controller.selectRange(
      const RawExpressionPosition(0),
      RawExpressionPosition(controller.expression.length),
    );
    await tester.pump();
    await tester.pump();

    _expectHandles();
    for (final key in const [
      Key('calculatorSelectionBaseHandle'),
      Key('calculatorSelectionExtentHandle'),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(1200));
    }
    expect(tester.takeException(), isNull);
  });
}
