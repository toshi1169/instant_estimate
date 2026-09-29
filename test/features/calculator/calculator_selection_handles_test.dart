import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  final text = widget.data ?? widget.textSpan!.toPlainText();
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

Offset _characterBoundary(
  WidgetTester tester,
  Finder finder,
  String target, {
  required bool trailing,
}) {
  final widget = tester.widget<Text>(finder);
  final text = widget.data ?? widget.textSpan!.toPlainText();
  final index = text.indexOf(target);
  expect(index, isNonNegative);
  final painter = TextPainter(
    text: TextSpan(text: text, style: widget.style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final offset = index + (trailing ? target.length : 0);
  final x = painter
      .getOffsetForCaret(TextPosition(offset: offset), Rect.zero)
      .dx;
  final rect = tester.getRect(finder);
  return Offset(rect.left + x * rect.width / painter.width, rect.center.dy);
}

Offset _rawBoundary(
  WidgetTester tester,
  Finder finder,
  ExpressionTextSegment segment,
  int rawOffset,
) {
  final widget = tester.widget<Text>(finder);
  final text = widget.data ?? widget.textSpan!.toPlainText();
  expect(text, segment.text);
  final displayOffset = segment.rawOffsets.indexOf(rawOffset);
  expect(displayOffset, isNonNegative);
  final painter = TextPainter(
    text: TextSpan(text: text, style: widget.style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final x = painter
      .getOffsetForCaret(TextPosition(offset: displayOffset), Rect.zero)
      .dx;
  final rect = tester.getRect(finder);
  return Offset(rect.left + x * rect.width / painter.width, rect.center.dy);
}

Offset _renderedRawBoundary(
  WidgetTester tester,
  Finder finder,
  ExpressionTextSegment segment,
  int rawOffset,
) {
  final displayOffset = segment.rawOffsets.indexOf(rawOffset);
  expect(displayOffset, isNonNegative);
  final richText = find.descendant(of: finder, matching: find.byType(RichText));
  expect(richText, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(richText);
  return paragraph.localToGlobal(
    paragraph.getOffsetForCaret(TextPosition(offset: displayOffset), Rect.zero),
  );
}

Offset _renderedFractionBoundary(
  WidgetTester tester,
  Key fieldKey,
  String value,
  int offset,
) {
  final text = find.descendant(
    of: find.byKey(fieldKey),
    matching: find.byWidgetPredicate(
      (widget) => widget is Text && widget.data == value,
    ),
  );
  expect(text, findsOneWidget);
  final richText = find.descendant(of: text, matching: find.byType(RichText));
  final paragraph = tester.renderObject<RenderParagraph>(richText);
  return paragraph.localToGlobal(
    paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero),
  );
}

Future<void> _dragHandle(
  WidgetTester tester, {
  required Key handleKey,
  required Offset destination,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(handleKey)),
  );
  await gesture.moveTo(destination);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Offset _iosHandleKnobCenter(
  WidgetTester tester,
  Key handleKey, {
  required bool circleAtTop,
}) {
  final paint = find.descendant(
    of: find.byKey(handleKey),
    matching: find.byType(CustomPaint),
  );
  final rect = tester.getRect(paint.last);
  return Offset(rect.center.dx, circleAtTop ? rect.top + 6 : rect.bottom - 6);
}

Offset _iosHandleAnchor(
  WidgetTester tester,
  Key handleKey, {
  required bool leftType,
}) {
  final paint = find.descendant(
    of: find.byKey(handleKey),
    matching: find.byType(CustomPaint),
  );
  final handleBox = tester.renderObject<RenderBox>(paint.last);
  final anchor = cupertinoTextSelectionControls.getHandleAnchor(
    leftType ? TextSelectionHandleType.left : TextSelectionHandleType.right,
    54.6,
  );
  return handleBox.localToGlobal(anchor);
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
    (widget) =>
        widget is Text &&
        ((widget.data ?? widget.textSpan?.toPlainText())?.contains(value) ??
            false),
  ),
);

Finder _expressionTextForSegment(ExpressionTextSegment segment) =>
    find.descendant(
      of: find.byKey(const Key('expressionText')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == segment.text &&
            widget.style?.fontSize == 54.6,
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

Finder _toolbarAction(String label) => find.descendant(
  of: find.byKey(const Key('calculatorSelectionToolbar')),
  matching: find.text(label),
);

Finder _caretToolbarAction(String label) => find.descendant(
  of: find.byKey(const Key('calculatorCaretToolbar')),
  matching: find.text(label),
);

void _mockClipboard({String initialText = ''}) {
  var clipboardText = initialText;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String;
          case 'Clipboard.getData':
            return <String, dynamic>{'text': clipboardText};
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
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
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('選択外の空白タップは古い選択を解除して最新位置を優先する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+456');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final expression = _expressionTextContaining('456');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '456'));
    expect(controller.selectedClipboardText, '456');

    final field = tester.getRect(
      find.byKey(const Key('expressionVerticalScroll')),
    );
    await tester.tapAt(Offset(field.left + 4, field.top + 4));
    await tester.pumpAndSettle();

    expect(controller.selection, isNull);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
  });

  testWidgets('設定と関数一覧を開く前にselection Overlayを完全に解除する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+456');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    var expression = _expressionTextContaining('456');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '456'));
    await tester.tap(find.byKey(const Key('calculatorKey⚙')));
    await tester.pumpAndSettle();
    expect(controller.selection, isNull);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expression = _expressionTextContaining('456');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '456'));
    await tester.longPress(find.text('•••'));
    await tester.pumpAndSettle();
    expect(controller.selection, isNull);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
  });

  testWidgets('通常時とselection時は同じTextStyleとglyph描画を使用する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+456');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    var text = tester.widget<Text>(_expressionTextContaining('123'));
    final normalStyle = text.style;
    await _doubleTapAt(
      tester,
      _characterCenter(tester, _expressionTextContaining('123'), '456'),
    );
    text = tester.widget<Text>(_expressionTextContaining('123'));

    expect(text.style, normalStyle);
    expect(text.data, '123 + 456');
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('選択メニューのコピーは選択を維持しカットは選択範囲だけ削除する', (tester) async {
    _mockClipboard();
    final controller = CalculatorController()..pasteAtCaret('123456789+429÷25');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final expression = _expressionTextContaining('429');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '429'));
    await tester.tap(_toolbarAction('コピー'));
    await tester.pumpAndSettle();

    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, '429');
    expect(controller.selectedClipboardText, '429');
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);

    await tester.tap(_toolbarAction('カット'));
    await tester.pumpAndSettle();

    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, '429');
    expect(controller.expression, '123456789+÷25');
    expect(controller.selection, isNull);
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
  });

  testWidgets('選択メニューの外部ペーストは選択範囲を置換し消去は選択だけ削除する', (tester) async {
    _mockClipboard(initialText: '88');
    final controller = CalculatorController()..pasteAtCaret('123+42.75÷5');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    var expression = _expressionTextContaining('42.75');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '42.75'));
    await tester.tap(_toolbarAction('ペースト'));
    await tester.pumpAndSettle();

    expect(controller.expression, '123+88÷5');
    expect(controller.selection, isNull);

    expression = _expressionTextContaining('88');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '88'));
    await tester.tap(_toolbarAction('消去'));
    await tester.pumpAndSettle();

    expect(controller.expression, '123+÷5');
    expect(controller.selection, isNull);
  });

  testWidgets('選択中の見積送信は文字欄だけを候補にし数量と解形式を出さない', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+429÷25');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final expression = _expressionTextContaining('429');
    await _doubleTapAt(tester, _characterCenter(tester, expression, '429'));
    await tester.tap(_toolbarAction('見積へ送る'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimateContentSelector')), findsNothing);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('estimateTransferPreview')))
          .data,
      '429',
    );
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    expect(find.text('数量'), findsNothing);
    expect(find.text('名称'), findsOneWidget);
    expect(find.text('仕様'), findsOneWidget);
    expect(find.text('摘要'), findsWidgets);
    await tester.tap(find.text('摘要').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    final description = tester.widget<TextFormField>(
      find.byKey(const Key('estimateDescriptionField')),
    );
    final quantity = tester.widget<TextFormField>(
      find.byKey(const Key('estimateQuantityField')),
    );
    expect(description.controller?.text, '429');
    expect(quantity.controller?.text, isEmpty);
  });

  testWidgets('小数点は数値全体を選択し演算子キャレットはペースト／選択を表示する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+42.75÷5');
    await _pumpCalculator(tester, controller);
    var expression = _expressionTextContaining('42.75');

    await _doubleTapAt(tester, _characterCenter(tester, expression, '42.75'));
    expect(controller.selectedClipboardText, '42.75');

    controller.clearSelection();
    await tester.pump();
    controller.moveCaretToRawOffset(3);
    await tester.pump();
    await _doubleTapAt(
      tester,
      tester.getCenter(find.byKey(const Key('calculatorCaret'))),
    );
    expect(controller.selection, isNull);
    expect(find.byKey(const Key('calculatorCaret')), findsOneWidget);
    expect(find.byKey(const Key('calculatorCaretToolbar')), findsOneWidget);
    expect(_caretToolbarAction('ペースト'), findsOneWidget);
    expect(_caretToolbarAction('選択'), findsOneWidget);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
  });

  testWidgets('キャレットメニューの選択は右側数字列を優先し、なければ左側を選択する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+456×789');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    controller.moveCaretToRawOffset(4);
    await tester.pump();
    await _doubleTapAt(
      tester,
      tester.getCenter(find.byKey(const Key('calculatorCaret'))),
    );
    await tester.tap(_caretToolbarAction('選択'));
    await tester.pumpAndSettle();
    expect(controller.selectedClipboardText, '456');
    _expectHandles();

    controller.clearSelection();
    controller.moveCaretToRawOffset(3);
    await tester.pump();
    await _doubleTapAt(
      tester,
      tester.getCenter(find.byKey(const Key('calculatorCaret'))),
    );
    await tester.tap(_caretToolbarAction('選択'));
    await tester.pumpAndSettle();
    expect(controller.selectedClipboardText, '123');
  });

  testWidgets('左右両ハンドルを記号境界へ動かし終了後にメニューを一度だけ再表示する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+254×5−993');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final text = _expressionTextContaining('254');
    final beforePlus = _characterBoundary(tester, text, '+', trailing: false);
    final afterMultiply = _characterBoundary(tester, text, '×', trailing: true);
    await _doubleTapAt(tester, _characterCenter(tester, text, '254'));
    expect(controller.selectedClipboardText, '254');

    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionBaseHandle'),
      destination: beforePlus,
    );
    expect(controller.selectedClipboardText, '+254');
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionExtentHandle'),
      destination: afterMultiply,
    );
    expect(controller.selectedClipboardText, '+254×');
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('短い選択でhit領域が近接しても左右physical handleを個別に掴める', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+456');
    controller.selectRange(
      const RawExpressionPosition(1),
      const RawExpressionPosition(2),
    );
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final text = _expressionTextContaining('123');
    final start = _characterBoundary(tester, text, '1', trailing: false);
    final end = _characterBoundary(tester, text, '3', trailing: true);
    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionBaseHandle'),
      destination: start,
    );
    expect(controller.selection!.base, const RawExpressionPosition(0));

    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionExtentHandle'),
      destination: end,
    );
    expect(controller.selection!.extent, const RawExpressionPosition(3));
    expect(controller.selectedClipboardText, '123');
  });

  testWidgets('iOSで実際に描画された左右の青いノブからpointer down move upが届く', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123+456');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final text = _expressionTextContaining('123');
    await _doubleTapAt(tester, _characterCenter(tester, text, '456'));
    final start = _characterBoundary(tester, text, '1', trailing: false);
    var gesture = await tester.startGesture(
      _iosHandleKnobCenter(
        tester,
        const Key('calculatorSelectionBaseHandle'),
        circleAtTop: true,
      ),
    );
    await gesture.moveTo(start);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection!.base, const RawExpressionPosition(0));

    final end = _characterBoundary(tester, text, '6', trailing: true);
    gesture = await tester.startGesture(
      _iosHandleKnobCenter(
        tester,
        const Key('calculatorSelectionExtentHandle'),
        circleAtTop: false,
      ),
    );
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection!.extent, const RawExpressionPosition(7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('左右どちらの実描画ノブから同一ExpressionPositionへ重ねてもcollapseする', (
    tester,
  ) async {
    final controller = CalculatorController()..pasteAtCaret('123+456');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));
    final text = _expressionTextContaining('123');

    await _doubleTapAt(tester, _characterCenter(tester, text, '456'));
    var leftKnob = _iosHandleKnobCenter(
      tester,
      const Key('calculatorSelectionBaseHandle'),
      circleAtTop: true,
    );
    var rightAnchor = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionExtentHandle'),
      leftType: false,
    );
    var leftAnchor = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionBaseHandle'),
      leftType: true,
    );
    var gesture = await tester.startGesture(leftKnob);
    await gesture.moveBy(rightAnchor - leftAnchor);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection, isNull);
    expect(controller.expressionPosition, const RawExpressionPosition(7));

    await _doubleTapAt(tester, _characterCenter(tester, text, '456'));
    final rightKnob = _iosHandleKnobCenter(
      tester,
      const Key('calculatorSelectionExtentHandle'),
      circleAtTop: false,
    );
    leftAnchor = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionBaseHandle'),
      leftType: true,
    );
    rightAnchor = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionExtentHandle'),
      leftType: false,
    );
    gesture = await tester.startGesture(rightKnob);
    await gesture.moveBy(leftAnchor - rightAnchor);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection, isNull);
    expect(controller.expressionPosition, const RawExpressionPosition(4));
  });

  testWidgets('通常式のTextPainter境界とplatform handle anchorは同じ描画座標を使う', (
    tester,
  ) async {
    final controller = CalculatorController()..pasteAtCaret('123+456');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));
    final text = _expressionTextContaining('123');
    await _doubleTapAt(tester, _characterCenter(tester, text, '456'));
    final segment = controller.displaySegments
        .whereType<ExpressionTextSegment>()
        .singleWhere((segment) => segment.text.contains('456'));

    final expectedStart = _rawBoundary(tester, text, segment, 4);
    final expectedEnd = _rawBoundary(tester, text, segment, 7);
    final actualStart = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionBaseHandle'),
      leftType: true,
    );
    final actualEnd = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionExtentHandle'),
      leftType: false,
    );
    expect(actualStart.dx, closeTo(expectedStart.dx, 0.01));
    expect(actualEnd.dx, closeTo(expectedEnd.dx, 0.01));
  });

  testWidgets('縮小した長い通常式の実描画境界とhandle endpointを左端から右端まで比較する', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('12345678901234567890');
    await _pumpCalculator(
      tester,
      controller,
      size: const Size(320, 844),
      textScale: 1.2,
    );
    final text = _expressionTextContaining('1234567890');
    final segment = controller.displaySegments
        .whereType<ExpressionTextSegment>()
        .firstWhere((segment) => segment.text.contains('1234567890'));

    for (final rawOffset in <int>[0, 5, 10, 15, 20]) {
      controller.selectRange(
        RawExpressionPosition(rawOffset == 20 ? 19 : rawOffset),
        RawExpressionPosition(rawOffset == 20 ? 20 : rawOffset + 1),
      );
      await tester.pump();
      await tester.pump();
      final key = rawOffset == 20
          ? const Key('calculatorSelectionExtentHandle')
          : const Key('calculatorSelectionBaseHandle');
      final leftType = rawOffset != 20;
      final actual = _iosHandleAnchor(tester, key, leftType: leftType);
      final expected = _renderedRawBoundary(tester, text, segment, rawOffset);
      expect(actual.dx, closeTo(expected.dx, 0.01), reason: 'raw=$rawOffset');
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('短い通常式の演算子・括弧・小数点境界は実描画座標と一致する ($brightness)', (tester) async {
      final controller = CalculatorController()..pasteAtCaret('(12.3+45)');
      await _pumpCalculator(
        tester,
        controller,
        size: const Size(800, 844),
        textScale: 1.15,
        brightness: brightness,
      );
      final segment = controller.displaySegments
          .whereType<ExpressionTextSegment>()
          .single;
      final text = _expressionTextForSegment(segment);

      for (final rawOffset in <int>[0, 1, 3, 4, 5, 6, 8]) {
        controller.selectRange(
          RawExpressionPosition(rawOffset),
          RawExpressionPosition(rawOffset + 1),
        );
        await tester.pump();
        await tester.pump();
        final actual = _iosHandleAnchor(
          tester,
          const Key('calculatorSelectionBaseHandle'),
          leftType: true,
        );
        final expected = _renderedRawBoundary(tester, text, segment, rawOffset);
        expect(actual.dx, closeTo(expected.dx, 0.01), reason: 'raw=$rawOffset');
      }
    });
  }

  testWidgets('2行通常式は各行の実描画境界から同じraw位置を復元する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('1234567890+12.34');
    await _pumpCalculator(
      tester,
      controller,
      size: const Size(320, 844),
      textScale: 1.25,
    );
    final segments = controller.displaySegments
        .whereType<ExpressionTextSegment>()
        .toList();
    expect(segments, hasLength(2));

    for (final rawOffset in <int>[0, 5, 11, 14, 15]) {
      final segment = segments.firstWhere(
        (segment) => segment.rawOffsets.contains(rawOffset),
      );
      final text = _expressionTextForSegment(segment);
      final expected = _renderedRawBoundary(tester, text, segment, rawOffset);
      await tester.tapAt(expected);
      await tester.pump();
      expect(
        controller.expressionPosition,
        RawExpressionPosition(rawOffset),
        reason: 'tap raw=$rawOffset',
      );

      controller.selectRange(
        RawExpressionPosition(rawOffset),
        RawExpressionPosition(rawOffset + 1),
      );
      await tester.pump();
      await tester.pump();
      final actual = _iosHandleAnchor(
        tester,
        const Key('calculatorSelectionBaseHandle'),
        leftType: true,
      );
      expect(actual.dx, closeTo(expected.dx, 0.01), reason: 'raw=$rawOffset');
    }
  });

  testWidgets('選択ハンドル交差後も向きを保持してドラッグと通常操作を継続できる', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('(12+345)÷6');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final text = _expressionTextContaining('345');
    final afterCloseParen = _characterBoundary(
      tester,
      text,
      ')',
      trailing: true,
    );
    await _doubleTapAt(tester, _characterCenter(tester, text, '345'));

    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionBaseHandle'),
      destination: afterCloseParen,
    );

    expect(controller.selection!.base, const RawExpressionPosition(8));
    expect(controller.selection!.extent, const RawExpressionPosition(7));
    expect(controller.selectedClipboardText, ')');
    _expectHandles();
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);

    await tester.tap(_toolbarAction('消去'));
    await tester.pumpAndSettle();
    expect(controller.expression, '(12+345÷6');
    expect(controller.selection, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('左右ハンドルは同一位置を通過して両方向に交差できる', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('(12+345)÷6');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final text = _expressionTextContaining('345');
    final beforeToken = _characterBoundary(
      tester,
      text,
      '345',
      trailing: false,
    );
    final afterToken = _characterBoundary(tester, text, '345', trailing: true);
    final beforePlus = _characterBoundary(tester, text, '+', trailing: false);
    final afterCloseParen = _characterBoundary(
      tester,
      text,
      ')',
      trailing: true,
    );
    await _doubleTapAt(tester, _characterCenter(tester, text, '345'));

    var gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('calculatorSelectionBaseHandle'))),
    );
    await gesture.moveTo(afterToken);
    await tester.pump();
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
    await gesture.moveTo(afterCloseParen);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection!.base, const RawExpressionPosition(8));
    expect(controller.selection!.extent, const RawExpressionPosition(7));

    await _doubleTapAt(tester, _characterCenter(tester, text, '345'));
    gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const Key('calculatorSelectionExtentHandle')),
      ),
    );
    await gesture.moveTo(beforeToken);
    await tester.pump();
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
    await gesture.moveTo(beforePlus);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection!.base, const RawExpressionPosition(4));
    expect(controller.selection!.extent, const RawExpressionPosition(3));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('左ハンドルを右端へ重ねると選択をキャレットへ統合する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('12+345×67');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final text = _expressionTextContaining('345');
    final afterToken = _characterBoundary(tester, text, '345', trailing: true);
    await _doubleTapAt(tester, _characterCenter(tester, text, '345'));
    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionBaseHandle'),
      destination: afterToken,
    );

    expect(controller.selection, isNull);
    expect(controller.expressionPosition, const RawExpressionPosition(6));
    expect(find.byKey(const Key('calculatorCaret')), findsOneWidget);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('calculatorSelectionExtentHandle')),
      findsNothing,
    );
    await _doubleTapAt(
      tester,
      tester.getCenter(find.byKey(const Key('calculatorCaret'))),
    );
    expect(find.byKey(const Key('calculatorCaretToolbar')), findsOneWidget);
    expect(_caretToolbarAction('ペースト'), findsOneWidget);
    expect(_caretToolbarAction('選択'), findsOneWidget);
  });

  testWidgets('左ハンドルを別行へドラッグして複数行を跨ぐ範囲を選択できる', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('1234567890+1234567890+345');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));

    final firstLine = _expressionTextContaining('1234567890').first;
    final lastLine = _expressionTextContaining('345').last;
    final documentStart = _characterBoundary(
      tester,
      firstLine,
      '1',
      trailing: false,
    );
    await _doubleTapAt(tester, _characterCenter(tester, lastLine, '345'));
    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionBaseHandle'),
      destination: documentStart,
    );

    expect(controller.selectedClipboardText, controller.expression);
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('複数行のスクロールはselectionを保ったままハンドル座標を追従させる', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('1234567890+1234567890+1234567890+345');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));

    final lastLine = _expressionTextContaining('345').last;
    await _doubleTapAt(tester, _characterCenter(tester, lastLine, '345'));
    controller.selectRange(
      const RawExpressionPosition(22),
      const RawExpressionPosition(36),
    );
    await tester.pumpAndSettle();
    final selectionBefore = controller.selection;
    final handleBefore = tester.getCenter(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
    );

    await tester.drag(
      find.byKey(const Key('expressionVerticalScroll')),
      const Offset(0, 24),
    );
    await tester.pumpAndSettle();

    expect(controller.selection, selectionBefore);
    final handleAfter = tester.getCenter(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
    );
    expect(handleAfter.dy, isNot(handleBefore.dy));
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    final selectedLine = _expressionTextContaining('1234567890').last;
    await tester.tapAt(_characterCenter(tester, selectedLine, '5'));
    await tester.pumpAndSettle();
    expect(controller.selection, selectionBefore);
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('画面外へ出たselectionハンドルを隠し戻すと正しい端点へ再表示する', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('1234567890+1234567890+1234567890+345');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));

    final lastLine = _expressionTextContaining('345').last;
    await _doubleTapAt(tester, _characterCenter(tester, lastLine, '345'));
    final selectionBefore = controller.selection;
    final scroll = find.byKey(const Key('expressionVerticalScroll'));

    await tester.drag(scroll, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(controller.selection, selectionBefore);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('calculatorSelectionExtentHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);

    await tester.drag(scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.selection, selectionBefore);
    _expectHandles();
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('選択範囲へのPasteは現在範囲だけを置換し選択なしではキャレットへ挿入する', (tester) async {
    _mockClipboard(initialText: '88');
    final controller = CalculatorController()..pasteAtCaret('12+345×67');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final text = _expressionTextContaining('345');
    await _doubleTapAt(tester, _characterCenter(tester, text, '345'));
    expect(controller.selection, isNotNull);
    await tester.tap(_toolbarAction('ペースト'));
    await tester.pumpAndSettle();
    expect(controller.expression, '12+88×67');

    controller.moveCaretToRawOffset(2);
    expect(controller.selection, isNull);
    expect(controller.pasteAtCaret('9'), isTrue);
    expect(controller.expression, '129+88×67');
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

  for (final values in const [
    ('12345', '12345678'),
    ('12345678', '12345'),
    ('1', '1234567890'),
    ('1234567890', '1'),
    ('12345', '67890'),
  ]) {
    testWidgets(
      '長さが異なる分子${values.$1.length}桁／分母${values.$2.length}桁でも実描画境界とhandle endpointが一致する',
      (tester) async {
        final controller = CalculatorController();
        _enterFraction(controller, values.$1, values.$2);
        await _pumpCalculator(tester, controller, size: const Size(320, 844));
        final marker = controller.expression;

        for (final fieldCase in [
          (
            const Key('fractionNumeratorField'),
            FractionField.numerator,
            values.$1,
          ),
          (
            const Key('fractionDenominatorField'),
            FractionField.denominator,
            values.$2,
          ),
        ]) {
          for (final range in [
            (0, 1),
            (fieldCase.$3.length - 1, fieldCase.$3.length),
          ]) {
            controller.selectRange(
              FractionExpressionPosition(
                marker: marker,
                field: fieldCase.$2,
                offset: range.$1,
              ),
              FractionExpressionPosition(
                marker: marker,
                field: fieldCase.$2,
                offset: range.$2,
              ),
            );
            await tester.pump();
            await tester.pump();

            final expectedBase = _renderedFractionBoundary(
              tester,
              fieldCase.$1,
              fieldCase.$3,
              range.$1,
            );
            final expectedExtent = _renderedFractionBoundary(
              tester,
              fieldCase.$1,
              fieldCase.$3,
              range.$2,
            );
            final actualBase = _iosHandleAnchor(
              tester,
              const Key('calculatorSelectionBaseHandle'),
              leftType: true,
            );
            final actualExtent = _iosHandleAnchor(
              tester,
              const Key('calculatorSelectionExtentHandle'),
              leftType: false,
            );
            // The platform handle itself is pixel-snapped after the scaled
            // expression geometry is converted into the root overlay.
            expect(actualBase.dx, closeTo(expectedBase.dx, 1.5));
            expect(actualExtent.dx, closeTo(expectedExtent.dx, 1.5));
          }
        }
      },
    );
  }

  testWidgets('帯分数整数部はTextScaler・Darkテーマでも実描画境界とhandle endpointが一致する', (
    tester,
  ) async {
    final controller = CalculatorController();
    _enterFraction(controller, '12345', '12345678', wholeNumber: '9876');
    await _pumpCalculator(
      tester,
      controller,
      size: const Size(320, 844),
      textScale: 1.4,
      brightness: Brightness.dark,
    );
    // The calculator keypad has an existing overflow at this accessibility
    // scale; this test targets the fraction field geometry above it.
    tester.takeException();
    final marker = controller.expression;
    controller.selectRange(
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.wholeNumber,
        offset: 0,
      ),
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.wholeNumber,
        offset: 4,
      ),
    );
    await tester.pump();
    await tester.pump();

    final expectedBase = _renderedFractionBoundary(
      tester,
      const Key('mixedFractionWholeNumber'),
      '9876',
      0,
    );
    final expectedExtent = _renderedFractionBoundary(
      tester,
      const Key('mixedFractionWholeNumber'),
      '9876',
      4,
    );
    expect(
      _iosHandleAnchor(
        tester,
        const Key('calculatorSelectionBaseHandle'),
        leftType: true,
      ).dx,
      closeTo(expectedBase.dx, 1.5),
    );
    expect(
      _iosHandleAnchor(
        tester,
        const Key('calculatorSelectionExtentHandle'),
        leftType: false,
      ).dx,
      closeTo(expectedExtent.dx, 1.5),
    );
  });

  testWidgets('分数fieldの選択ハンドルを外へ広げると分数全体へsnapする', (tester) async {
    _mockClipboard();
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
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);

    await tester.tap(_toolbarAction('コピー'));
    await tester.pumpAndSettle();
    final copied = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    expect(copied, contains('23/45'));
    expect(
      copied.runes.any((rune) => rune >= 0xE000 && rune <= 0xF8FF),
      isFalse,
    );

    final markerBeforePaste = controller.expression;
    await tester.tap(_toolbarAction('ペースト'));
    await tester.pumpAndSettle();
    expect(controller.displayExpression, '7 + 23/45 + 9');
    expect(controller.expression, isNot(markerBeforePaste));
    expect(find.byKey(const Key('fractionNumeratorField')), findsOneWidget);
    expect(find.byKey(const Key('fractionDenominatorField')), findsOneWidget);
    expect(controller.selection, isNull);
  });

  testWidgets('分数全体へsnapした後も指を離すまでハンドルドラッグを継続する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('7+');
    _enterFraction(controller, '23', '45');
    controller.pasteAtCaret('+9');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    await _doubleTapAt(
      tester,
      tester.getCenter(find.byKey(const Key('fractionNumeratorField'))),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('calculatorSelectionBaseHandle'))),
    );
    await gesture.moveTo(tester.getCenter(_expressionTextContaining('7')));
    await tester.pump();
    expect(controller.selection!.base, isA<RawExpressionPosition>());
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);

    await gesture.moveTo(tester.getCenter(_expressionTextContaining('9')));
    await tester.pump();
    expect(controller.selection!.base, isA<RawExpressionPosition>());
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
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
