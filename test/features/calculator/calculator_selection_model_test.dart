import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';

ExpressionFractionSegment _singleFraction(CalculatorController controller) =>
    controller.displaySegments.whereType<ExpressionFractionSegment>().single;

void _enterFraction(
  CalculatorController controller,
  String numerator,
  String denominator,
) {
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

void main() {
  group('calculator expression selection model', () {
    test('raw選択は左右どちら向きでも同じ範囲を編集する', () {
      for (final positions in const [(1, 4), (4, 1)]) {
        final controller = CalculatorController()..pasteAtCaret('12+34');
        controller.selectRange(
          RawExpressionPosition(positions.$1),
          RawExpressionPosition(positions.$2),
        );

        expect(controller.selectedClipboardText, '2+3');
        controller.press('9');
        expect(controller.expression, '194');
        expect(controller.selection, isNull);
        expect(controller.expressionPosition, const RawExpressionPosition(2));
      }
    });

    test('単一キャレットの選択は直後の数字列を優先し、なければ直前を選ぶ', () {
      final right = CalculatorController()..pasteAtCaret('123+456×789');
      right.moveCaretToRawOffset(4);
      expect(right.selectNumberNearCaret(), isTrue);
      expect(right.selectedClipboardText, '456');

      final left = CalculatorController()..pasteAtCaret('123+456');
      left.moveCaretToRawOffset(3);
      expect(left.selectNumberNearCaret(), isTrue);
      expect(left.selectedClipboardText, '123');

      final none = CalculatorController()..pasteAtCaret('()+');
      none.moveCaretToRawOffset(1);
      expect(none.selectNumberNearCaret(), isFalse);
      expect(none.selection, isNull);
      expect(none.expressionPosition, const RawExpressionPosition(1));
    });

    test('分数fieldの単一キャレット選択は同じfield内だけを対象にする', () {
      final controller = CalculatorController();
      _enterFraction(controller, '23', '45');
      final marker = _singleFraction(controller).marker;
      controller.activateFraction(
        marker,
        FractionField.denominator,
        caretOffset: 0,
      );

      expect(controller.selectNumberNearCaret(), isTrue);
      expect(controller.selectedClipboardText, '45');
      expect(
        controller.selection,
        ExpressionSelection(
          base: FractionExpressionPosition(
            marker: marker,
            field: FractionField.denominator,
            offset: 0,
          ),
          extent: FractionExpressionPosition(
            marker: marker,
            field: FractionField.denominator,
            offset: 2,
          ),
        ),
      );
    });

    test('同一分数の整数部・分子・分母はfield内だけを選択できる', () {
      final controller = CalculatorController();
      for (final key in ['1', '2', 'a/b', '3', '4', 'a/b', '5', '6']) {
        controller.press(key);
      }
      final marker = _singleFraction(controller).marker;

      for (final field in FractionField.values) {
        controller.selectRange(
          FractionExpressionPosition(marker: marker, field: field, offset: 0),
          FractionExpressionPosition(marker: marker, field: field, offset: 1),
        );
        expect(controller.hasSelection, isTrue);
        expect(controller.selectedClipboardText, isNotEmpty);
        controller.clearSelection();
      }

      controller.selectRange(
        FractionExpressionPosition(
          marker: marker,
          field: FractionField.numerator,
          offset: 0,
        ),
        FractionExpressionPosition(
          marker: marker,
          field: FractionField.numerator,
          offset: 2,
        ),
      );
      controller.press('9');
      expect(_singleFraction(controller).numerator, '9');
      expect(_singleFraction(controller).denominator, '56');

      controller.selectRange(
        FractionExpressionPosition(
          marker: marker,
          field: FractionField.denominator,
          offset: 2,
        ),
        FractionExpressionPosition(
          marker: marker,
          field: FractionField.denominator,
          offset: 0,
        ),
      );
      expect(controller.selectedClipboardText, '56');
    });

    test('同一分数でもfieldを跨ぐ選択は分数全体へsnapする', () {
      final controller = CalculatorController();
      _enterFraction(controller, '2', '3');
      final fraction = _singleFraction(controller);

      controller.selectRange(
        FractionExpressionPosition(
          marker: fraction.marker,
          field: FractionField.numerator,
          offset: 1,
        ),
        FractionExpressionPosition(
          marker: fraction.marker,
          field: FractionField.denominator,
          offset: 1,
        ),
      );

      expect(
        controller.selection,
        const ExpressionSelection(
          base: RawExpressionPosition(0),
          extent: RawExpressionPosition(1),
        ),
      );
      expect(controller.selectedClipboardText, '2/3');
    });

    test('rawと分数内部を跨ぐ選択は分数全体へsnapする', () {
      final controller = CalculatorController()..pasteAtCaret('7+');
      _enterFraction(controller, '2', '3');
      controller.press('+');
      controller.press('9');
      final fraction = _singleFraction(controller);
      final markerIndex = controller.expression.indexOf(fraction.marker);

      controller.selectRange(
        const RawExpressionPosition(1),
        FractionExpressionPosition(
          marker: fraction.marker,
          field: FractionField.numerator,
          offset: 1,
        ),
      );
      expect(
        controller.selection,
        ExpressionSelection(
          base: const RawExpressionPosition(1),
          extent: RawExpressionPosition(markerIndex + 1),
        ),
      );
      expect(controller.selectedClipboardText, '+2/3');

      controller.selectRange(
        FractionExpressionPosition(
          marker: fraction.marker,
          field: FractionField.denominator,
          offset: 1,
        ),
        const RawExpressionPosition(0),
      );
      expect(
        controller.selection,
        ExpressionSelection(
          base: RawExpressionPosition(markerIndex + 1),
          extent: const RawExpressionPosition(0),
        ),
      );
      expect(controller.selectedClipboardText, '7+2/3');
    });

    test('複数分数fragmentを再貼付するとmarkerとstateを複製する', () {
      final controller = CalculatorController();
      _enterFraction(controller, '2', '3');
      controller.press('+');
      _enterFraction(controller, '4', '5');
      final originalMarkers = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .map((segment) => segment.marker)
          .toList();
      controller.selectRange(
        const RawExpressionPosition(0),
        RawExpressionPosition(controller.expression.length),
      );
      final fragment = controller.copySelectionFragment()!;
      expect(controller.selectedClipboardText, '2/3+4/5');
      expect(
        controller.selectedClipboardText.runes.any(
          (rune) => rune >= 0xE000 && rune <= 0xF8FF,
        ),
        isFalse,
      );

      controller.clearSelection();
      controller.moveCaretToRawOffset(controller.expression.length);
      controller.press('+');
      expect(controller.pasteFragment(fragment), isTrue);
      final allMarkers = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .map((segment) => segment.marker)
          .toList();
      expect(allMarkers, hasLength(4));
      expect(allMarkers.toSet(), hasLength(4));
      expect(allMarkers.skip(2), isNot(contains(anyOf(originalMarkers))));

      controller.selectRange(
        FractionExpressionPosition(
          marker: originalMarkers.first,
          field: FractionField.numerator,
          offset: 0,
        ),
        FractionExpressionPosition(
          marker: originalMarkers.first,
          field: FractionField.numerator,
          offset: 1,
        ),
      );
      controller.press('8');
      final fractions = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .toList();
      expect(fractions.first.numerator, '8');
      expect(fractions[2].numerator, '2');
    });

    test('raw範囲の分数全体削除は対応するstateも削除する', () {
      final controller = CalculatorController()..pasteAtCaret('1+');
      _enterFraction(controller, '2', '3');
      controller.press('+');
      controller.press('4');
      final marker = _singleFraction(controller).marker;
      final markerIndex = controller.expression.indexOf(marker);

      controller.selectRange(
        RawExpressionPosition(markerIndex),
        RawExpressionPosition(markerIndex + 1),
      );
      expect(controller.deleteSelection(), isTrue);

      expect(controller.expression, '1++4');
      expect(controller.fractionInputForMarker(marker), isNull);
      expect(controller.selection, isNull);
    });

    test('Cut・Backspace・Pasteは選択範囲を対象にして選択を解除する', () {
      final controller = CalculatorController()..pasteAtCaret('12345');
      controller.selectRange(
        const RawExpressionPosition(1),
        const RawExpressionPosition(4),
      );
      final fragment = controller.cutSelectionFragment()!;
      expect(fragment.expression, '234');
      expect(controller.expression, '15');
      expect(controller.selection, isNull);

      expect(controller.pasteFragment(fragment), isTrue);
      expect(controller.expression, '12345');
      controller.selectRange(
        const RawExpressionPosition(1),
        const RawExpressionPosition(4),
      );
      controller.backspace();
      expect(controller.expression, '15');
      expect(controller.selection, isNull);
    });

    test('選択範囲を演算子・関数・外部Pasteで置換する', () {
      final operator = CalculatorController()..pasteAtCaret('12+34');
      operator.selectRange(
        const RawExpressionPosition(2),
        const RawExpressionPosition(3),
      );
      operator.press('×');
      expect(operator.expression, '12×34');

      final function = CalculatorController()..pasteAtCaret('12+34');
      function.selectRange(
        const RawExpressionPosition(0),
        const RawExpressionPosition(2),
      );
      expect(function.insertFunction('sin'), isNull);
      expect(function.expression, 'sin(+34');

      final pasted = CalculatorController()..pasteAtCaret('12+34');
      pasted.selectRange(
        const RawExpressionPosition(3),
        const RawExpressionPosition(5),
      );
      expect(pasted.pasteAtCaret('56'), isTrue);
      expect(pasted.expression, '12+56');

      pasted.selectRange(
        const RawExpressionPosition(0),
        const RawExpressionPosition(2),
      );
      expect(pasted.replaceSelection('ab'), isFalse);
      expect(pasted.expression, '12+56');
      expect(pasted.hasSelection, isTrue);
    });

    test('分数Clipboardは通常・帯・負数を1行化してmarkerを露出しない', () {
      for (final value in ['2/3', '5/3', '1 2/3', '-2/3', '-1 2/3']) {
        final controller = CalculatorController();
        controller.editHistoryEntry(
          CalculationHistoryEntry(
            expression: value,
            result: '0',
            decimalResult: '0',
            createdAt: DateTime(2026),
          ),
        );
        controller.selectRange(
          const RawExpressionPosition(0),
          RawExpressionPosition(controller.expression.length),
        );
        expect(controller.selectedClipboardText, value);
      }
    });

    test('20桁選択置換・計算・Clear・履歴再編集でselectionが残らない', () {
      final controller = CalculatorController()
        ..pasteAtCaret('12345678901234567890');
      controller.selectRange(
        const RawExpressionPosition(0),
        const RawExpressionPosition(1),
      );
      controller.press('9');
      expect(controller.expression, '92345678901234567890');
      expect(controller.expression, hasLength(20));

      controller.selectRange(
        const RawExpressionPosition(0),
        const RawExpressionPosition(1),
      );
      controller.press('=');
      expect(controller.selection, isNull);
      final entry = controller.history.single;

      controller.selectRange(
        const RawExpressionPosition(0),
        const RawExpressionPosition(1),
      );
      controller.clear();
      expect(controller.selection, isNull);
      controller.editHistoryEntry(entry);
      expect(controller.selection, isNull);
    });
  });
}
