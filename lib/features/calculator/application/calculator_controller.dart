import 'package:flutter/foundation.dart';

import '../domain/calculation_engine.dart';

enum CalculatorState { input, result, error }

class CalculationHistoryEntry {
  const CalculationHistoryEntry({
    required this.expression,
    required this.result,
  });

  final String expression;
  final String result;
}

class FormattedExpression {
  const FormattedExpression({required this.text, required this.caretOffset});

  final String text;
  final int caretOffset;
}

enum FractionField { numerator, denominator }

sealed class ExpressionDisplaySegment {
  const ExpressionDisplaySegment();
}

class ExpressionTextSegment extends ExpressionDisplaySegment {
  const ExpressionTextSegment(this.text);
  final String text;
}

class ExpressionCaretSegment extends ExpressionDisplaySegment {
  const ExpressionCaretSegment();
}

class ExpressionFractionSegment extends ExpressionDisplaySegment {
  const ExpressionFractionSegment({
    required this.marker,
    required this.wholeNumber,
    required this.numerator,
    required this.denominator,
    required this.activeField,
  });

  final String marker;
  final String wholeNumber;
  final String numerator;
  final String denominator;
  final FractionField? activeField;
}

class _EditableFraction {
  _EditableFraction({this.wholeNumber = ''});

  final String wholeNumber;
  String numerator = '';
  String denominator = '';

  bool get isComplete => numerator.isNotEmpty && denominator.isNotEmpty;
}

class CalculatorController extends ChangeNotifier {
  CalculatorController({this._engine = const CalculationEngine()});

  final CalculationEngine _engine;
  final List<CalculationHistoryEntry> _history = [];

  String _expression = '';
  String _result = '0';
  String _rawResult = '0';
  String? _errorMessage;
  CalculatorState _state = CalculatorState.input;
  bool _canCycleFraction = false;
  int _caretPosition = 0;
  final Map<String, _EditableFraction> _fractions = {};
  String? _activeFractionMarker;
  FractionField? _activeFractionField;
  int _nextFractionId = 0;

  String get expression => _expression;
  String get result => _result;
  String? get errorMessage => _errorMessage;
  CalculatorState get state => _state;
  bool get showCaret => _state == CalculatorState.input;
  bool get canCycleFraction => _canCycleFraction;
  int get caretPosition => _caretPosition;
  bool get isEditingFraction => _activeFractionMarker != null;
  List<CalculationHistoryEntry> get history => List.unmodifiable(_history);
  String get clipboardText {
    if (_expression.isEmpty) return _result;
    if (_state == CalculatorState.result) {
      return '$displayExpression = $_result';
    }
    return displayExpression;
  }

  String get estimateExpressionText => displayExpression;
  String get estimateResultText =>
      _state == CalculatorState.error ? '' : _result;

  FormattedExpression get formattedExpression {
    final buffer = StringBuffer();
    var displayCaret = 0;

    for (var index = 0; index <= _expression.length; index++) {
      if (index == _caretPosition) displayCaret = buffer.length;
      if (index == _expression.length) break;

      final character = _expression[index];
      if (_isFractionMarker(character)) {
        buffer.write(_fractionAsLinearText(character));
      } else if (_isOperator(character)) {
        if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
          buffer.write(' ');
        }
        if (index == _caretPosition) displayCaret = buffer.length;
        buffer
          ..write(character)
          ..write(' ');
      } else {
        buffer.write(character);
      }
    }

