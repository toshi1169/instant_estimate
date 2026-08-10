import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/angle_unit.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/data/calculation_history_store.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

class FakeCalculationHistoryStore implements CalculationHistoryStore {
  FakeCalculationHistoryStore([List<StoredCalculationHistoryEntry>? entries])
    : entries = List.of(entries ?? const []);

  List<StoredCalculationHistoryEntry> entries;

  @override
  Future<List<StoredCalculationHistoryEntry>> load() async => List.of(entries);

  @override
  Future<void> save(List<StoredCalculationHistoryEntry> entries) async {
    this.entries = List.of(entries);
  }
}

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

    test('関数一覧から定数・平方根・階乗を入力して計算できる', () {
      final controller = CalculatorController();

      expect(controller.insertFunction('√'), isNull);
      controller.press('9');
      controller.press('()');
      controller.press('+');
      controller.press('3');
      expect(controller.insertFunction('x!'), isNull);
      controller.press('=');

      expect(controller.result, '9');
    });

    test('関数一覧から三角関数を入力して暫定・確定計算できる', () {
      final controller = CalculatorController();

      expect(controller.insertFunction('sin'), isNull);
      controller.press('3');
      controller.press('0');
      expect(controller.expression, 'sin(30');
      expect(controller.result, '0.5');
      expect(controller.isPreviewResult, isTrue);

      controller.press('=');
      expect(controller.result, '0.5');
    });

    test('角度設定をラジアンへ切り替えて再計算できる', () {
      final controller = CalculatorController();
      controller.updateDisplaySettings(
        decimalPlaces: 5,
        roundingMode: CalculatorRoundingMode.halfUp,
        angleUnit: AngleUnit.radians,
      );
      controller.insertFunction('sin');
      controller.insertFunction('π');
      controller.press('÷');
      controller.press('2');
      controller.press('=');

      expect(controller.result, '1');
    });

    test('バックボタン1回で三角関数トークン全体を削除する', () {
      final controller = CalculatorController();

      controller.insertFunction('sinh⁻¹');
      expect(controller.expression, 'sinh⁻¹(');
      controller.press('←');
      expect(controller.expression, isEmpty);
    });

    test('バックボタン1回で関数トークン全体を削除する', () {
      final controller = CalculatorController();

      controller.insertFunction('log');
      expect(controller.expression, 'log(');
      controller.press('←');
      expect(controller.expression, isEmpty);

      controller.press('4');
      controller.insertFunction('x²');
      expect(controller.expression, '4^2');
      controller.press('←');
      expect(controller.expression, '4');
    });

    test('関数の閉じカッコなしで暫定解と確定解を計算する', () {
      final controller = CalculatorController();

      controller.insertFunction('√');
      controller.press('4');

      expect(controller.expression, '√(4');
      expect(controller.result, '2');
      expect(controller.isPreviewResult, isTrue);

      controller.press('=');
      expect(controller.result, '2');
      expect(controller.state, CalculatorState.result);
    });

    test('逆数は横棒付き分数として入力する', () {
      final controller = CalculatorController();

      expect(controller.insertFunction('1/x'), isNull);
      var fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '1');
      expect(fraction.denominator, isEmpty);
      expect(fraction.activeField, FractionField.denominator);

      controller.press('4');
      fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.denominator, '4');
      expect(controller.result, '0.25');
      expect(controller.isPreviewResult, isTrue);

      controller.press('=');
      expect(controller.result, '0.25');
    });

    test('3桁以下の解には先頭カンマを表示しない', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('7.5×44');
      controller.press('=');

      expect(controller.result, '330');
    });

    test('4桁以上の解だけ正しい位置へ3桁区切りを表示する', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('7.5×440');
      controller.press('=');

      expect(controller.result, '3,300');
    });

    test('履歴の式を編集欄へ戻しても元履歴を残す', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('12×3');
      controller.press('=');
      final entry = controller.history.single;

      controller.editHistoryEntry(entry);

      expect(controller.displayExpression, '12 × 3');
      expect(controller.result, '36');
      expect(controller.state, CalculatorState.input);
      expect(controller.history, hasLength(1));
    });

    test('分数を含む履歴を横棒付き分数として編集欄へ戻す', () {
      final controller = CalculatorController();
      for (final key in ['2', '0', 'a/b', '1', 'a/b', '2', 'a/b', '=']) {
        controller.press(key);
      }
      final entry = controller.history.single;

      controller.editHistoryEntry(entry);

      expect(controller.displayExpression, '20 1/2');
      expect(
        controller.displaySegments.whereType<ExpressionFractionSegment>(),
        hasLength(1),
      );
      expect(controller.history, hasLength(1));
    });

    test('指定した履歴だけ削除する', () {
      final controller = CalculatorController();
      for (final expression in ['1+1', '2+2']) {
        controller.pasteAtCaret(expression);
        controller.press('=');
        controller.clear();
      }

      controller.deleteHistoryEntry(controller.history.first);

      expect(controller.history, hasLength(1));
      expect(controller.history.single.expression, '2 + 2');
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

    test('結果を仮分数・帯分数・小数の順に切り替える', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('2−1÷2');
      controller.press('=');

      expect(controller.result, '1.5');
      expect(controller.history.single.result, '1.5');
      expect(controller.history.single.decimalResult, '1.5');
      expect(controller.history.single.improperFractionResult, '3/2');
      expect(controller.history.single.mixedFractionResult, '1 1/2');

      controller.press('=');
      expect(controller.result, '3/2');
      expect(controller.resultDisplayMode, ResultDisplayMode.improperFraction);

      controller.press('a/b');
      expect(controller.result, '1 1/2');
      expect(controller.resultDisplayMode, ResultDisplayMode.mixedFraction);

      controller.press('=');
      expect(controller.result, '1.5');
      expect(controller.resultDisplayMode, ResultDisplayMode.decimal);
      expect(controller.history, hasLength(1));
      expect(controller.history.single.result, '1.5');
    });

    test('分数化できない解では案内を返す', () {
      final controller = CalculatorController();
      controller.press('2');
      controller.press('=');

      expect(controller.press('a/b'), '分数に変換できません');
      expect(controller.result, '2');
    });

    test('仮分数表示から四則演算を続けても分数を式へ維持する', () {
      for (final operator in ['+', '−', '×', '÷']) {
        final controller = CalculatorController();
        controller.pasteAtCaret('2−1÷2');
        controller.press('=');
        controller.press('=');

        controller.press(operator);

        expect(controller.displayExpression, '3/2 $operator');
        expect(controller.state, CalculatorState.input);
      }
    });

    test('帯分数表示から演算を続けても帯分数を式へ維持する', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('2−1÷2');
      controller.press('=');
      controller.press('=');
      controller.press('=');

      controller.press('+');
      controller.press('1');
      controller.press('=');

      expect(controller.displayExpression, '1 1/2 + 1');
      expect(controller.result, '2.5');
    });

    test('負の帯分数表示からも正しい値で計算を続けられる', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('1÷2−2');
      controller.press('=');
      controller.press('=');
      controller.press('=');

      controller.press('+');
      controller.press('1');
      controller.press('=');

      expect(controller.displayExpression, '-1 1/2 + 1');
      expect(controller.result, '-0.5');
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

    test('分子と分母の中で四則演算を計算できる', () {
      final controller = CalculatorController();
      for (final key in [
        'a/b',
        '1',
        '+',
        '2',
        'a/b',
        '3',
        '×',
        '2',
        'a/b',
        '=',
      ]) {
        controller.press(key);
      }

      expect(controller.displayExpression, '(1+2)/(3×2)');
      expect(controller.result, '0.5');
    });

    test('分子と分母の中で括弧と平方根を計算できる', () {
      final controller = CalculatorController();
      for (final key in ['a/b', '()', '1', '+', '2', '()', 'a/b']) {
        controller.press(key);
      }
      expect(controller.insertFunction('√'), isNull);
      for (final key in ['3', '6', 'a/b', '=']) {
        controller.press(key);
      }

      expect(controller.displayExpression, '((1+2))/(√(36)');
      expect(controller.result, '0.5');
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

    test('分子と分母は10桁まで入力でき11桁目を通知する', () {
      final controller = CalculatorController();
      controller.press('a/b');

      String? notice;
      for (var index = 0; index < 11; index++) {
        notice = controller.press('1');
      }
      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;

      expect(fraction.numerator, '1111111111');
      expect(notice, 'これ以上入力できません');
    });

    test('分数内の演算子は10桁の入力上限に数えない', () {
      final controller = CalculatorController();
      controller.press('a/b');
      for (final key in [
        '1',
        '2',
        '3',
        '4',
        '5',
        '+',
        '6',
        '7',
        '8',
        '9',
        '0',
      ]) {
        expect(controller.press(key), isNull);
      }

      expect(controller.press('1'), 'これ以上入力できません');
      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '12345+67890');
    });

    test('1京を超える解は10のべき乗で表示する', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('10000000000000000×10');
      controller.press('=');

      expect(controller.result, '1 × 10¹⁷');
    });

    test('計算可能な入力途中では暫定解を表示する', () {
      final controller = CalculatorController();
      for (final key in ['1', '2', '+', '3']) {
        controller.press(key);
      }

      expect(controller.result, '15');
      expect(controller.state, CalculatorState.input);
      expect(controller.isPreviewResult, isTrue);

      controller.press('=');

      expect(controller.result, '15');
      expect(controller.state, CalculatorState.result);
      expect(controller.isPreviewResult, isFalse);
    });

    test('分子と分母の指定した桁へ数字を挿入できる', () {
      final controller = CalculatorController();
      for (final key in ['a/b', '1', '2', '3', 'a/b', '4', '5', '6']) {
        controller.press(key);
      }
      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;

      controller.activateFraction(
        fraction.marker,
        FractionField.numerator,
        caretOffset: 1,
      );
      controller.press('9');
      controller.activateFraction(
        fraction.marker,
        FractionField.denominator,
        caretOffset: 2,
      );
      controller.press('8');

      expect(controller.displayExpression, '1923/4586');
    });

    test('帯分数の整数部分の指定した桁へ数字を挿入できる', () {
      final controller = CalculatorController();
      for (final key in ['2', '0', 'a/b', '1', 'a/b', '2']) {
        controller.press(key);
      }
      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;

      controller.activateFraction(
        fraction.marker,
        FractionField.wholeNumber,
        caretOffset: 1,
      );
      controller.press('9');

      expect(controller.displayExpression, '290 1/2');
    });

    test('計算履歴を端末保存用ストアへ保存する', () async {
      final store = FakeCalculationHistoryStore();
      final controller = CalculatorController(historyStore: store);
      await controller.loadHistory();

      controller.pasteAtCaret('1+2');
      controller.press('=');
      await pumpEventQueue();

      expect(store.entries, hasLength(1));
      expect(store.entries.single.expression, '1 + 2');
      expect(store.entries.single.result, '3');
    });

    test('保存済み履歴と計算日時を新しい電卓へ復元する', () async {
      final createdAt = DateTime(2026, 7, 31, 11, 30);
      final store = FakeCalculationHistoryStore([
        StoredCalculationHistoryEntry(
          expression: '2 − 1 ÷ 2',
          result: '1.5',
          decimalResult: '1.5',
          improperFractionResult: '3/2',
          mixedFractionResult: '1 1/2',
          createdAt: createdAt,
        ),
      ]);
      final controller = CalculatorController(historyStore: store);

      await controller.loadHistory();

      expect(controller.history, hasLength(1));
      expect(controller.history.single.improperFractionResult, '3/2');
      expect(controller.history.single.createdAt, createdAt);
    });

    test('履歴削除を端末保存用ストアへ反映する', () async {
      final store = FakeCalculationHistoryStore([
        StoredCalculationHistoryEntry(
          expression: '1 + 2',
          result: '3',
          decimalResult: '3',
          createdAt: DateTime(2026, 7, 31),
        ),
      ]);
      final controller = CalculatorController(historyStore: store);
      await controller.loadHistory();

      controller.deleteHistoryEntry(controller.history.single);
      await pumpEventQueue();

      expect(store.entries, isEmpty);
    });

    test('小数桁と丸め方法は表示だけへ適用する', () {
      final controller = CalculatorController();
      controller.updateDisplaySettings(
        decimalPlaces: 2,
        roundingMode: CalculatorRoundingMode.halfUp,
      );
      controller.pasteAtCaret('2/3');
      controller.press('=');
      expect(controller.result, '0.67');

      controller.clear();
      controller.updateDisplaySettings(
        decimalPlaces: 2,
        roundingMode: CalculatorRoundingMode.floor,
      );
      controller.pasteAtCaret('2/3');
      controller.press('=');
      expect(controller.result, '0.66');

      controller.clear();
      controller.updateDisplaySettings(
        decimalPlaces: 2,
        roundingMode: CalculatorRoundingMode.ceiling,
      );
      controller.pasteAtCaret('1/3');
      controller.press('=');
      expect(controller.result, '0.34');
    });

    test('履歴をすべて削除して端末保存へ反映する', () async {
      final store = FakeCalculationHistoryStore([
        StoredCalculationHistoryEntry(
          expression: '1 + 2',
          result: '3',
          decimalResult: '3',
          createdAt: DateTime(2026, 8, 2),
        ),
      ]);
      final controller = CalculatorController(historyStore: store);
      await controller.loadHistory();

      await controller.clearHistory();

      expect(controller.history, isEmpty);
      expect(store.entries, isEmpty);
    });
  });
}
