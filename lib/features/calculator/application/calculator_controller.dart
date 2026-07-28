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

  String get expression => _expression;
  String get result => _result;
  String? get errorMessage => _errorMessage;
  CalculatorState get state => _state;
  bool get showCaret => _state == CalculatorState.input;
  bool get canCycleFraction => _canCycleFraction;
  List<CalculationHistoryEntry> get history => List.unmodifiable(_history);

  String get displayExpression {
    if (_expression.isEmpty) return '';
    return _expression
        .replaceAll('×', ' × ')
        .replaceAll('÷', ' ÷ ')
        .replaceAll('+', ' + ')
        .replaceAll('−', ' − ')
        .replaceAll('^', ' ^ ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void press(String key) {
    switch (key) {
      case '=':
        calculate();
      case '←':
        backspace();
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
      final value = _engine.evaluate(_expression);
      _rawResult = _plainNumber(value);
      _result = _formatNumber(value);
      _state = CalculatorState.result;
      _errorMessage = null;
      _canCycleFraction = _findSimpleFraction(value);
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

  void backspace() {
    if (_state != CalculatorState.input) {
      clear();
      return;
    }
    if (_expression.isEmpty) return;

    _expression = _expression.substring(0, _expression.length - 1);
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
    notifyListeners();
  }

  void _insertDigits(String digits) {
    _prepareForNumberInput();
    if (_endsWithClosingValue()) _expression += '×';

    final currentNumber = _currentNumber;
    if (currentNumber == '0' && !digits.startsWith('0')) {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    if (_expression.isEmpty && digits == '00') {
      _expression = '0';
    } else {
      _expression += digits;
    }
    notifyListeners();
  }

  void _insertDecimalPoint() {
    _prepareForNumberInput();
    if (_endsWithClosingValue()) _expression += '×';
    if (_currentNumber.contains('.')) return;

    if (_expression.isEmpty || _endsWithOperatorOrOpenParenthesis) {
      _expression += '0.';
    } else {
      _expression += '.';
    }
    notifyListeners();
  }

  void _insertOperator(String operator) {
    if (_state == CalculatorState.error) clear();
    if (_state == CalculatorState.result) {
      _expression = _rawResult;
      _state = CalculatorState.input;
    }
    if (_expression.isEmpty) {
      if (operator == '−') _expression = operator;
      notifyListeners();
      return;
    }

    final last = _expression[_expression.length - 1];
    if (_isOperator(last)) {
      if (operator == '−' && last != '−') {
        _expression += operator;
      } else {
        _expression =
            '${_expression.substring(0, _expression.length - 1)}$operator';
      }
    } else if (last == '(') {
      if (operator == '−') _expression += operator;
    } else if (last != '.') {
      _expression += operator;
    }
    _canCycleFraction = false;
    notifyListeners();
  }

  void _insertParenthesis() {
    _prepareForNumberInput();
    final openCount = '('.allMatches(_expression).length;
    final closeCount = ')'.allMatches(_expression).length;

    if (_expression.isEmpty || _endsWithOperatorOrOpenParenthesis) {
      _expression += '(';
    } else if (openCount > closeCount) {
      _expression += ')';
    } else {
      _expression += '×(';
    }
    notifyListeners();
  }

  void _insertPercent() {
    if (_state != CalculatorState.input || _expression.isEmpty) return;
    final last = _expression[_expression.length - 1];
    if (_isDigit(last) || last == ')') {
      _expression += '%';
      notifyListeners();
    }
  }

  void _prepareForNumberInput() {
    if (_state == CalculatorState.result || _state == CalculatorState.error) {
      clear();
    }
    _canCycleFraction = false;
  }

  bool get _endsWithOperatorOrOpenParenthesis {
    if (_expression.isEmpty) return true;
    final last = _expression[_expression.length - 1];
    return _isOperator(last) || last == '(';
  }

  bool _endsWithClosingValue() {
    if (_expression.isEmpty) return false;
    final last = _expression[_expression.length - 1];
    return last == ')' || last == '%';
  }

  String get _currentNumber {
    final match = RegExp(r'[\d.]+$').firstMatch(_expression);
    return match?.group(0) ?? '';
  }

  bool _isDigit(String character) =>
      character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;

  bool _isOperator(String character) =>
      const {'+', '−', '×', '÷', '^'}.contains(character);

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