    final text = buffer.toString().trimRight();
    return FormattedExpression(
      text: text,
      caretOffset: displayCaret.clamp(0, text.length),
    );
  }

  String get displayExpression => formattedExpression.text;

  List<ExpressionDisplaySegment> get displaySegments {
    final segments = <ExpressionDisplaySegment>[];
    final textBuffer = StringBuffer();

    void flushText() {
      if (textBuffer.isEmpty) return;
      segments.add(ExpressionTextSegment(textBuffer.toString()));
      textBuffer.clear();
    }

    for (var index = 0; index <= _expression.length; index++) {
      if (showCaret &&
          _activeFractionMarker == null &&
          index == _caretPosition) {
        flushText();
        segments.add(const ExpressionCaretSegment());
      }
      if (index == _expression.length) break;

      final character = _expression[index];
      if (_isFractionMarker(character)) {
        flushText();
        final fraction = _fractions[character]!;
        segments.add(
          ExpressionFractionSegment(
            marker: character,
            wholeNumber: fraction.wholeNumber,
            numerator: fraction.numerator,
            denominator: fraction.denominator,
            activeField: _activeFractionMarker == character
                ? _activeFractionField
                : null,
          ),
        );
      } else if (_isOperator(character)) {
        if (textBuffer.isNotEmpty && !textBuffer.toString().endsWith(' ')) {
          textBuffer.write(' ');
        }
        textBuffer
          ..write(character)
          ..write(' ');
      } else {
        textBuffer.write(character);
      }
    }
    flushText();
    return segments;
  }

  void press(String key) {
    switch (key) {
      case '=':
        calculate();
      case '←':
        backspace();
      case 'a/b':
        pressFractionButton();
      case '()':
        _insertParenthesis();
      case '.':
        _insertDecimalPoint();
      case '%':
        _insertPercent();
      case '+':
      case '−':
      case '×':
      case '÷':
      case '^':
        _insertOperator(key);
      case '0':
      case '00':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        _insertDigits(key);
    }
  }

  void calculate() {
    if (_expression.isEmpty || _state == CalculatorState.error) return;
    if (_state == CalculatorState.result) return;

    try {
      final value = _engine.evaluate(_expandFractionsForCalculation());
      _rawResult = _plainNumber(value);
      _result = _formatNumber(value);
      _state = CalculatorState.result;
      _errorMessage = null;
      _canCycleFraction = _findSimpleFraction(value);
      _caretPosition = _expression.length;
      _activeFractionMarker = null;
      _activeFractionField = null;
      _history.add(
        CalculationHistoryEntry(expression: displayExpression, result: _result),
      );
      if (_history.length > 50) _history.removeAt(0);
    } on CalculationException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('計算できません');
    }
    notifyListeners();
  }

  void moveCaretToDisplayOffset(int displayOffset) {
    if (_state == CalculatorState.error) return;
    if (_state == CalculatorState.result) {
      _state = CalculatorState.input;
      _canCycleFraction = false;
    }

    var bestRawOffset = 0;
    var bestDistance = 1 << 30;
    for (var rawOffset = 0; rawOffset <= _expression.length; rawOffset++) {
      final candidate = _displayOffsetForRawOffset(rawOffset);
      final distance = (candidate - displayOffset).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestRawOffset = rawOffset;
      }
    }
    _caretPosition = bestRawOffset;
    _activeFractionMarker = null;
    _activeFractionField = null;
    notifyListeners();
  }

  void activateFraction(String marker, FractionField field) {
    if (!_fractions.containsKey(marker)) return;
    _state = CalculatorState.input;
    _canCycleFraction = false;
    _activeFractionMarker = marker;
    _activeFractionField = field;
    _caretPosition = _expression.indexOf(marker);
    notifyListeners();
  }

  void pressFractionButton() {
    if (_state == CalculatorState.result) {
      // Result display cycling is connected in the next fraction phase.
      return;
    }
    if (_state == CalculatorState.error) clear();

    final activeMarker = _activeFractionMarker;
    if (activeMarker != null) {
      final fraction = _fractions[activeMarker]!;
      if (_activeFractionField == FractionField.numerator) {
        _activeFractionField = FractionField.denominator;
      } else if (fraction.denominator.isNotEmpty) {
        _activeFractionMarker = null;
        _activeFractionField = null;
        _caretPosition = _expression.indexOf(activeMarker) + 1;
      }
      notifyListeners();
      return;
    }

    var wholeNumber = '';
    if (_caretPosition > 0 &&
        (_isFractionMarker(_characterBeforeCaret) ||
            _characterBeforeCaret == ')' ||
            _characterBeforeCaret == '%')) {
      _insertAtCaret('×');
    }
    final beforeCaret = _expression.substring(0, _caretPosition);
    final wholeNumberMatch = RegExp(r'(?<![\d.])\d+$').firstMatch(beforeCaret);
    if (wholeNumberMatch != null) {
      wholeNumber = wholeNumberMatch.group(0)!;
      final start = wholeNumberMatch.start;
      _expression =
          '${_expression.substring(0, start)}'
          '${_expression.substring(_caretPosition)}';
      _caretPosition = start;
    }

    final marker = String.fromCharCode(0xE000 + _nextFractionId++);
    _fractions[marker] = _EditableFraction(wholeNumber: wholeNumber);
    _insertAtCaret(marker);
    _activeFractionMarker = marker;
    _activeFractionField = FractionField.numerator;
    _caretPosition = _expression.indexOf(marker);
    notifyListeners();
  }

  void backspace() {
    if (_activeFractionMarker != null) {
      _backspaceFraction();
      return;
    }
    if (_state != CalculatorState.input) {
      clear();
      return;
    }
    if (_caretPosition == 0 || _expression.isEmpty) return;

    final removedCharacter = _expression[_caretPosition - 1];
    _expression =
        '${_expression.substring(0, _caretPosition - 1)}'
        '${_expression.substring(_caretPosition)}';
    if (_isFractionMarker(removedCharacter)) {
      _fractions.remove(removedCharacter);
    }
    _caretPosition--;
    _canCycleFraction = false;
    notifyListeners();
  }

  void clearLeftOfCaret() {
    if (_activeFractionMarker != null) {
      final marker = _activeFractionMarker!;
      final markerIndex = _expression.indexOf(marker);
      final removed = _expression.substring(0, markerIndex + 1);
      for (final character in removed.split('')) {
        if (_isFractionMarker(character)) _fractions.remove(character);
      }
      _expression = _expression.substring(markerIndex + 1);
      _activeFractionMarker = null;
      _activeFractionField = null;
      _caretPosition = 0;
      _result = '0';
      notifyListeners();
      return;
    }
    if (_state != CalculatorState.input) {
      clear();
      return;
    }
    if (_caretPosition == 0) return;

    final removed = _expression.substring(0, _caretPosition);
    for (final character in removed.split('')) {
      if (_isFractionMarker(character)) _fractions.remove(character);
    }
    _expression = _expression.substring(_caretPosition);
    _caretPosition = 0;
    _activeFractionMarker = null;
    _activeFractionField = null;
    _result = '0';
    _canCycleFraction = false;
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _result = '0';
    _rawResult = '0';
    _errorMessage = null;
    _state = CalculatorState.input;
    _canCycleFraction = false;
    _caretPosition = 0;
    _fractions.clear();
    _activeFractionMarker = null;
    _activeFractionField = null;
    notifyListeners();
  }

  bool pasteAtCaret(String text) {
    final normalized = text
        .replaceAll(',', '')
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('-', '−')
        .replaceAll(RegExp(r'\s+'), '');
    final sanitized = normalized.replaceAll(RegExp(r'[^0-9.+×÷−^%()]'), '');
    if (sanitized.isEmpty) return false;

    if (_state == CalculatorState.result || _state == CalculatorState.error) {
      clear();
    }
    _insertAtCaret(sanitized);
    _canCycleFraction = false;
    notifyListeners();
    return true;
  }

  void _insertDigits(String digits) {
    if (_activeFractionMarker != null) {
      _insertFractionDigits(digits);
      return;
    }
    _prepareForNumberInput();
    if (_characterBeforeCaret == ')' ||
        _characterBeforeCaret == '%' ||
        _isFractionMarker(_characterBeforeCaret)) {
      _insertAtCaret('×');
    }

    if (_expression.isEmpty && digits == '00') {
      _insertAtCaret('0');
    } else {
      _insertAtCaret(digits);
    }
    notifyListeners();
  }

  void _insertDecimalPoint() {
    if (_activeFractionMarker != null) return;
    _prepareForNumberInput();
    if (_characterBeforeCaret == ')' ||
        _characterBeforeCaret == '%' ||
        _isFractionMarker(_characterBeforeCaret)) {
      _insertAtCaret('×');
    }
    if (_numberAroundCaret.contains('.')) return;

    if (_caretPosition == 0 ||
        _isOperator(_characterBeforeCaret) ||
        _characterBeforeCaret == '(') {
      _insertAtCaret('0.');
    } else {
      _insertAtCaret('.');
    }
    notifyListeners();
  }

  void _insertOperator(String operator) {
    if (_activeFractionMarker != null) return;
    if (_state == CalculatorState.error) clear();
    if (_state == CalculatorState.result) {
      _expression = _rawResult;
      _caretPosition = _expression.length;
      _state = CalculatorState.input;
    }
    if (_expression.isEmpty) {
      if (operator == '−') _insertAtCaret(operator);
      notifyListeners();
      return;
    }

    final previous = _characterBeforeCaret;
    if (_isOperator(previous)) {
      if (operator == '−' && previous != '−') {
        _insertAtCaret(operator);
      } else {
        _replaceBeforeCaret(operator);
      }
    } else if (previous == '(') {
      if (operator == '−') _insertAtCaret(operator);
    } else if (previous != '.') {
      _insertAtCaret(operator);
    }
    _canCycleFraction = false;
    notifyListeners();
  }

  void _insertParenthesis() {
    if (_activeFractionMarker != null) return;
    _prepareForNumberInput();
    final beforeCaret = _expression.substring(0, _caretPosition);
    final openCount = '('.allMatches(beforeCaret).length;
    final closeCount = ')'.allMatches(beforeCaret).length;
    final previous = _characterBeforeCaret;

    if (_caretPosition == 0 || _isOperator(previous) || previous == '(') {
      _insertAtCaret('(');
    } else if (openCount > closeCount) {
      _insertAtCaret(')');
    } else {
      _insertAtCaret('×(');
    }
    notifyListeners();
  }

  void _insertPercent() {
    if (_activeFractionMarker != null) return;
    if (_state != CalculatorState.input || _caretPosition == 0) return;
    final previous = _characterBeforeCaret;
    if (_isDigit(previous) || previous == ')' || _isFractionMarker(previous)) {
      _insertAtCaret('%');
      notifyListeners();
    }
  }

  void _prepareForNumberInput() {
    if (_state == CalculatorState.result || _state == CalculatorState.error) {
      clear();
    }
    _canCycleFraction = false;
  }

  void _insertAtCaret(String value) {
    _expression =
        '${_expression.substring(0, _caretPosition)}'
        '$value'
        '${_expression.substring(_caretPosition)}';
    _caretPosition += value.length;
  }

  void _insertFractionDigits(String digits) {
    final fraction = _fractions[_activeFractionMarker]!;
    final target = _activeFractionField == FractionField.numerator
        ? fraction.numerator
        : fraction.denominator;
    final value = target.isEmpty && digits == '00' ? '0' : '$target$digits';
    if (_activeFractionField == FractionField.numerator) {
      fraction.numerator = value;
    } else {
      fraction.denominator = value;
    }
    notifyListeners();
  }

  void _backspaceFraction() {
    final marker = _activeFractionMarker!;
    final fraction = _fractions[marker]!;
    if (_activeFractionField == FractionField.denominator) {
      if (fraction.denominator.isNotEmpty) {
        fraction.denominator = fraction.denominator.substring(
          0,
          fraction.denominator.length - 1,
        );
      } else {
        _activeFractionField = FractionField.numerator;
      }
      notifyListeners();
      return;
    }

    if (fraction.numerator.isNotEmpty) {
      fraction.numerator = fraction.numerator.substring(
        0,
        fraction.numerator.length - 1,
      );
    } else {
      final index = _expression.indexOf(marker);
      _expression =
          '${_expression.substring(0, index)}'
          '${_expression.substring(index + 1)}';
      _fractions.remove(marker);
      _activeFractionMarker = null;
      _activeFractionField = null;
      _caretPosition = index;
    }
    notifyListeners();
  }

  void _replaceBeforeCaret(String value) {
    _expression =
        '${_expression.substring(0, _caretPosition - 1)}'
        '$value'
        '${_expression.substring(_caretPosition)}';
  }

  String get _characterBeforeCaret =>
      _caretPosition == 0 ? '' : _expression[_caretPosition - 1];

  String get _numberAroundCaret {
    var start = _caretPosition;
    var end = _caretPosition;
    while (start > 0 && _isNumberCharacter(_expression[start - 1])) {
      start--;
    }
    while (end < _expression.length && _isNumberCharacter(_expression[end])) {
      end++;
    }
    return _expression.substring(start, end);
  }

  int _displayOffsetForRawOffset(int targetRawOffset) {
    final buffer = StringBuffer();
    for (var index = 0; index < targetRawOffset; index++) {
      final character = _expression[index];
      if (_isFractionMarker(character)) {
        buffer.write(_fractionAsLinearText(character));
      } else if (_isOperator(character)) {
        if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) {
          buffer.write(' ');
        }
        buffer
          ..write(character)
          ..write(' ');
      } else {
        buffer.write(character);
      }
    }
    return buffer.length;
  }

  bool _isNumberCharacter(String character) =>
      _isDigit(character) || character == '.';

  bool _isDigit(String character) {
    if (character.isEmpty) return false;
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }

  bool _isOperator(String character) =>
      const {'+', '−', '×', '÷', '^'}.contains(character);

  bool _isFractionMarker(String character) =>
      character.isNotEmpty && _fractions.containsKey(character);

  String _fractionAsLinearText(String marker) {
    final fraction = _fractions[marker]!;
    final numerator = fraction.numerator.isEmpty ? '□' : fraction.numerator;
    final denominator = fraction.denominator.isEmpty
        ? '□'
        : fraction.denominator;
    final whole = fraction.wholeNumber.isEmpty
        ? ''
        : '${fraction.wholeNumber} ';
    return '$whole$numerator/$denominator';
  }

  String _expandFractionsForCalculation() {
    final buffer = StringBuffer();
    for (final character in _expression.split('')) {
      if (!_isFractionMarker(character)) {
        buffer.write(character);
        continue;
      }

      final fraction = _fractions[character]!;
      if (!fraction.isComplete || fraction.denominator == '0') {
        throw const CalculationException('計算できません');
      }
      final whole = int.tryParse(fraction.wholeNumber) ?? 0;
      final numerator = int.parse(fraction.numerator);
      final denominator = int.parse(fraction.denominator);
      final improperNumerator = whole * denominator + numerator;
      buffer.write('($improperNumerator÷$denominator)');
    }
    return buffer.toString();
  }

  void _setError(String message) {
    _errorMessage = message;
    _result = '';
    _state = CalculatorState.error;
    _canCycleFraction = false;
  }

  String _plainNumber(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(12)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatNumber(double value) {
    final plain = _plainNumber(value);
    final parts = plain.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final digits = parts.first.replaceFirst('-', '');
    final grouped = digits.replaceAllMapped(
      RegExp(r'(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return ['$sign$grouped', if (parts.length == 2) parts[1]].join('.');
  }

  bool _findSimpleFraction(double value) {
    final absoluteValue = value.abs();
    for (var denominator = 1; denominator <= 999; denominator++) {
      final numerator = (absoluteValue * denominator).round();
      if (numerator > 999) continue;
      if ((absoluteValue - numerator / denominator).abs() < 1e-10) {
        return true;
      }
    }
    return false;
  }
}
