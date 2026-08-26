import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/theme/app_theme.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';

void main() {
  testWidgets('無料版はiPhone 11 Proで履歴3行とキー下端を維持する', (tester) async {
    const device = _TestDevice(
      size: Size(375, 812),
      topInset: 44,
      bottomInset: 34,
    );
    final withAds = await _pumpCalculator(tester, device: device, ads: true);

    expect(withAds.history.height, closeTo(82, 0.01));
    expect(_visibleHistoryRowCount(withAds.history), 3);
    expect(withAds.calculation.height, closeTo(201.54, 0.1));
    expect(withAds.keypad.top, closeTo(401.54, 0.1));
    expect(withAds.keypad.bottom, closeTo(772, 0.01));
    expect(withAds.firstButton.width, closeTo(86.25, 0.01));
    expect(withAds.firstButton.height, closeTo(56.74, 0.01));
    expect(withAds.safeBottom - withAds.lastButton.bottom, closeTo(6, 0.01));
    expect(withAds.lastButton.bottom, lessThanOrEqualTo(withAds.safeBottom));
    expect(withAds.banner, isNotNull);
    expect(withAds.banner!.bottom, lessThanOrEqualTo(withAds.history.top));
    expect(withAds.expressionFontSize, 42);
    expect(withAds.resultFontSize, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有料版はiPhone 11 Proで履歴を5行へ拡張する', (tester) async {
    const device = _TestDevice(
      size: Size(375, 812),
      topInset: 44,
      bottomInset: 34,
    );
    final withoutAds = await _pumpCalculator(
      tester,
      device: device,
      ads: false,
    );

    expect(withoutAds.banner, isNull);
    expect(withoutAds.history.height, closeTo(130, 0.01));
    expect(_visibleHistoryRowCount(withoutAds.history), 5);
    expect(withoutAds.calculation.height, closeTo(215.54, 0.1));
    expect(withoutAds.keypad.top, closeTo(401.54, 0.1));
    expect(withoutAds.keypad.bottom, closeTo(772, 0.01));
    expect(
      withoutAds.safeBottom - withoutAds.lastButton.bottom,
      closeTo(6, 0.01),
    );
    expect(withoutAds.expressionFontSize, 42);
    expect(withoutAds.resultFontSize, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPhone 17で広告なしは履歴2行分広くキー位置は変わらない', (tester) async {
    const device = _TestDevice(
      size: Size(402, 874),
      topInset: 62,
      bottomInset: 34,
    );
    final withAds = await _pumpCalculator(tester, device: device, ads: true);
    final withoutAds = await _pumpCalculator(
      tester,
      device: device,
      ads: false,
    );

    expect(withAds.firstButton.width, closeTo(93, 0.01));
    expect(withAds.firstButton.height, closeTo(61.18, 0.01));
    expect(withAds.safeBottom - withAds.lastButton.bottom, closeTo(6, 0.01));
    expect(withAds.history.height, closeTo(82, 0.01));
    expect(withoutAds.history.height, closeTo(130, 0.01));
    expect(_visibleHistoryRowCount(withAds.history), 3);
    expect(_visibleHistoryRowCount(withoutAds.history), 5);
    expect(
      withoutAds.history.height - withAds.history.height,
      closeTo(48, 0.01),
    );
    expect(withAds.calculation.height, closeTo(218.89, 0.1));
    expect(withoutAds.calculation.height, closeTo(232.89, 0.1));
    expect(withAds.calculation.bottom, closeTo(432.89, 0.1));
    expect(
      withoutAds.calculation.bottom,
      closeTo(withAds.calculation.bottom, 0.01),
    );
    expect(withoutAds.keypad, equals(withAds.keypad));
    expect(withAds.keypad.top, closeTo(436.89, 0.1));
    expect(withAds.keypad.bottom, closeTo(834, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('小さい画面でも最下段が見切れず横Overflowを発生させない', (tester) async {
    const device = _TestDevice(
      size: Size(320, 568),
      topInset: 20,
      bottomInset: 0,
    );
    for (final ads in [true, false]) {
      final layout = await _pumpCalculator(tester, device: device, ads: ads);
      expect(layout.safeBottom - layout.lastButton.bottom, closeTo(4, 0.1));
      expect(layout.firstButton.left, greaterThanOrEqualTo(4));
      expect(layout.lastRowRight, lessThanOrEqualTo(device.size.width - 4));
      expect(layout.history.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    }
  });

  for (final device in const [
    _TestDevice(size: Size(375, 812), topInset: 44, bottomInset: 34),
    _TestDevice(size: Size(402, 874), topInset: 62, bottomInset: 34),
    _TestDevice(size: Size(320, 812), topInset: 44, bottomInset: 34),
  ]) {
    testWidgets('${device.size.width.toInt()}px幅で1～20桁分数のキャレットが枠内に収まる', (
      tester,
    ) async {
      for (final length in [1, 10, 11, 19, 20]) {
        final controller = CalculatorController();
        addTearDown(controller.dispose);
        final numerator = List.filled(length, '1').join();
        final denominator = List.filled(length, '2').join();
        controller.press('a/b');
        for (final digit in numerator.split('')) {
          controller.press(digit);
        }
        controller.press('a/b');
        for (final digit in denominator.split('')) {
          controller.press(digit);
        }

        await _pumpFractionCalculator(
          tester,
          device: device,
          controller: controller,
        );
        _expectCaretInside(tester, const Key('fractionDenominatorField'));

        final segment = controller.displaySegments
            .whereType<ExpressionFractionSegment>()
            .single;
        controller.activateFraction(
          segment.marker,
          FractionField.numerator,
          caretOffset: segment.numerator.length,
        );
        await tester.pump();
        _expectCaretInside(tester, const Key('fractionNumeratorField'));

        final numeratorText = tester.widget<Text>(
          find
              .descendant(
                of: find.byKey(const Key('fractionNumeratorField')),
                matching: find.text(numerator),
              )
              .first,
        );
        expect(numeratorText.style?.fontSize, 42);
        expect(tester.takeException(), isNull, reason: '$length digits');
      }
    });
  }

  testWidgets('10→11桁と19→20桁で表示とキャレットが同一pumpで追従する', (tester) async {
    const device = _TestDevice(
      size: Size(375, 812),
      topInset: 44,
      bottomInset: 34,
    );
    final controller = CalculatorController()..press('a/b');
    addTearDown(controller.dispose);
    await _pumpFractionCalculator(
      tester,
      device: device,
      controller: controller,
    );

    void expectCurrentFrame({required Key fieldKey, required String value}) {
      final textFinder = find.descendant(
        of: find.byKey(fieldKey),
        matching: find.text(value),
      );
      expect(textFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(textFinder);
      final renderParagraph = tester.renderObject<RenderParagraph>(textFinder);
      expect(textWidget.data, value);
      expect(renderParagraph.text.toPlainText(), value);
      final painter = TextPainter(
        text: TextSpan(text: value, style: textWidget.style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      expect(painter.text!.toPlainText(), value);
      final textRect = tester.getRect(textFinder);
      final caretRect = tester.getRect(
        find.byKey(const Key('fractionFieldCaret')),
      );
      final fittedBox = tester.renderObject<RenderFittedBox>(
        find.byKey(const Key('expressionLineScale-0')),
      );
      final scale = fittedBox.child!.getTransformTo(fittedBox).storage[0];
      expect((caretRect.left - textRect.right) / scale, closeTo(2, 0.01));
      _expectCaretInside(tester, fieldKey);
    }

    for (var index = 1; index <= 20; index++) {
      await tester.tap(
        find.widgetWithText(FilledButton, (index % 10).toString()).first,
      );
      await tester.pump();
      final expected = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single
          .numerator;
      final segment = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(expected.length, index);
      expect(identical(segment.input, controller.activeFractionInput), isTrue);
      expectCurrentFrame(
        fieldKey: const Key('fractionNumeratorField'),
        value: expected,
      );
      expect(tester.takeException(), isNull, reason: '$index digits');
    }
    await tester.tap(find.widgetWithText(FilledButton, '1').first);
    await tester.pump();
    var fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(fraction.numerator.length, 20);
    expectCurrentFrame(
      fieldKey: const Key('fractionNumeratorField'),
      value: fraction.numerator,
    );
    expect(
      tester.getSize(find.byKey(const Key('fractionNumeratorCaretSlot'))),
      tester.getSize(find.byKey(const Key('fractionDenominatorCaretSlot'))),
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(const Key('fractionDenominatorCaretSlot')),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0,
    );

    await tester.tap(find.bySemanticsLabel('a/b'));
    await tester.pump();
    for (var index = 1; index <= 20; index++) {
      await tester.tap(
        find.widgetWithText(FilledButton, ((index + 4) % 10).toString()).first,
      );
      await tester.pump();
      final expected = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single
          .denominator;
      final segment = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(expected.length, index);
      expect(identical(segment.input, controller.activeFractionInput), isTrue);
      expect(
        identical(
          segment.input,
          controller.fractionInputForEvaluation(segment.marker),
        ),
        isTrue,
      );
      expectCurrentFrame(
        fieldKey: const Key('fractionDenominatorField'),
        value: expected,
      );
      expect(tester.takeException(), isNull, reason: '$index digits');
    }
    await tester.tap(find.widgetWithText(FilledButton, '2').first);
    await tester.pump();
    fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(fraction.denominator.length, 20);
    expectCurrentFrame(
      fieldKey: const Key('fractionDenominatorField'),
      value: fraction.denominator,
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(const Key('fractionNumeratorCaretSlot')),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0,
    );
  });

  testWidgets('実機再現3ケースで分数表示・入力状態・評価式が一致する', (tester) async {
    const device = _TestDevice(
      size: Size(375, 812),
      topInset: 44,
      bottomInset: 34,
    );

    Future<CalculatorController> enterFraction(
      String numerator,
      String denominator,
    ) async {
      final controller = CalculatorController();
      addTearDown(controller.dispose);
      await _pumpFractionCalculator(
        tester,
        device: device,
        controller: controller,
      );
      await tester.tap(find.bySemanticsLabel('a/b'));
      await tester.pump();
      for (final character in numerator.split('')) {
        await tester.tap(find.widgetWithText(FilledButton, character).first);
        await tester.pump();
      }
      await tester.tap(find.bySemanticsLabel('a/b'));
      await tester.pump();
      for (final character in denominator.split('')) {
        await tester.tap(find.widgetWithText(FilledButton, character).first);
        await tester.pump();
      }
      return controller;
    }

    void expectDisplayedFraction(
      CalculatorController controller, {
      required String numerator,
      required String denominator,
    }) {
      final segment = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(
        _displayedFieldText(tester, const Key('fractionNumeratorField')),
        numerator,
      );
      expect(
        _displayedFieldText(tester, const Key('fractionDenominatorField')),
        denominator,
      );
      expect(segment.numerator, numerator);
      expect(segment.denominator, denominator);
      final evaluation = controller.fractionInputForEvaluation(segment.marker);
      expect(evaluation.numeratorText, numerator);
      expect(evaluation.denominatorText, denominator);
      expect(identical(segment.input, evaluation), isTrue);
      expect(tester.takeException(), isNull);
    }

    var controller = await enterFraction('1234567890', '1234567890');
    expectDisplayedFraction(
      controller,
      numerator: '1234567890',
      denominator: '1234567890',
    );
    expect(
      controller.fractionExpressionForEvaluation(
        controller.displaySegments
            .whereType<ExpressionFractionSegment>()
            .single
            .marker,
      ),
      '((1)÷(1))',
    );

    controller = await enterFraction('12345678901', '123456789012');
    expectDisplayedFraction(
      controller,
      numerator: '12345678901',
      denominator: '123456789012',
    );
    var segment = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(
      controller.fractionExpressionForEvaluation(segment.marker),
      '((12345678901)÷(123456789012))',
    );

    controller = await enterFraction('123456789+5', '1234567890');
    expectDisplayedFraction(
      controller,
      numerator: '123456789+5',
      denominator: '1234567890',
    );
    segment = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(
      controller.fractionExpressionForEvaluation(segment.marker),
      '((123456789+5)÷(1234567890))',
    );
    controller.press('=');
    // The screen fixture uses one decimal place; the exact evaluation source
    // above proves that the visible trailing 5 participates in calculation.
    expect(controller.result, '0.1');
  });

  testWidgets('1・2行は常時表示し3行以上は計算式だけ縦スクロールする', (tester) async {
    const device = _TestDevice(
      size: Size(375, 812),
      topInset: 44,
      bottomInset: 34,
    );
    final controller = CalculatorController();
    addTearDown(controller.dispose);
    await _pumpFractionCalculator(
      tester,
      device: device,
      controller: controller,
    );

    controller.pasteAtCaret('1234567890+1');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expressionLine-0')), findsOneWidget);
    expect(find.byKey(const Key('expressionLine-1')), findsOneWidget);
    var scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('expressionVerticalScroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, 0);

    controller.clear();
    controller.pasteAtCaret('1234567890+1234567890+1234567890');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expressionLine-2')), findsOneWidget);
    scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('expressionVerticalScroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    controller.clear();
    controller.pasteAtCaret('1234567890+1234567890+1234567890+1234567890');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('expressionLine-0')), findsOneWidget);
    expect(find.byKey(const Key('expressionLine-3')), findsOneWidget);
    scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const Key('expressionVerticalScroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(
      scrollable.position.pixels,
      closeTo(scrollable.position.maxScrollExtent, 0.01),
    );
    expect(find.byKey(const Key('resultText')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('20桁分数は不可分Widgetのまま等比縮小されOverflowしない', (tester) async {
    const device = _TestDevice(
      size: Size(320, 812),
      topInset: 44,
      bottomInset: 34,
    );
    final controller = CalculatorController()..press('a/b');
    for (final digit in '12345678901234567890'.split('')) {
      controller.press(digit);
    }
    controller.press('a/b');
    for (final digit in '98765432109876543210'.split('')) {
      controller.press(digit);
    }
    addTearDown(controller.dispose);
    await _pumpFractionCalculator(
      tester,
      device: device,
      controller: controller,
    );

    expect(find.byKey(const Key('fractionNumeratorField')), findsOneWidget);
    expect(find.byKey(const Key('fractionDenominatorField')), findsOneWidget);
    expect(find.byKey(const Key('expressionLine-0')), findsOneWidget);
    final fittedBox = tester.renderObject<RenderFittedBox>(
      find.byKey(const Key('expressionLineScale-0')),
    );
    final transform = fittedBox.child!.getTransformTo(fittedBox);
    expect(transform.storage[0], lessThan(1));
    expect(transform.storage[0], closeTo(transform.storage[5], 0.0001));
    _expectCaretInside(tester, const Key('fractionDenominatorField'));
    expect(tester.takeException(), isNull);
  });
}

void _expectCaretInside(WidgetTester tester, Key fieldKey) {
  final field = tester.getRect(find.byKey(fieldKey));
  final caret = tester.getRect(find.byKey(const Key('fractionFieldCaret')));
  expect(caret.left, greaterThanOrEqualTo(field.left));
  expect(caret.right, lessThanOrEqualTo(field.right));
  expect(caret.top, greaterThanOrEqualTo(field.top));
  expect(caret.bottom, lessThanOrEqualTo(field.bottom));
}

String _displayedFieldText(WidgetTester tester, Key fieldKey) {
  return tester
      .widgetList<Text>(
        find.descendant(of: find.byKey(fieldKey), matching: find.byType(Text)),
      )
      .map((text) => text.data ?? '')
      .join();
}

Future<void> _pumpFractionCalculator(
  WidgetTester tester, {
  required _TestDevice device,
  required CalculatorController controller,
}) async {
  tester.view.physicalSize = device.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: device.size,
          padding: EdgeInsets.only(
            top: device.topInset,
            bottom: device.bottomInset,
          ),
        ),
        child: CalculatorScreen(
          key: ValueKey(controller),
          controller: controller,
          accessPlan: AppAccessPlan.adFree,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

int _visibleHistoryRowCount(Rect history) {
  const rowHeight = 24.0;
  const verticalPadding = 5.0;
  return ((history.height - verticalPadding * 2) / rowHeight).floor();
}

Future<_LayoutSnapshot> _pumpCalculator(
  WidgetTester tester, {
  required _TestDevice device,
  required bool ads,
}) async {
  tester.view.physicalSize = device.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = CalculatorController()..press('1');
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: device.size,
          padding: EdgeInsets.only(
            top: device.topInset,
            bottom: device.bottomInset,
          ),
        ),
        child: CalculatorScreen(
          controller: controller,
          accessPlan: ads ? AppAccessPlan.free : AppAccessPlan.adFree,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final expressionText = tester.widget<Text>(
    find
        .descendant(
          of: find.byKey(const Key('expressionText')),
          matching: find.byType(Text),
        )
        .first,
  );
  final resultText = tester.widget<Text>(find.byKey(const Key('resultText')));
  final bannerFinder = find.byKey(const Key('calculatorAdBanner'));
  return _LayoutSnapshot(
    firstButton: tester.getRect(find.byKey(const Key('calculatorKey^'))),
    lastButton: tester.getRect(find.byKey(const Key('calculatorKey0'))),
    lastRowRight: tester.getRect(find.byKey(const Key('calculatorKey='))).right,
    history: tester.getRect(find.byKey(const Key('historyPanel'))),
    calculation: tester.getRect(find.byKey(const Key('calculationSpace'))),
    keypad: tester.getRect(find.byKey(const Key('calculatorKeypadArea'))),
    banner: bannerFinder.evaluate().isEmpty
        ? null
        : tester.getRect(bannerFinder),
    safeBottom: device.size.height - device.bottomInset,
    expressionFontSize: expressionText.style?.fontSize,
    resultFontSize: resultText.style?.fontSize,
  );
}

class _TestDevice {
  const _TestDevice({
    required this.size,
    required this.topInset,
    required this.bottomInset,
  });

  final Size size;
  final double topInset;
  final double bottomInset;
}

class _LayoutSnapshot {
  const _LayoutSnapshot({
    required this.firstButton,
    required this.lastButton,
    required this.lastRowRight,
    required this.history,
    required this.calculation,
    required this.keypad,
    required this.banner,
    required this.safeBottom,
    required this.expressionFontSize,
    required this.resultFontSize,
  });

  final Rect firstButton;
  final Rect lastButton;
  final double lastRowRight;
  final Rect history;
  final Rect calculation;
  final Rect keypad;
  final Rect? banner;
  final double safeBottom;
  final double? expressionFontSize;
  final double? resultFontSize;
}
