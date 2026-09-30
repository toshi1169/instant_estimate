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
  final text = tester.widget<Text>(finder).textSpan!.toPlainText();
  final richText = find.descendant(
    of: find.byKey(const Key('expressionText')),
    matching: find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText() == text,
    ),
  );
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
  final richText = find.descendant(
    of: find.byKey(fieldKey),
    matching: find.byType(RichText),
  );
  expect(richText, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(richText);
  expect(paragraph.text.toPlainText(), value);
  return paragraph.localToGlobal(
    paragraph.getOffsetForCaret(TextPosition(offset: offset), Rect.zero),
  );
}

Offset _renderedFractionCharacterCenter(
  WidgetTester tester,
  Key fieldKey,
  String value,
  int index,
) {
  final leading = _renderedFractionBoundary(tester, fieldKey, value, index);
  final trailing = _renderedFractionBoundary(
    tester,
    fieldKey,
    value,
    index + 1,
  );
  final richText = find.descendant(
    of: find.byKey(fieldKey),
    matching: find.byType(RichText),
  );
  return Offset(
    (leading.dx + trailing.dx) / 2,
    tester.getRect(richText).center.dy,
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
  final handleBox = tester.renderObject<RenderBox>(paint.last);
  final topLeft = handleBox.localToGlobal(Offset.zero);
  final bottomRight = handleBox.localToGlobal(
    handleBox.size.bottomRight(Offset.zero),
  );
  final scale = (bottomRight.dy - topLeft.dy) / handleBox.size.height;
  return Offset(
    (topLeft.dx + bottomRight.dx) / 2,
    circleAtTop ? topLeft.dy + 6 * scale : bottomRight.dy - 6 * scale,
  );
}

Offset _iosHandleAnchor(
  WidgetTester tester,
  Key handleKey, {
  required bool leftType,
}) {
  final anchorKey = handleKey == const Key('calculatorSelectionBaseHandle')
      ? const ValueKey('calculatorSelectionBaseHandleAnchor')
      : const ValueKey('calculatorSelectionExtentHandleAnchor');
  final anchorBox = tester.renderObject<RenderBox>(find.byKey(anchorKey));
  return anchorBox.localToGlobal(Offset.zero);
}

double _paintedVerticalScale(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  final top = box.localToGlobal(Offset.zero);
  final bottom = box.localToGlobal(Offset(0, box.size.height));
  return (bottom - top).distance / box.size.height;
}

double _handleVisualScale(WidgetTester tester, Key handleKey) {
  final paint = find.descendant(
    of: find.byKey(handleKey),
    matching: find.byType(CustomPaint),
  );
  return _paintedVerticalScale(tester, paint.last);
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
            (widget.data ?? widget.textSpan?.toPlainText()) == segment.text &&
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

String _selectAllLabel(WidgetTester tester) => MaterialLocalizations.of(
  tester.element(find.byKey(const Key('calculatorCaretToolbar'))),
).selectAllButtonLabel;

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
    final normalSpan = text.textSpan as TextSpan;
    await _doubleTapAt(
      tester,
      _characterCenter(tester, _expressionTextContaining('123'), '456'),
    );
    text = tester.widget<Text>(_expressionTextContaining('123'));

    final selectedSpan = text.textSpan as TextSpan;
    expect(selectedSpan.style, normalSpan.style);
    expect(selectedSpan.toPlainText(), '123 + 456');
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('通常式と構造化分数は同じ書体・太さ・基準サイズを共有する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('12+');
    _enterFraction(controller, '34', '56');
    await _pumpCalculator(tester, controller, size: const Size(800, 844));

    final expressionText = tester.widget<Text>(_expressionTextContaining('12'));
    final expressionRoot = expressionText.textSpan as TextSpan;
    final expressionStyle = expressionRoot.style!;
    final fractionText = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const Key('fractionNumeratorField')),
        matching: find.byType(RichText),
      ),
    );
    final fractionRoot = fractionText.text as TextSpan;
    final fractionStyle = (fractionRoot.children?.single as TextSpan).style!;

    expect(fractionStyle.fontFamily, expressionStyle.fontFamily);
    expect(
      fractionStyle.fontFamilyFallback,
      expressionStyle.fontFamilyFallback,
    );
    expect(fractionStyle.fontWeight, expressionStyle.fontWeight);
    expect(fractionStyle.fontSize, expressionStyle.fontSize);
    expect(fractionStyle.letterSpacing, expressionStyle.letterSpacing);
    expect(expressionStyle.fontWeight, FontWeight.w400);
    expect(expressionStyle.fontSize, 54.6);
    expect(expressionRoot.text, '12 + ');
    expect(expressionRoot.children, isNull);

    final expressionPainter = TextPainter(
      text: TextSpan(text: '1234567890', style: expressionStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final fractionPainter = TextPainter(
      text: TextSpan(text: '1234567890', style: fractionStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(fractionPainter.width, closeTo(expressionPainter.width, 0.001));
  });

  testWidgets('通常式と分子分母のhandle表示倍率は各端点の実描画倍率に追従する', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('12345678901234567890+');
    _enterFraction(controller, '12345678', '1234');
    await _pumpCalculator(tester, controller, size: const Size(320, 844));

    final textSegment = controller.displaySegments
        .whereType<ExpressionTextSegment>()
        .first;
    controller.selectRange(
      RawExpressionPosition(textSegment.rawOffsets.first),
      RawExpressionPosition(textSegment.rawOffsets.last),
    );
    await tester.pump();
    await tester.pump();

    final expressionText = _expressionTextForSegment(textSegment);
    final expressionParagraph = find.descendant(
      of: find.byKey(const Key('expressionText')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText() == textSegment.text,
      ),
    );
    final expressionScale = _paintedVerticalScale(tester, expressionParagraph);
    expect(expressionScale, lessThan(1));
    expect(
      _handleVisualScale(tester, const Key('calculatorSelectionBaseHandle')),
      closeTo(expressionScale, 0.01),
    );
    expect(tester.getSize(expressionText).height, greaterThan(0));

    final fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    controller.selectRange(
      FractionExpressionPosition(
        marker: fraction.marker,
        field: FractionField.numerator,
        offset: 2,
      ),
      FractionExpressionPosition(
        marker: fraction.marker,
        field: FractionField.denominator,
        offset: 2,
      ),
    );
    await tester.pump();
    await tester.pump();

    final numeratorParagraph = find.descendant(
      of: find.byKey(const Key('fractionNumeratorField')),
      matching: find.byType(RichText),
    );
    final denominatorParagraph = find.descendant(
      of: find.byKey(const Key('fractionDenominatorField')),
      matching: find.byType(RichText),
    );
    expect(
      _handleVisualScale(tester, const Key('calculatorSelectionBaseHandle')),
      closeTo(_paintedVerticalScale(tester, numeratorParagraph), 0.01),
    );
    expect(
      _handleVisualScale(tester, const Key('calculatorSelectionExtentHandle')),
      closeTo(_paintedVerticalScale(tester, denominatorParagraph), 0.01),
    );
    final hitSize = tester.getSize(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
    );
    expect(hitSize.width, greaterThanOrEqualTo(48));
    expect(hitSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('分子途中から分母途中を同じselectionで部分表示する', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '123456789', '123456789');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    final marker = controller.expression;

    controller.selectRange(
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.numerator,
        offset: 4,
      ),
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.denominator,
        offset: 2,
      ),
    );
    await tester.pump();
    await tester.pump();

    TextSpan fieldSpan(Key key) =>
        tester
                .widget<RichText>(
                  find.descendant(
                    of: find.byKey(key),
                    matching: find.byType(RichText),
                  ),
                )
                .text
            as TextSpan;
    List<TextSpan> leaves(TextSpan span) => [
      if (span.text != null) span,
      for (final child in span.children ?? const <InlineSpan>[])
        if (child is TextSpan) ...leaves(child),
    ];
    final numerator = fieldSpan(const Key('fractionNumeratorField'));
    final denominator = fieldSpan(const Key('fractionDenominatorField'));
    final numeratorChildren = leaves(numerator);
    final denominatorChildren = leaves(denominator);

    expect(numeratorChildren.map((span) => span.text), ['1234', '56789', '']);
    expect(numeratorChildren[1].style?.backgroundColor, isNotNull);
    expect(denominatorChildren.map((span) => span.text), ['', '12', '3456789']);
    expect(denominatorChildren[1].style?.backgroundColor, isNotNull);
    expect(find.byKey(const Key('selectedFractionNode')), findsNothing);
    _expectHandles();

    final baseAnchor = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionBaseHandle'),
      leftType: true,
    );
    final extentAnchor = _iosHandleAnchor(
      tester,
      const Key('calculatorSelectionExtentHandle'),
      leftType: false,
    );
    final numeratorBoundary = _renderedFractionBoundary(
      tester,
      const Key('fractionNumeratorField'),
      '123456789',
      4,
    );
    final denominatorBoundary = _renderedFractionBoundary(
      tester,
      const Key('fractionDenominatorField'),
      '123456789',
      2,
    );
    expect(baseAnchor.dx, closeTo(numeratorBoundary.dx, 0.01));
    expect(extentAnchor.dx, closeTo(denominatorBoundary.dx, 0.01));
  });

  testWidgets('分子の選択ハンドルを分母途中へドラッグして部分選択を継続する', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '123456789', '123456789');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    final marker = controller.expression;
    controller.selectRange(
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.numerator,
        offset: 4,
      ),
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.numerator,
        offset: 9,
      ),
    );
    await tester.pump();
    await tester.pump();

    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionExtentHandle'),
      destination: _renderedFractionBoundary(
        tester,
        const Key('fractionDenominatorField'),
        '123456789',
        2,
      ),
    );

    expect(controller.selectedClipboardText, '56789÷12');
    expect(controller.selection?.extent, isA<FractionExpressionPosition>());
    expect(
      (controller.selection!.extent as FractionExpressionPosition).field,
      FractionField.denominator,
    );
    expect(find.byKey(const Key('selectedFractionNode')), findsNothing);
    _expectHandles();
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
    expect(_caretToolbarAction('選択'), findsOneWidget);
    expect(_caretToolbarAction(_selectAllLabel(tester)), findsOneWidget);
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

  testWidgets('通常式キャレット左右1文字内のダブルタップはキャレットメニューを優先する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('123456');
    await _pumpCalculator(tester, controller);
    final text = _expressionTextContaining('123456');
    final adjacentCharacter = _characterCenter(tester, text, '4');
    final outsideCharacter = _characterCenter(tester, text, '6');
    controller.moveCaretToRawOffset(3);
    await tester.pump();
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('calculatorCaret'))),
    );
    await tester.pump(const Duration(seconds: 2));
    await _doubleTapAt(tester, adjacentCharacter);

    expect(controller.selection, isNull);
    expect(controller.expressionPosition, const RawExpressionPosition(3));
    expect(find.byKey(const Key('calculatorCaretToolbar')), findsOneWidget);

    controller.moveCaretToRawOffset(3);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _doubleTapAt(tester, outsideCharacter);
    expect(controller.selectedClipboardText, '123456');
  });

  testWidgets('分数fieldキャレット左右1文字内のダブルタップはキャレットメニューを優先する', (tester) async {
    final fractionController = CalculatorController();
    _enterFraction(fractionController, '1234', '5678');
    await _pumpCalculator(tester, fractionController);
    final marker = fractionController.expression;
    final fractionBoundary = _renderedFractionBoundary(
      tester,
      const Key('fractionNumeratorField'),
      '1234',
      2,
    );
    final fractionAdjacentCharacter = _renderedFractionCharacterCenter(
      tester,
      const Key('fractionNumeratorField'),
      '1234',
      2,
    );
    final fractionPosition = FractionExpressionPosition(
      marker: marker,
      field: FractionField.numerator,
      offset: 2,
    );
    await tester.tapAt(fractionBoundary);
    await tester.pump(const Duration(seconds: 2));
    expect(fractionController.expressionPosition, fractionPosition);
    await _doubleTapAt(tester, fractionAdjacentCharacter);

    expect(fractionController.selection, isNull);
    expect(fractionController.expressionPosition, fractionPosition);
    expect(find.byKey(const Key('calculatorCaretToolbar')), findsOneWidget);
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
    await tester.pump();
    expect(
      _iosHandleAnchor(
        tester,
        const Key('calculatorSelectionBaseHandle'),
        leftType: true,
      ),
      _iosHandleAnchor(
        tester,
        const Key('calculatorSelectionExtentHandle'),
        leftType: false,
      ),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.selection, isNull);
    expect(controller.expressionPosition, const RawExpressionPosition(7));
    expect(find.byKey(const Key('calculatorCaretToolbar')), findsOneWidget);
    expect(_caretToolbarAction('選択'), findsOneWidget);
    expect(_caretToolbarAction(_selectAllLabel(tester)), findsOneWidget);
    expect(_caretToolbarAction('コピー'), findsNothing);
    expect(_caretToolbarAction('カット'), findsNothing);

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
    await tester.pump();
    expect(
      _iosHandleAnchor(
        tester,
        const Key('calculatorSelectionBaseHandle'),
        leftType: true,
      ),
      _iosHandleAnchor(
        tester,
        const Key('calculatorSelectionExtentHandle'),
        leftType: false,
      ),
    );
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
      if (controller.hasSelection) {
        await tester.tapAt(expected);
        await tester.pumpAndSettle();
        expect(controller.selection, isNull);
      }
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

    await tester.tapAt(_characterCenter(tester, text, '345'));
    await tester.pumpAndSettle();
    expect(controller.selection, isNull);
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
    expect(find.byKey(const Key('calculatorCaretToolbar')), findsOneWidget);
    expect(_caretToolbarAction('選択'), findsOneWidget);
    expect(_caretToolbarAction(_selectAllLabel(tester)), findsOneWidget);
    expect(_caretToolbarAction('コピー'), findsNothing);
    expect(_caretToolbarAction('カット'), findsNothing);
    await _doubleTapAt(
      tester,
      tester.getCenter(find.byKey(const Key('calculatorCaret'))),
    );
    expect(find.byKey(const Key('calculatorCaretToolbar')), findsOneWidget);
    expect(_caretToolbarAction('選択'), findsOneWidget);
    expect(_caretToolbarAction(_selectAllLabel(tester)), findsOneWidget);
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
    expect(controller.selection, isNull);
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
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
    final marker = controller.expression;

    for (final entry in const [
      (Key('mixedFractionWholeNumber'), '12', FractionField.wholeNumber),
      (Key('fractionNumeratorField'), '34', FractionField.numerator),
      (Key('fractionDenominatorField'), '56', FractionField.denominator),
    ]) {
      if (controller.hasSelection) {
        await tester.tap(find.byKey(entry.$1));
        await tester.pumpAndSettle();
        expect(controller.selection, isNull);
      }
      controller.moveCaretBeforeFraction(marker);
      await tester.pump();
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

  testWidgets('短い分子12を実描画位置のダブルタップで選択する', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '12', '12345678');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    controller.moveCaretBeforeFraction(controller.expression);
    await tester.pump();

    await _doubleTapAt(
      tester,
      _renderedFractionCharacterCenter(
        tester,
        const Key('fractionNumeratorField'),
        '12',
        0,
      ),
    );

    expect(controller.selectedClipboardText, '12');
    expect(controller.selection?.base, isA<FractionExpressionPosition>());
    expect(controller.selection?.extent, isA<FractionExpressionPosition>());
    _expectHandles();
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsOneWidget);
  });

  testWidgets('分子12−566の表示選択とCut対象が一致する', (tester) async {
    _mockClipboard();
    final controller = CalculatorController()..press('a/b');
    for (final character in '12−566'.split('')) {
      controller.press(character);
    }
    controller.press('a/b');
    for (final character in '12345678'.split('')) {
      controller.press(character);
    }
    controller.press('a/b');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    controller.moveCaretBeforeFraction(controller.expression);
    await tester.pump();

    await _doubleTapAt(
      tester,
      _renderedFractionCharacterCenter(
        tester,
        const Key('fractionNumeratorField'),
        '12−566',
        4,
      ),
    );
    expect(controller.selectedClipboardText, '566');

    await tester.tap(_toolbarAction('カット'));
    await tester.pumpAndSettle();
    final fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(fraction.numerator, '12−');
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, '566');
  });

  testWidgets('長い分母の実描画位置で全8桁を選択しCut対象と一致する', (tester) async {
    _mockClipboard();
    final controller = CalculatorController();
    _enterFraction(controller, '12', '12345678');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    controller.moveCaretBeforeFraction(controller.expression);
    await tester.pump();

    await _doubleTapAt(
      tester,
      _renderedFractionCharacterCenter(
        tester,
        const Key('fractionDenominatorField'),
        '12345678',
        4,
      ),
    );
    expect(controller.selectedClipboardText, '12345678');

    await tester.tap(_toolbarAction('カット'));
    await tester.pumpAndSettle();
    final fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(fraction.denominator, isEmpty);
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, '12345678');
  });

  testWidgets('分数field端までのhandle移動はfield内選択を維持する', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '12−566', '12345678');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    final marker = controller.expression;
    controller.selectRange(
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.numerator,
        offset: 3,
      ),
      FractionExpressionPosition(
        marker: marker,
        field: FractionField.numerator,
        offset: 5,
      ),
    );
    await tester.pump();
    await tester.pump();

    await _dragHandle(
      tester,
      handleKey: const Key('calculatorSelectionExtentHandle'),
      destination: _renderedFractionBoundary(
        tester,
        const Key('fractionNumeratorField'),
        '12−566',
        6,
      ),
    );

    expect(controller.selectedClipboardText, '566');
    expect(
      controller.selection?.base,
      const FractionExpressionPosition(
        marker: '\uE000',
        field: FractionField.numerator,
        offset: 3,
      ),
    );
    expect(
      controller.selection?.extent,
      const FractionExpressionPosition(
        marker: '\uE000',
        field: FractionField.numerator,
        offset: 6,
      ),
    );
    expect(find.byKey(const Key('selectedFractionNode')), findsNothing);
  });

  testWidgets('長押し位置と分母caret・magnifierが同じ実文字境界を使う', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '12', '12345678');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    final boundary = _renderedFractionBoundary(
      tester,
      const Key('fractionDenominatorField'),
      '12345678',
      4,
    );

    final gesture = await tester.startGesture(boundary);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(
      controller.expressionPosition,
      const FractionExpressionPosition(
        marker: '\uE000',
        field: FractionField.denominator,
        offset: 4,
      ),
    );
    expect(find.byKey(const Key('calculatorMagnifier')), findsOneWidget);
    final caret = tester.getRect(find.byKey(const Key('fractionFieldCaret')));
    // The existing fraction caret keeps its 2 logical-pixel visual gap, and
    // both it and the paragraph are independently pixel-snapped after the
    // fraction's FittedBox transform. The resolved logical offset must still
    // be the touched boundary (offset 4), rather than drifting by characters.
    expect(caret.left, closeTo(boundary.dx, 5));

    await gesture.up();
    await tester.pumpAndSettle();
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

  testWidgets('分数全体選択中に式表示欄の白い余白をタップすると選択UIだけを解除する', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '12−566', '12345678');
    await _pumpCalculator(tester, controller, size: const Size(390, 844));
    final expressionBefore = controller.expression;
    controller.selectRange(
      const RawExpressionPosition(0),
      const RawExpressionPosition(1),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('selectedFractionNode')), findsOneWidget);
    _expectHandles();

    final expressionRect = tester.getRect(
      find.byKey(const Key('expressionText')),
    );
    await tester.tapAt(
      Offset(expressionRect.left + 12, expressionRect.bottom - 12),
    );
    await tester.pumpAndSettle();

    expect(controller.expression, expressionBefore);
    expect(controller.selection, isNull);
    expect(find.byKey(const Key('selectedFractionNode')), findsNothing);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);

    controller.moveCaretBeforeFraction(controller.expression);
    await tester.pump();
    await _doubleTapAt(
      tester,
      _renderedFractionCharacterCenter(
        tester,
        const Key('fractionNumeratorField'),
        '12−566',
        4,
      ),
    );
    expect(controller.selectedClipboardText, '566');
    _expectHandles();
  });

  testWidgets('選択中は式の文字上を1回タップすると編集せず選択UIだけを解除する', (tester) async {
    final controller = CalculatorController()
      ..pasteAtCaret('12345678901234567890');
    await _pumpCalculator(tester, controller, size: const Size(320, 844));
    final expressionBefore = controller.expression;
    controller.selectRange(
      const RawExpressionPosition(2),
      const RawExpressionPosition(18),
    );
    final caretBefore = controller.caretPosition;
    await tester.pump();
    await tester.pump();
    _expectHandles();

    await tester.tap(_expressionTextContaining('12345678901234567890'));
    await tester.pumpAndSettle();

    expect(controller.expression, expressionBefore);
    expect(controller.caretPosition, caretBefore);
    expect(controller.selection, isNull);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
  });

  testWidgets('部分選択中は計算結果上のタップで入力を変えず選択UIを解除する', (tester) async {
    final controller = CalculatorController()..pasteAtCaret('12+34');
    await _pumpCalculator(tester, controller);
    final expressionBefore = controller.expression;
    final resultBefore = controller.result;
    controller.selectRange(
      const RawExpressionPosition(0),
      const RawExpressionPosition(2),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('resultText')));
    await tester.pumpAndSettle();

    expect(controller.expression, expressionBefore);
    expect(controller.result, resultBefore);
    expect(controller.selection, isNull);
    expect(
      find.byKey(const Key('calculatorSelectionExtentHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
  });

  testWidgets('複数分数の全体選択中は履歴欄タップで選択UIだけを解除する', (tester) async {
    final controller = CalculatorController();
    _enterFraction(controller, '12', '34567890');
    controller.pasteAtCaret('+');
    _enterFraction(controller, '9876543210', '3');
    await _pumpCalculator(tester, controller);
    final expressionBefore = controller.expression;
    controller.selectRange(
      const RawExpressionPosition(0),
      RawExpressionPosition(controller.expression.length),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('selectedFractionNode')), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('historyPanel')));
    await tester.pumpAndSettle();

    expect(controller.expression, expressionBefore);
    expect(controller.selection, isNull);
    expect(find.byKey(const Key('selectedFractionNode')), findsNothing);
    expect(
      find.byKey(const Key('calculatorSelectionBaseHandle')),
      findsNothing,
    );
    expect(find.byKey(const Key('calculatorSelectionToolbar')), findsNothing);
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
