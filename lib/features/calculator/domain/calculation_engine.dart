import 'dart:math' as math;

class CalculationException implements Exception {
  const CalculationException(this.message);

  final String message;
}

class CalculationEngine {
  const CalculationEngine();

  double evaluate(String expression) {
    if (expression.trim().isEmpty) {
      throw const CalculationException('計算できません');
    }

    final parser = _ExpressionParser(expression);
    final value = parser.parse();
    if (!value.isFinite) {
      throw const CalculationException('計算できません');
    }
    return value;
  }
}

class _ExpressionParser {
  _ExpressionParser(String source)
    : _source = source
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll(RegExp(r'\s+'), '');

  final String _source;
  int _position = 0;

  double parse() {
    final value = _parseExpression();
    if (_position != _source.length) {
      throw const CalculationException('計算できません');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      if (_consume('+')) {
        value += _parseTerm();
      } else if (_consume('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parsePower();
    while (true) {
      if (_consume('*')) {
        value *= _parsePower();
      } else if (_consume('/')) {
        final divisor = _parsePower();
        if (divisor == 0) {
          throw const CalculationException('0で割ることはできません');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parsePower() {
    final base = _parseUnary();
    if (!_consume('^')) return base;

    final exponent = _parsePower();
    final result = _pow(base, exponent);
    if (!result.isFinite) {
      throw const CalculationException('計算できません');
    }
    return result;
  }

  double _parseUnary() {
    if (_consume('+')) return _parseUnary();
    if (_consume('-')) return -_parseUnary();
    return _parsePostfix();
  }

  double _parsePostfix() {
    var value = _parsePrimary();
    while (true) {
      if (_consume('%')) {
        value /= 100;
      } else if (_consume('!')) {
        value = _factorial(value);
      } else {
        return value;
      }
    }
  }

  double _parsePrimary() {
    if (_consume('(')) {
      final value = _parseExpression();
      if (!_consume(')')) {
        throw const CalculationException('計算できません');
      }
      return value;
    }

    if (_consumeText('π')) return math.pi;
    if (_consumeText('φ')) return (1 + math.sqrt(5)) / 2;
    if (_consumeText('e')) return math.e;

    final function = _readFunctionName();
    if (function != null) {
      if (!_consume('(')) {
        throw const CalculationException('計算できません');
      }
      final argument = _parseExpression();
      if (!_consume(')')) {
        throw const CalculationException('計算できません');
      }
      return _applyFunction(function, argument);
    }

    final start = _position;
    var hasDecimalPoint = false;
    while (_position < _source.length) {
      final character = _source[_position];
      if (_isDigit(character)) {
        _position++;
      } else if (character == '.' && !hasDecimalPoint) {
        hasDecimalPoint = true;
        _position++;
      } else {
        break;
      }
    }

    if (start == _position) {
      throw const CalculationException('計算できません');
    }

    final number = double.tryParse(_source.substring(start, _position));
    if (number == null) {
      throw const CalculationException('計算できません');
    }
    return number;
  }

  bool _consume(String character) {
    if (_position >= _source.length || _source[_position] != character) {
      return false;
    }
    _position++;
    return true;
  }

  bool _consumeText(String text) {
    if (!_source.startsWith(text, _position)) return false;
    _position += text.length;
    return true;
  }

  String? _readFunctionName() {
    for (final name in const ['log₂', 'log', 'ln', '³√', '√', 'abs']) {
      if (_consumeText(name)) return name;
    }
    return null;
  }

  double _applyFunction(String function, double argument) {
    final value = switch (function) {
      'log' => argument > 0 ? math.log(argument) / math.ln10 : double.nan,
      'ln' => argument > 0 ? math.log(argument) : double.nan,
      'log₂' => argument > 0 ? math.log(argument) / math.ln2 : double.nan,
      '√' => argument >= 0 ? math.sqrt(argument) : double.nan,
      '³√' =>
        argument < 0
            ? -math.pow(-argument, 1 / 3).toDouble()
            : math.pow(argument, 1 / 3).toDouble(),
      'abs' => argument.abs(),
      _ => double.nan,
    };
    if (!value.isFinite) {
      throw const CalculationException('計算できません');
    }
    return value;
  }

  double _factorial(double value) {
    if (value < 0 || value != value.truncateToDouble() || value > 170) {
      throw const CalculationException('計算できません');
    }
    var result = 1.0;
    for (var number = 2; number <= value; number++) {
      result *= number;
    }
    return result;
  }

  bool _isDigit(String character) {
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }

  double _pow(double base, double exponent) {
    return math.pow(base, exponent).toDouble();
  }
}
