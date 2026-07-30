import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';

void main() {
  group('CalculatorController', () {
    test('入力した式を計算して履歴へ追加する', () {
      final controller = CalculatorController();

      for (final key in ['1', '2', '.', '5', '+', '3', '.', '5', '=']) {
        controller.press(key);
      }

      expect(controller.result, '16');
      expect(controller.state, CalculatorState.result);
      expect(controller.showCaret, isFalse);
      expect(controller.history, hasLength(1));
      expect(controller.history.single.expression, '12.5 + 3.5');
    });

    test('計算結果から演算を続けられる', () {
      final controller = CalculatorController();

      for (final key in ['8', '÷', '2', '=', '+', '3', '=']) {
        controller.press(key);
      }

      expect(controller.result, '7');
      expect(controller.history, hasLength(2));
    });

    test('バックボタンは入力中の末尾を削除する', () {
      final controller = CalculatorController();
      controller.press('1');
      controller.press('2');
      controller.press('←');

      expect(controller.expression, '1');
    });

    test('キャレット位置へ数字を挿入できる', () {
      final controller = CalculatorController();
      for (final key in ['1', '2', '+', '3']) {
        controller.press(key);
      }

      controller.moveCaretToDisplayOffset(1);
      controller.press('9');

      expect(controller.expression, '192+3');
      expect(controller.caretPosition, 2);
    });

    test('バックボタンはキャレット左側の1文字を削除する', () {
      final controller = CalculatorController();
      for (final key in ['1', '2', '3']) {
        controller.press(key);
      }

      controller.moveCaretToDisplayOffset(2);
      controller.backspace();

      expect(controller.expression, '13');
      expect(controller.caretPosition, 1);
    });

    test('長押し削除はキャレット左側をすべて削除する', () {
      final controller = CalculatorController();
      for (final key in ['1', '2', '+', '3', '4']) {
        controller.press(key);
      }

      controller.moveCaretToDisplayOffset(5);
      controller.clearLeftOfCaret();

      expect(controller.expression, '34');
      expect(controller.caretPosition, 0);
    });

    test('クリップボードの計算式をキャレット位置へ貼り付ける', () {
      final controller = CalculatorController();

      expect(controller.pasteAtCaret('12 * 3'), isTrue);
      controller.press('=');

      expect(controller.expression, '12×3');
      expect(controller.result, '36');
    });

    test('計算に使えない文字だけの場合は貼り付けない', () {
      final controller = CalculatorController();

      expect(controller.pasteAtCaret('見積書'), isFalse);
      expect(controller.expression, isEmpty);
    });

    test('クリアは式と結果を初期化する', () {
      final controller = CalculatorController();
      controller.press('9');
      controller.press('=');
      controller.clear();

      expect(controller.expression, isEmpty);
      expect(controller.result, '0');
      expect(controller.state, CalculatorState.input);
    });

    test('分数化可能な結果では切替可能状態になる', () {
      final controller = CalculatorController();
      for (final key in ['1', '1', '.', '3', '7', '5', '=']) {
        controller.press(key);
      }

      expect(controller.canCycleFraction, isTrue);
    });

    test('a/bボタンで通常分数を入力して計算できる', () {
      final controller = CalculatorController();
      for (final key in ['a/b', '1', 'a/b', '2', 'a/b', '=']) {
        controller.press(key);
      }

      expect(controller.displayExpression, '1/2');
      expect(controller.result, '0.5');
    });

    test('直前の整数を帯分数として保持して計算できる', () {
      final controller = CalculatorController();
      for (final key in ['1', 'a/b', '1', 'a/b', '2', 'a/b', '=']) {
        controller.press(key);
      }

      expect(controller.displayExpression, '1 1/2');
      expect(controller.result, '1.5');
    });

    test('帯分数と通常分数を含む式を計算できる', () {
      final controller = CalculatorController();
      const keys = [
        '1',
        'a/b',
        '1',
        'a/b',
        '2',
        'a/b',
        '×',
        '()',
        '2',
        'a/b',
        '2',
        'a/b',
        '3',
        'a/b',
        '+',
        'a/b',
        '3',
        'a/b',
        '4',
        'a/b',
        '()',
        '÷',
        '2',
        '=',
      ];
      for (final key in keys) {
        controller.press(key);
      }

      expect(controller.result, '2.5625');
    });

    test('空の分数枠はバックボタンで枠ごと削除する', () {
      final controller = CalculatorController();
      controller.press('a/b');
      controller.press('←');

      expect(controller.expression, isEmpty);
      expect(controller.isEditingFraction, isFalse);
    });

    test('分数の分子と分母をタップ対象として切り替えられる', () {
      final controller = CalculatorController();
      controller.press('a/b');
      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;

      controller.activateFraction(fraction.marker, FractionField.denominator);
      controller.press('5');

      expect(controller.displayExpression, '□/5');
    });

    test('帯分数の左側で数字を入力すると掛け算として扱う', () {
      final controller = CalculatorController();
      for (final key in ['2', '0', 'a/b', '5', 'a/b', '1', '0', 'a/b']) {
        controller.press(key);
      }
      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;

      controller.moveCaretBeforeFraction(fraction.marker);
      for (final key in ['8', '5', '4']) {
        controller.press(key);
      }
      controller.press('=');

      expect(controller.displayExpression, '854 × 20 5/10');
      expect(controller.result, '17,507');
    });
  });
}
