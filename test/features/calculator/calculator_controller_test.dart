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

    test('クリアは式と解を空欄へ戻す', () {
      final controller = CalculatorController();
      controller.press('9');
      controller.press('=');
      controller.clear();

      expect(controller.expression, isEmpty);
      expect(controller.result, isEmpty);
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

    test('分子と分母は20桁まで入力でき21桁目を通知する', () {
      final controller = CalculatorController();
      controller.press('a/b');

      String? notice;
      for (var index = 0; index < 21; index++) {
        notice = controller.press('1');
      }
      var fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;

      expect(fraction.numerator, '11111111111111111111');
      expect(notice, '最大20桁まで入力できます');

      controller.press('a/b');
      notice = null;
      for (var index = 0; index < 21; index++) {
        notice = controller.press('2');
      }
      fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.denominator, '22222222222222222222');
      expect(notice, '最大20桁まで入力できます');
    });

    test('分子と分母の1・10・11・19・20桁を保持する', () {
      for (final length in [1, 10, 11, 19, 20]) {
        final controller = CalculatorController();
        controller.press('a/b');
        for (var index = 0; index < length; index++) {
          controller.press('1');
        }
        controller.press('a/b');
        for (var index = 0; index < length; index++) {
          controller.press('2');
        }

        final fraction = controller.displaySegments
            .whereType<ExpressionFractionSegment>()
            .single;
        expect(fraction.numerator, List.filled(length, '1').join());
        expect(fraction.denominator, List.filled(length, '2').join());
      }
    });

    test('分数全体の先頭マイナスを桁数に含めず数字20桁を保持する', () {
      final controller = CalculatorController();
      controller.press('a/b');
      controller.press('−');
      controller.press('−');
      for (var index = 0; index < 20; index++) {
        expect(controller.press('1'), isNull);
      }
      expect(controller.press('1'), '最大20桁まで入力できます');

      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '11111111111111111111');
      expect(controller.expression.startsWith('−'), isTrue);
      expect(controller.expression.split('−'), hasLength(2));
    });

    test('マイナス分数は分子・分母内ではなく分数全体の前へ置く', () {
      final controller = CalculatorController();
      for (final key in ['a/b', '−', '1', 'a/b', '2', '=']) {
        controller.press(key);
      }

      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '1');
      expect(fraction.denominator, '2');
      expect(controller.displayExpression, '− 1/2');
      expect(controller.result, '-0.5');
    });

    test('分数内の演算子と小数点は20桁の入力上限に数えない', () {
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
        '.',
        '1',
      ]) {
        expect(controller.press(key), isNull);
      }

      for (var index = 0; index < 9; index++) {
        expect(controller.press('2'), isNull);
      }
      expect(controller.press('2'), '最大20桁まで入力できます');
      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '12345+67890.1222222222');
    });

    test('分子と分母の小数入力を保持し整数比として正規化する', () {
      for (final values in [
        ('1.5', '2.5', '0.6'),
        ('1.50', '2.50', '0.6'),
        ('0.5', '2', '0.25'),
        ('2', '0.5', '4'),
      ]) {
        final controller = CalculatorController();
        controller.press('a/b');
        for (final character in values.$1.split('')) {
          controller.press(character);
        }
        controller.press('a/b');
        for (final character in values.$2.split('')) {
          controller.press(character);
        }

        final displayedNumerator = values.$1.contains('.')
            ? '(${values.$1})'
            : values.$1;
        final displayedDenominator = values.$2.contains('.')
            ? '(${values.$2})'
            : values.$2;
        expect(
          controller.displayExpression,
          '$displayedNumerator/$displayedDenominator',
        );
        controller.press('=');
        expect(controller.result, values.$3);
      }
    });

    test('小数分数の入力中は末尾0を保持し結果だけ約分する', () {
      final controller = CalculatorController();
      for (final key in [
        'a/b',
        '1',
        '.',
        '5',
        '0',
        'a/b',
        '2',
        '.',
        '5',
        '0',
      ]) {
        controller.press(key);
      }

      expect(controller.displayExpression, '(1.50)/(2.50)');
      controller.press('=');
      controller.press('=');
      expect(controller.result, '3/5');
    });

    test('先頭小数点は0.として入力し小数点は各数値に1つだけ', () {
      final controller = CalculatorController();
      controller.press('a/b');
      controller.press('.');
      controller.press('5');
      controller.press('.');

      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '0.5');
    });

    test('小数点を除く数字20桁を許可して21桁目を拒否する', () {
      final controller = CalculatorController();
      controller.press('a/b');
      for (final character in '1234567890.1234567890'.split('')) {
        expect(controller.press(character), isNull);
      }
      expect(controller.press('2'), '最大20桁まで入力できます');

      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '1234567890.1234567890');
    });

    test('通常数値は小数点を除く20桁を保持し21桁目を拒否する', () {
      final controller = CalculatorController();
      for (final character in '1234567890.1234567890'.split('')) {
        expect(controller.press(character), isNull);
      }

      expect(controller.expression, '1234567890.1234567890');
      expect(controller.press('1'), '最大20桁まで入力できます');
      expect(controller.expression, '1234567890.1234567890');
    });

    test('20桁の四則演算はBigInt比の経路で精度を維持する', () {
      final addition = CalculatorController();
      addition.pasteAtCaret('12345678901234567890+12345678901234567890');
      addition.press('=');
      expect(addition.result, '24,691,357,802,469,135,780');

      final multiplication = CalculatorController();
      multiplication.pasteAtCaret('12345678901234567890×2');
      multiplication.press('=');
      expect(multiplication.result, '24,691,357,802,469,135,780');

      final decimal = CalculatorController();
      for (final digit in '1234567890.1234567890'.split('')) {
        decimal.press(digit);
      }
      decimal.press('=');
      expect(decimal.result, '1,234,567,890.123456789');
    });

    test('20桁の分子と分母および小数分数との加算を正確に評価する', () {
      final longFraction = CalculatorController();
      longFraction.press('a/b');
      for (final digit in '12345678901234567890'.split('')) {
        longFraction.press(digit);
      }
      longFraction.press('a/b');
      for (final digit in '12345678901234567890'.split('')) {
        longFraction.press(digit);
      }
      longFraction.press('=');
      expect(longFraction.result, '1');

      final decimalFraction = CalculatorController();
      for (final key in ['a/b', '1', '.', '5', 'a/b', '2', '.', '5', 'a/b']) {
        decimalFraction.press(key);
      }
      decimalFraction.press('+');
      decimalFraction.press('0');
      decimalFraction.press('.');
      decimalFraction.press('4');
      decimalFraction.press('=');
      expect(decimalFraction.result, '1');
    });

    test('分子・分母の入力状態を表示・キャレット・評価で逐次共有する', () {
      String expectedExpression(String numerator, String denominator) {
        var numeratorValue = BigInt.parse(numerator);
        var denominatorValue = BigInt.parse(denominator);
        final divisor = numeratorValue.gcd(denominatorValue);
        numeratorValue ~/= divisor;
        denominatorValue ~/= divisor;
        return '(($numeratorValue)÷($denominatorValue))';
      }

      void expectSingleSource(
        CalculatorController controller,
        ExpressionFractionSegment segment,
      ) {
        final controllerInput = controller.fractionInputForMarker(
          segment.marker,
        );
        final evaluationInput = controller.fractionInputForEvaluation(
          segment.marker,
        );
        expect(identical(segment.input, controllerInput), isTrue);
        expect(identical(controllerInput, evaluationInput), isTrue);
        expect(
          controller.fractionExpressionForEvaluation(segment.marker),
          expectedExpression(segment.numerator, segment.denominator),
        );
      }

      const numeratorDigits = '12345678901234567890';
      const fixedDenominator = '123456789';
      final numeratorController = CalculatorController()..press('a/b');
      numeratorController.press('0');
      numeratorController.press('a/b');
      for (final digit in fixedDenominator.split('')) {
        numeratorController.press(digit);
      }
      var segment = numeratorController.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      numeratorController.activateFraction(
        segment.marker,
        FractionField.numerator,
        caretOffset: 1,
      );
      numeratorController.backspace();

      for (var index = 1; index <= numeratorDigits.length; index++) {
        numeratorController.press(numeratorDigits[index - 1]);
        segment = numeratorController.displaySegments
            .whereType<ExpressionFractionSegment>()
            .single;
        expect(segment.numerator, numeratorDigits.substring(0, index));
        expect(segment.activeCaretOffset, index);
        expectSingleSource(numeratorController, segment);
      }
      expect(numeratorController.press('1'), '最大20桁まで入力できます');
      expect(
        numeratorController.activeFractionInput!.numeratorText,
        numeratorDigits,
      );

      const fixedNumerator = '1234567895';
      const denominatorDigits = '12345678901234567890';
      final denominatorController = CalculatorController()..press('a/b');
      for (final digit in fixedNumerator.split('')) {
        denominatorController.press(digit);
      }
      denominatorController.press('a/b');
      for (var index = 1; index <= denominatorDigits.length; index++) {
        denominatorController.press(denominatorDigits[index - 1]);
        segment = denominatorController.displaySegments
            .whereType<ExpressionFractionSegment>()
            .single;
        expect(segment.denominator, denominatorDigits.substring(0, index));
        expect(segment.activeCaretOffset, index);
        expectSingleSource(denominatorController, segment);
      }
      expect(denominatorController.press('1'), '最大20桁まで入力できます');

      final exactExample = CalculatorController();
      for (final key in [
        'a/b',
        ...fixedNumerator.split(''),
        'a/b',
        ...fixedDenominator.split(''),
      ]) {
        exactExample.press(key);
      }
      segment = exactExample.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(
        exactExample.fractionExpressionForEvaluation(segment.marker),
        '((1234567895)÷(123456789))',
      );
      exactExample.press('=');
      expect(exactExample.result, '10.0000000405');
    });

    test('分数の数字1タップを入力・暫定評価後の1通知へまとめる', () {
      final controller = CalculatorController()..press('a/b');
      var notifications = 0;
      controller.addListener(() => notifications++);

      for (final digit in '12345678901234567890'.split('')) {
        final before = notifications;
        controller.press(digit);
        expect(notifications - before, 1);
      }
      final beforeRejectedDigit = notifications;
      controller.press('1');
      expect(notifications - beforeRejectedDigit, 1);
    });

    test('実機再現値の表示入力と評価元および結果が一致する', () {
      CalculatorController enterFraction(String numerator, String denominator) {
        final controller = CalculatorController()..press('a/b');
        for (final key in numerator.split('')) {
          controller.press(key);
        }
        controller.press('a/b');
        for (final key in denominator.split('')) {
          controller.press(key);
        }
        return controller;
      }

      var controller = enterFraction('1234567890', '1234567890');
      var segment = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(
        segment.input,
        same(controller.fractionInputForEvaluation(segment.marker)),
      );
      expect(
        controller.fractionExpressionForEvaluation(segment.marker),
        '((1)÷(1))',
      );
      controller.press('=');
      expect(controller.result, '1');

      controller = enterFraction('12345678901', '123456789012');
      segment = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(
        segment.input,
        same(controller.fractionInputForEvaluation(segment.marker)),
      );
      expect(
        controller.fractionExpressionForEvaluation(segment.marker),
        '((12345678901)÷(123456789012))',
      );
      controller.press('=');
      expect(controller.result, '0.099999999998');

      controller = enterFraction('123456789+5', '1234567890');
      segment = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(segment.numerator, '123456789+5');
      expect(
        segment.input,
        same(controller.fractionInputForEvaluation(segment.marker)),
      );
      expect(
        controller.fractionExpressionForEvaluation(segment.marker),
        '((123456789+5)÷(1234567890))',
      );
      controller.press('=');
      expect(controller.result, '0.10000000405');
    });

    test('10文字以上の行の後の演算子を次行先頭へ配置する', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('1234567890');
      controller.press('+');
      controller.press('5');

      final segments = controller.displaySegments;
      final breakIndex = segments.indexWhere(
        (segment) => segment is ExpressionLineBreakSegment,
      );
      expect(breakIndex, greaterThan(0));
      final followingText = segments
          .skip(breakIndex + 1)
          .whereType<ExpressionTextSegment>()
          .first
          .text;
      expect(followingText, startsWith('+'));
    });

    test('0・0.0・0.00の分母は確定できない', () {
      for (final denominator in ['0', '0.0', '0.00']) {
        final controller = CalculatorController();
        controller.press('a/b');
        controller.press('1');
        controller.press('a/b');
        for (final character in denominator.split('')) {
          controller.press(character);
        }
        controller.press('=');

        expect(controller.state, CalculatorState.error);
        expect(controller.errorMessage, '分母に0は入力できません');
      }
    });

    test('分数内の小数点をBackspaceで1文字ずつ削除できる', () {
      final controller = CalculatorController();
      for (final key in ['a/b', '1', '.', '5']) {
        controller.press(key);
      }

      controller.backspace();
      controller.backspace();

      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, '1');
    });

    test('式を1文字ずつ完全削除すると解とエラーも空欄になる', () {
      final controller = CalculatorController();
      controller.press('1');
      controller.press('+');
      controller.press('1');
      expect(controller.result, '2');

      controller.backspace();
      controller.backspace();
      controller.backspace();

      expect(controller.expression, isEmpty);
      expect(controller.result, isEmpty);
      expect(controller.errorMessage, isNull);
    });

    test('長押し相当の全削除で解とエラーも空欄になる', () {
      final controller = CalculatorController();
      controller.press('9');
      controller.moveCaretToDisplayOffset(1);
      controller.clearLeftOfCaret();

      expect(controller.expression, isEmpty);
      expect(controller.result, isEmpty);
      expect(controller.errorMessage, isNull);
    });

    test('関数一覧の全項目を分子と分母で入力して計算できる', () {
      final functionInputs = <String, List<String>>{
        'π': ['@π'],
        'e': ['@e'],
        'φ': ['@φ'],
        'log': ['@log', '1', '0', '0'],
        'ln': ['@ln', '@e'],
        'log₂': ['@log₂', '8'],
        '√': ['@√', '9'],
        '³√': ['@³√', '2', '7'],
        '|x|': ['@|x|', '−', '5'],
        'x²': ['3', '@x²'],
        'x³': ['2', '@x³'],
        '1/x': ['@1/x', '4'],
        'sin': ['@sin', '3', '0'],
        'cos': ['@cos', '6', '0'],
        'tan': ['@tan', '4', '5'],
        'sin⁻¹': ['@sin⁻¹', '1'],
        'cos⁻¹': ['@cos⁻¹', '0'],
        'tan⁻¹': ['@tan⁻¹', '1'],
        'sinh': ['@sinh', '1'],
        'cosh': ['@cosh', '1'],
        'tanh': ['@tanh', '1'],
        'sinh⁻¹': ['@sinh⁻¹', '1'],
        'cosh⁻¹': ['@cosh⁻¹', '2'],
        'tanh⁻¹': ['@tanh⁻¹', '1', '÷', '2'],
        '10ˣ': ['@10ˣ', '2'],
        'eˣ': ['@eˣ', '1'],
        'x!': ['5', '@x!'],
      };

      void enterActions(CalculatorController controller, List<String> actions) {
        for (final action in actions) {
          if (action.startsWith('@')) {
            expect(
              controller.insertFunction(action.substring(1)),
              isNull,
              reason: action,
            );
          } else {
            expect(controller.press(action), isNull, reason: action);
          }
        }
      }

      for (final entry in functionInputs.entries) {
        for (final functionInNumerator in [true, false]) {
          final controller = CalculatorController();
          controller.press('a/b');
          if (functionInNumerator) {
            enterActions(controller, entry.value);
            controller.press('a/b');
            controller.press('1');
          } else {
            controller.press('1');
            controller.press('a/b');
            enterActions(controller, entry.value);
          }

          controller.press('=');

          expect(
            controller.state,
            CalculatorState.result,
            reason:
                '${entry.key} in '
                '${functionInNumerator ? 'numerator' : 'denominator'}',
          );
          expect(controller.errorMessage, isNull, reason: entry.key);
        }
      }
    });

    test('分数内の関数はバックボタン1回で関数名ごと削除する', () {
      final controller = CalculatorController();
      controller.press('a/b');
      controller.insertFunction('sinh⁻¹');

      controller.backspace();

      final fraction = controller.displaySegments
          .whereType<ExpressionFractionSegment>()
          .single;
      expect(fraction.numerator, isEmpty);
    });

    test('20桁以内の整数解は指数化せず正確な全桁を表示する', () {
      final controller = CalculatorController();
      controller.pasteAtCaret('10000000000000000×10');
      controller.press('=');

      expect(controller.result, '100,000,000,000,000,000');
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
