import 'dart:math' as math;

import '../../../core/domain/angle_unit.dart';

class CalculationException implements Exception {
  const CalculationException(this.message);

  final String message;
}

class CalculationEngine {
  const CalculationEngine();

  double evaluate(
    String expression, {
    AngleUnit angleUnit = AngleUnit.degrees,
  }) {
    if (expression.trim().isEmpty) {
      throw const CalculationException('計算できません');
    }

    final parser = _ExpressionParser(expression, angleUnit);
    final value = parser.parse();
    if (!value.isFinite) {
      throw const CalculationException('計算できません');
    }
    return value;
  }
}

class _ExpressionParser {
  _ExpressionParser(String source, this._angleUnit)
    : _source = source
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll(RegExp(r'\s+'), '');

  final String _source;
  final AngleUnit _angleUnit;
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
    for (final name in const [
      'sinh⁻¹',
      'cosh⁻¹',
      'tanh⁻¹',
      'sin⁻¹',
      'cos⁻¹',
      'tan⁻¹',
      'sinh',
      'cosh',
      'tanh',
      'sin',
      'cos',
      'tan',
      'log₂',
      'log',
      'ln',
      '³√',
      '√',
      'abs',
    ]) {
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
      'sin' => math.sin(_toRadians(argument)),
      'cos' => math.cos(_toRadians(argument)),
      'tan' => _tangent(argument),
      'sin⁻¹' => _fromRadians(math.asin(argument)),
      'cos⁻¹' => _fromRadians(math.acos(argument)),
      'tan⁻¹' => _fromRadians(math.atan(argument)),
      'sinh' => _sinh(argument),
      'cosh' => _cosh(argument),
      'tanh' => _tanh(argument),
      'sinh⁻¹' => math.log(argument + math.sqrt(argument * argument + 1)),
      'cosh⁻¹' =>
        argument >= 1
            ? math.log(argument + math.sqrt(argument * argument - 1))
            : double.nan,
      'tanh⁻¹' =>
        argument.abs() < 1
            ? 0.5 * math.log((1 + argument) / (1 - argument))
            : double.nan,
      _ => double.nan,
    };
    if (!value.isFinite) {
      throw const CalculationException('計算できません');
    }
    return value;
  }

  double _toRadians(double value) =>
      _angleUnit == AngleUnit.degrees ? value * math.pi / 180 : value;

  double _fromRadians(double value) =>
      _angleUnit == AngleUnit.degrees ? value * 180 / math.pi : value;

  double _tangent(double value) {
    final radians = _toRadians(value);
    if (math.cos(radians).abs() < 1e-12) return double.nan;
    return math.tan(radians);
  }

  double _sinh(double value) => (math.exp(value) - math.exp(-value)) / 2;

  double _cosh(double value) => (math.exp(value) + math.exp(-value)) / 2;

  double _tanh(double value) {
    if (value > 20) return 1;
    if (value < -20) return -1;
    final positive = math.exp(value);
    final negative = math.exp(-value);
    return (positive - negative) / (positive + negative);
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
