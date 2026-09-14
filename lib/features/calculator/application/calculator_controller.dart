import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/domain/angle_unit.dart';
import '../data/calculation_history_store.dart';
import '../domain/calculation_engine.dart';
import '../../settings/domain/app_settings.dart';

enum CalculatorState { input, result, error }

enum ResultDisplayMode { decimal, improperFraction, mixedFraction }

class CalculationHistoryEntry {
  const CalculationHistoryEntry({
    required this.expression,
    required this.result,
    required this.decimalResult,
    required this.createdAt,
    this.improperFractionResult,
    this.mixedFractionResult,
  });

  final String expression;
  final String result;
  final String decimalResult;
  final DateTime createdAt;
  final String? improperFractionResult;
  final String? mixedFractionResult;
}

class _ExactDecimal {
  const _ExactDecimal({required this.unscaled, required this.scale});

  final BigInt unscaled;
  final int scale;

  BigInt get scaleFactor => BigInt.from(10).pow(scale);

  static _ExactDecimal? tryParse(String value) {
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(value);
    if (match == null) return null;
    final fractionDigits = match.group(2) ?? '';
    return _ExactDecimal(
      unscaled: BigInt.parse('${match.group(1)}$fractionDigits'),
      scale: fractionDigits.length,
    );
  }
}

class _ExactRational {
  _ExactRational(BigInt numerator, BigInt denominator)
    : numerator = denominator.isNegative ? -numerator : numerator,
      denominator = denominator.abs() {
    if (denominator == BigInt.zero) {
      throw const CalculationException('0で割ることはできません');
    }
  }

  final BigInt numerator;
  final BigInt denominator;

  factory _ExactRational.fromDecimal(String value) {
    final decimal = _ExactDecimal.tryParse(value);
    if (decimal == null) throw const CalculationException('計算できません');
    return _ExactRational(decimal.unscaled, decimal.scaleFactor)._normalized();
  }

  _ExactRational _normalized() {
    final divisor = numerator.abs().gcd(denominator);
    return _ExactRational(numerator ~/ divisor, denominator ~/ divisor);
  }

  _ExactRational operator +(_ExactRational other) => _ExactRational(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  )._normalized();

  _ExactRational operator -(_ExactRational other) => _ExactRational(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  )._normalized();

  _ExactRational operator *(_ExactRational other) => _ExactRational(
    numerator * other.numerator,
    denominator * other.denominator,
  )._normalized();

  _ExactRational operator /(_ExactRational other) {
    if (other.numerator == BigInt.zero) {
      throw const CalculationException('0で割ることはできません');
    }
    return _ExactRational(
      numerator * other.denominator,
      denominator * other.numerator,
    )._normalized();
  }

  _ExactRational operator -() => _ExactRational(-numerator, denominator);

  double toDouble() => numerator.toDouble() / denominator.toDouble();
}

class _ExactExpressionParser {
  _ExactExpressionParser(String source)
    : _source = source
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll(RegExp(r'\s+'), '');

  final String _source;
  int _position = 0;

  static _ExactRational? tryEvaluate(String source) {
    if (RegExp(r'[^0-9.+\-*/()]').hasMatch(
      source.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('−', '-'),
    )) {
      return null;
    }
    try {
      return _ExactExpressionParser(source).parse();
    } on CalculationException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  _ExactRational parse() {
    final value = _parseExpression();
    if (_position != _source.length) {
      throw const CalculationException('計算できません');
    }
    return value;
  }

  _ExactRational _parseExpression() {
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

  _ExactRational _parseTerm() {
    var value = _parseUnary();
    while (true) {
      if (_consume('*')) {
        value *= _parseUnary();
      } else if (_consume('/')) {
        value /= _parseUnary();
      } else {
        return value;
      }
    }
  }

  _ExactRational _parseUnary() {
    if (_consume('+')) return _parseUnary();
    if (_consume('-')) return -_parseUnary();
    if (_consume('(')) {
      final value = _parseExpression();
      if (!_consume(')')) throw const CalculationException('計算できません');
      return value;
    }
    final start = _position;
    var hasDecimalPoint = false;
    while (_position < _source.length) {
      final character = _source[_position];
      if (_isAsciiDigit(character)) {
        _position++;
      } else if (character == '.' && !hasDecimalPoint) {
        hasDecimalPoint = true;
        _position++;
      } else {
        break;
      }
    }
    if (start == _position) throw const CalculationException('計算できません');
    var number = _source.substring(start, _position);
    if (number.endsWith('.')) number = number.substring(0, number.length - 1);
    return _ExactRational.fromDecimal(number);
  }

  bool _consume(String value) {
    if (_position >= _source.length || _source[_position] != value) {
      return false;
    }
    _position++;
    return true;
  }

  static bool _isAsciiDigit(String value) {
    final code = value.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }
}

class FormattedExpression {
  const FormattedExpression({required this.text, required this.caretOffset});

  final String text;
  final int caretOffset;
}

enum FractionField { wholeNumber, numerator, denominator }

sealed class ExpressionDisplaySegment {
  const ExpressionDisplaySegment();
}

class ExpressionTextSegment extends ExpressionDisplaySegment {
  const ExpressionTextSegment({required this.text, required this.rawOffsets});

  final String text;
  final List<int> rawOffsets;
}

class ExpressionCaretSegment extends ExpressionDisplaySegment {
  const ExpressionCaretSegment();
}

class ExpressionLineBreakSegment extends ExpressionDisplaySegment {
  const ExpressionLineBreakSegment();
}

class ExpressionFractionSegment extends ExpressionDisplaySegment {
  const ExpressionFractionSegment({
    required this.marker,
    required this.input,
    required this.activeField,
    required this.activeCaretOffset,
  });

  final String marker;
  final FractionInputState input;
  final FractionField? activeField;
  final int? activeCaretOffset;

  String get wholeNumber => input.wholeNumberText;
  String get numerator => input.numeratorText;
  String get denominator => input.denominatorText;
}

@immutable
class FractionInputState {
  const FractionInputState({
    this.wholeNumberText = '',
    this.numeratorText = '',
    this.denominatorText = '',
  });

  final String wholeNumberText;
  final String numeratorText;
  final String denominatorText;

  bool get isComplete => numeratorText.isNotEmpty && denominatorText.isNotEmpty;

  FractionInputState copyWith({
    String? wholeNumberText,
    String? numeratorText,
    String? denominatorText,
  }) {
    return FractionInputState(
      wholeNumberText: wholeNumberText ?? this.wholeNumberText,
      numeratorText: numeratorText ?? this.numeratorText,
      denominatorText: denominatorText ?? this.denominatorText,
    );
  }
}

class _ResultFraction {
  const _ResultFraction({required this.numerator, required this.denominator});

  final int numerator;
  final int denominator;
}

class CalculatorController extends ChangeNotifier {
  CalculatorController({
    this.historyStore,
    this._engine = const CalculationEngine(),
    this._decimalPlaces = 12,
    this._roundingMode = CalculatorRoundingMode.halfUp,
    this._angleUnit = AngleUnit.degrees,
  });

  static const int numberDigitLimit = 20;
  static const int fractionDigitLimit = numberDigitLimit;
  static const String digitLimitNotice = 'calculatorDigitLimitReached';
  static const double standardNumberDisplayLimit = 10000000000000000;

  final CalculationEngine _engine;
  final CalculationHistoryStore? historyStore;
  final List<CalculationHistoryEntry> _history = [];
  Future<void> _pendingHistorySave = Future.value();
  bool _historyLoaded = false;
  bool _historyLoadComplete = false;
  int _decimalPlaces;
  CalculatorRoundingMode _roundingMode;
  AngleUnit _angleUnit;

  String _expression = '';
  String _result = '0';
  String _rawResult = '0';
  String? _errorMessage;
  CalculatorState _state = CalculatorState.input;
  bool _canCycleFraction = false;
  bool _isPreviewResult = false;
  ResultDisplayMode _resultDisplayMode = ResultDisplayMode.decimal;
  _ResultFraction? _resultFraction;
  _ExactRational? _exactResult;
  String? _pendingNotice;
  int _caretPosition = 0;
  final Map<String, FractionInputState> _fractions = {};
  String? _activeFractionMarker;
  FractionField? _activeFractionField;
  int _activeFractionCaretOffset = 0;
  int _nextFractionId = 0;
  bool _isProcessingKeyPress = false;
  bool _keyPressNotificationPending = false;

  String get expression => _expression;
  String get result => _result;
  String? get errorMessage => _errorMessage;
  CalculatorState get state => _state;
  bool get showCaret => _state == CalculatorState.input;
  bool get canCycleFraction => _canCycleFraction;
  bool get isPreviewResult => _isPreviewResult;
  ResultDisplayMode get resultDisplayMode => _resultDisplayMode;
  int? get resultFractionNumerator => _resultFraction?.numerator;
  int? get resultFractionDenominator => _resultFraction?.denominator;
  int get caretPosition => _caretPosition;
  bool get isEditingFraction => _activeFractionMarker != null;
  FractionInputState? get activeFractionInput =>
      _activeFractionMarker == null ? null : _fractions[_activeFractionMarker];
  @visibleForTesting
  FractionInputState? fractionInputForMarker(String marker) =>
      _fractions[marker];

  @visibleForTesting
  FractionInputState fractionInputForEvaluation(String marker) =>
      _fractions[marker]!;

  @visibleForTesting
  String fractionExpressionForEvaluation(String marker) =>
      _fractionExpressionForCalculation(_fractions[marker]!);
  List<CalculationHistoryEntry> get history => List.unmodifiable(_history);

  @override
  void notifyListeners() {
    if (_isProcessingKeyPress) {
      _keyPressNotificationPending = true;
      return;
    }
    super.notifyListeners();
  }

  void updateDisplaySettings({
    required int decimalPlaces,
    required CalculatorRoundingMode roundingMode,
    AngleUnit? angleUnit,
  }) {
    final angleChanged = angleUnit != null && angleUnit != _angleUnit;
    _decimalPlaces = decimalPlaces.clamp(1, 12);
    _roundingMode = roundingMode;
    _angleUnit = angleUnit ?? _angleUnit;
    if (angleChanged && _expression.isNotEmpty) {
      if (_state == CalculatorState.input) {
        _updatePreviewResult();
        return;
      }
      if (_state == CalculatorState.result) {
        try {
          final evaluation = _evaluateCurrentExpression();
          final value = evaluation.approximate;
          _exactResult = evaluation.exact;
          _rawResult = _exactResult == null
              ? _rawNumber(value)
              : _roundedExactPlainNumber(_exactResult!);
          _result = _exactResult == null
              ? _formatNumber(value)
              : _formatExactNumber(_exactResult!);
          _resultFraction = _findSimpleFraction(value);
          _canCycleFraction = _resultFraction != null;
          _resultDisplayMode = ResultDisplayMode.decimal;
        } catch (_) {
          // 既に確定済みの表示は、再計算できない場合も維持する。
        }
      }
    }
    if (_state != CalculatorState.error && _rawResult.isNotEmpty) {
      if (_exactResult != null) {
        _rawResult = _roundedExactPlainNumber(_exactResult!);
        _result = _formatExactNumber(_exactResult!);
      } else {
        final value = double.tryParse(_rawResult);
        if (value != null && value.isFinite) _result = _formatNumber(value);
      }
    }
    notifyListeners();
  }

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
  double? get estimateQuantityValue {
    if (_state == CalculatorState.error) return null;
    final value = double.tryParse(_rawResult);
    return value != null && value.isFinite ? value : null;
  }

  Future<void> loadHistory() async {
    if (_historyLoaded || historyStore == null) return;
    _historyLoaded = true;
    final entriesCreatedWhileLoading = List.of(_history);
    try {
      final stored = await historyStore!.load();
      final limitedStored = stored.length > 50
          ? stored.sublist(stored.length - 50)
          : stored;
      _history
        ..clear()
        ..addAll(
          limitedStored.map(
            (entry) => CalculationHistoryEntry(
              expression: entry.expression,
              result: entry.result,
              decimalResult: entry.decimalResult,
              improperFractionResult: entry.improperFractionResult,
              mixedFractionResult: entry.mixedFractionResult,
              createdAt: entry.createdAt,
            ),
          ),
        )
        ..addAll(entriesCreatedWhileLoading);
      while (_history.length > 50) {
        _history.removeAt(0);
      }
    } finally {
      _historyLoadComplete = true;
    }
    if (entriesCreatedWhileLoading.isNotEmpty) _saveHistory();
    notifyListeners();
  }

  Future<void> reloadHistory() async {
    final store = historyStore;
    if (store == null) return;
    final stored = await store.load();
    final limitedStored = stored.length > 50
        ? stored.sublist(stored.length - 50)
        : stored;
    _history
      ..clear()
      ..addAll(
        limitedStored.map(
          (entry) => CalculationHistoryEntry(
            expression: entry.expression,
            result: entry.result,
            decimalResult: entry.decimalResult,
            improperFractionResult: entry.improperFractionResult,
            mixedFractionResult: entry.mixedFractionResult,
            createdAt: entry.createdAt,
          ),
        ),
      );
    _historyLoaded = true;
    _historyLoadComplete = true;
    notifyListeners();
  }

  void _saveHistory() {
    final store = historyStore;
    if (store == null || !_historyLoadComplete) return;
    final snapshot = _history
        .map(
          (entry) => StoredCalculationHistoryEntry(
            expression: entry.expression,
            result: entry.result,
            decimalResult: entry.decimalResult,
            improperFractionResult: entry.improperFractionResult,
            mixedFractionResult: entry.mixedFractionResult,
            createdAt: entry.createdAt,
          ),
        )
        .toList(growable: false);
    _pendingHistorySave = _pendingHistorySave
        .then((_) => store.save(snapshot))
        .catchError((Object _) {});
    unawaited(_pendingHistorySave);
  }

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
    final textRawOffsets = <int>[];

    void appendText(String text, int rawStart, int rawEnd) {
      if (textRawOffsets.isEmpty) textRawOffsets.add(rawStart);
      textBuffer.write(text);
      textRawOffsets.add(rawEnd);
    }

    void flushText() {
      if (textBuffer.isEmpty) return;
      segments.add(
        ExpressionTextSegment(
          text: textBuffer.toString(),
          rawOffsets: List.unmodifiable(textRawOffsets),
        ),
      );
      textBuffer.clear();
      textRawOffsets.clear();
    }

    var lineCharacterCount = 0;
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
            input: fraction,
            activeField: _activeFractionMarker == character
                ? _activeFractionField
                : null,
            activeCaretOffset: _activeFractionMarker == character
                ? _activeFractionCaretOffset
                : null,
          ),
        );
        lineCharacterCount += math.max(
          fraction.numeratorText.length,
          fraction.denominatorText.length,
        );
      } else if (_isOperator(character)) {
        if (lineCharacterCount >= 10) {
          flushText();
          segments.add(const ExpressionLineBreakSegment());
          lineCharacterCount = 0;
        }
        if (textBuffer.isNotEmpty && !textBuffer.toString().endsWith(' ')) {
          appendText(' ', index, index);
        }
        appendText(character, index, index + 1);
        appendText(' ', index + 1, index + 1);
        lineCharacterCount++;
      } else {
        appendText(character, index, index + 1);
        if (character != ' ') lineCharacterCount++;
      }
    }
    flushText();
    return segments;
  }

  String? press(String key) {
    _pendingNotice = null;
    _isProcessingKeyPress = true;
    _keyPressNotificationPending = false;
    try {
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
      if (_state == CalculatorState.input) _updatePreviewResult();
      return _pendingNotice;
    } finally {
      _isProcessingKeyPress = false;
      if (_keyPressNotificationPending) {
        _keyPressNotificationPending = false;
        super.notifyListeners();
      }
    }
  }

  String? insertFunction(String label) {
    _pendingNotice = null;
    if (_activeFractionMarker != null) {
      final notice = _insertFractionFunction(label);
      if (notice == null) _updatePreviewResult();
      return notice;
    }

    if (label == '1/x') {
      return _insertReciprocalFunction();
    }

    final insertion = switch (label) {
      'π' || 'e' || 'φ' => label,
      'log' => 'log(',
      'ln' => 'ln(',
      'log₂' => 'log₂(',
      '√' => '√(',
      '³√' => '³√(',
      '|x|' => 'abs(',
      'x²' => '^2',
      'x³' => '^3',
      '10ˣ' => '10^(',
      'eˣ' => 'e^(',
      'x!' => '!',
      'sin' ||
      'cos' ||
      'tan' ||
      'sin⁻¹' ||
      'cos⁻¹' ||
      'tan⁻¹' ||
      'sinh' ||
      'cosh' ||
      'tanh' ||
      'sinh⁻¹' ||
      'cosh⁻¹' ||
      'tanh⁻¹' => '$label(',
      _ => null,
    };
    if (insertion == null) return 'この関数はまだ利用できません';

    final needsLeftOperand = const {'x²', 'x³', 'x!'}.contains(label);
    if (_state == CalculatorState.result && needsLeftOperand) {
      _startExpressionFromDisplayedResult();
    } else if (_state == CalculatorState.result ||
        _state == CalculatorState.error) {
      clear();
    }

    if (needsLeftOperand && !_hasOperandBeforeCaret) {
      return '先に数値を入力してください';
    }

    final startsNewOperand = !needsLeftOperand;
    if (startsNewOperand && _hasOperandBeforeCaret) {
      _insertAtCaret('×');
    }
    _insertAtCaret(insertion);
    _state = CalculatorState.input;
    _canCycleFraction = false;
    _updatePreviewResult();
    notifyListeners();
    return null;
  }

  String? _insertReciprocalFunction() {
    if (_state == CalculatorState.result || _state == CalculatorState.error) {
      clear();
    }
    if (_hasOperandBeforeCaret) _insertAtCaret('×');

    final marker = String.fromCharCode(0xE000 + _nextFractionId++);
    _fractions[marker] = const FractionInputState(numeratorText: '1');
    _insertAtCaret(marker);
    _activeFractionMarker = marker;
    _activeFractionField = FractionField.denominator;
    _activeFractionCaretOffset = 0;
    _caretPosition = _expression.indexOf(marker);
    _state = CalculatorState.input;
    _canCycleFraction = false;
    _result = '0';
    _isPreviewResult = false;
    notifyListeners();
    return null;
  }

  void calculate() {
    if (_expression.isEmpty || _state == CalculatorState.error) return;
    if (_state == CalculatorState.result) {
      _cycleResultDisplay();
      return;
    }

    try {
      final evaluation = _evaluateCurrentExpression();
      final value = evaluation.approximate;
      _exactResult = evaluation.exact;
      _rawResult = evaluation.exact == null
          ? _rawNumber(value)
          : _roundedExactPlainNumber(evaluation.exact!);
      _result = evaluation.exact == null
          ? _formatNumber(value)
          : _formatExactNumber(evaluation.exact!);
      _state = CalculatorState.result;
      _isPreviewResult = false;
      _errorMessage = null;
      _resultFraction = _findSimpleFraction(value);
      _canCycleFraction = _resultFraction != null;
      _resultDisplayMode = ResultDisplayMode.decimal;
      _caretPosition = _expression.length;
      _activeFractionMarker = null;
      _activeFractionField = null;
      _activeFractionCaretOffset = 0;
      _history.add(
        CalculationHistoryEntry(
          expression: displayExpression,
          result: _result,
          decimalResult: _result,
          improperFractionResult: _resultFraction == null
              ? null
              : '${_resultFraction!.numerator}/${_resultFraction!.denominator}',
          mixedFractionResult: _resultFraction == null
              ? null
              : _mixedFractionText(_resultFraction!),
          createdAt: DateTime.now(),
        ),
      );
      if (_history.length > 50) _history.removeAt(0);
      _saveHistory();
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
    _activeFractionCaretOffset = 0;
    notifyListeners();
  }

  void moveCaretToRawOffset(int rawOffset) {
    if (_state == CalculatorState.error) return;
    if (_state == CalculatorState.result) {
      _state = CalculatorState.input;
      _canCycleFraction = false;
    }
    _caretPosition = rawOffset.clamp(0, _expression.length);
    _activeFractionMarker = null;
    _activeFractionField = null;
    _activeFractionCaretOffset = 0;
    notifyListeners();
  }

  void activateFraction(
    String marker,
    FractionField field, {
    int? caretOffset,
  }) {
    if (!_fractions.containsKey(marker)) return;
    _state = CalculatorState.input;
    _canCycleFraction = false;
    _activeFractionMarker = marker;
    _activeFractionField = field;
    final value = _fractionFieldValue(_fractions[marker]!, field);
    _activeFractionCaretOffset = (caretOffset ?? value.length).clamp(
      0,
      value.length,
    );
    _caretPosition = _expression.indexOf(marker);
    notifyListeners();
  }

  void moveCaretBeforeFraction(String marker) {
    final markerIndex = _expression.indexOf(marker);
    if (markerIndex < 0) return;
    if (_state == CalculatorState.result) {
      _state = CalculatorState.input;
      _canCycleFraction = false;
    }
    _activeFractionMarker = null;
    _activeFractionField = null;
    _activeFractionCaretOffset = 0;
    _caretPosition = markerIndex;
    notifyListeners();
  }

  void moveCaretAfterFraction(String marker) {
    final markerIndex = _expression.indexOf(marker);
    if (markerIndex < 0) return;
    if (_state == CalculatorState.result) {
      _state = CalculatorState.input;
      _canCycleFraction = false;
    }
    _activeFractionMarker = null;
    _activeFractionField = null;
    _activeFractionCaretOffset = 0;
    _caretPosition = markerIndex + 1;
    notifyListeners();
  }

  void pressFractionButton() {
    if (_state == CalculatorState.result) {
      _cycleResultDisplay();
      return;
    }
    if (_state == CalculatorState.error) clear();

    final activeMarker = _activeFractionMarker;
    if (activeMarker != null) {
      final fraction = _fractions[activeMarker]!;
      if (_activeFractionField == FractionField.wholeNumber) {
        _activeFractionField = FractionField.numerator;
        _activeFractionCaretOffset = fraction.numeratorText.length;
      } else if (_activeFractionField == FractionField.numerator) {
        _activeFractionField = FractionField.denominator;
        _activeFractionCaretOffset = fraction.denominatorText.length;
      } else if (fraction.denominatorText.isNotEmpty) {
        _activeFractionMarker = null;
        _activeFractionField = null;
        _activeFractionCaretOffset = 0;
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
    _fractions[marker] = FractionInputState(wholeNumberText: wholeNumber);
    _insertAtCaret(marker);
    _activeFractionMarker = marker;
    _activeFractionField = FractionField.numerator;
    _activeFractionCaretOffset = 0;
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

    final functionToken = _functionTokenBeforeCaret();
    if (functionToken != null) {
      _expression =
          '${_expression.substring(0, _caretPosition - functionToken.length)}'
          '${_expression.substring(_caretPosition)}';
      _caretPosition -= functionToken.length;
      _canCycleFraction = false;
      _updatePreviewResult();
      notifyListeners();
      return;
    }

    final removedCharacter = _expression[_caretPosition - 1];
    _expression =
        '${_expression.substring(0, _caretPosition - 1)}'
        '${_expression.substring(_caretPosition)}';
    if (_isFractionMarker(removedCharacter)) {
      _fractions.remove(removedCharacter);
    }
    _caretPosition--;
    _canCycleFraction = false;
    _updatePreviewResult();
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
      _activeFractionCaretOffset = 0;
      _caretPosition = 0;
      _updatePreviewResult();
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
    _activeFractionCaretOffset = 0;
    _updatePreviewResult();
    _canCycleFraction = false;
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _result = '';
    _rawResult = '';
    _errorMessage = null;
    _state = CalculatorState.input;
    _canCycleFraction = false;
    _isPreviewResult = false;
    _resultDisplayMode = ResultDisplayMode.decimal;
    _resultFraction = null;
    _exactResult = null;
    _caretPosition = 0;
    _fractions.clear();
    _activeFractionMarker = null;
    _activeFractionField = null;
    _activeFractionCaretOffset = 0;
    notifyListeners();
  }

  void editHistoryEntry(CalculationHistoryEntry entry) {
    _expression = '';
    _fractions.clear();
    _activeFractionMarker = null;
    _activeFractionField = null;
    _activeFractionCaretOffset = 0;

    final fractionPattern = RegExp(r'(-?\d+)\s+(\d+)\/(\d+)|(-?\d+)\/(\d+)');
    var sourceOffset = 0;
    for (final match in fractionPattern.allMatches(entry.expression)) {
      _expression += _normalizeHistoryExpression(
        entry.expression.substring(sourceOffset, match.start),
      );
      final marker = String.fromCharCode(0xE000 + _nextFractionId++);
      final isMixedFraction = match.group(1) != null;
      _fractions[marker] = FractionInputState(
        wholeNumberText: isMixedFraction ? match.group(1)! : '',
        numeratorText: isMixedFraction ? match.group(2)! : match.group(4)!,
        denominatorText: isMixedFraction ? match.group(3)! : match.group(5)!,
      );
      _expression += marker;
      sourceOffset = match.end;
    }
    _expression += _normalizeHistoryExpression(
      entry.expression.substring(sourceOffset),
    );

    _result = '0';
    _rawResult = '0';
    _errorMessage = null;
    _state = CalculatorState.input;
    _canCycleFraction = false;
    _isPreviewResult = false;
    _resultDisplayMode = ResultDisplayMode.decimal;
    _resultFraction = null;
    _caretPosition = _expression.length;
    _updatePreviewResult();
    notifyListeners();
  }

  void deleteHistoryEntry(CalculationHistoryEntry entry) {
    if (_history.remove(entry)) {
      _saveHistory();
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    _saveHistory();
    await _pendingHistorySave;
    notifyListeners();
  }

  String _normalizeHistoryExpression(String value) {
    return value.replaceAll(',', '').replaceAll(RegExp(r'\s+'), '');
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
    _updatePreviewResult();
    notifyListeners();
    return true;
  }

  void _insertDigits(String digits) {
    if (_activeFractionMarker != null) {
      _insertFractionDigits(digits);
      return;
    }
    _prepareForNumberInput();
    final currentDigitCount = _numberAroundCaret
        .split('')
        .where(_isDigit)
        .length;
    final normalizedDigits = _expression.isEmpty && digits == '00'
        ? '0'
        : digits;
    final available = numberDigitLimit - currentDigitCount;
    if (available <= 0) {
      _pendingNotice = digitLimitNotice;
      notifyListeners();
      return;
    }
    final accepted = normalizedDigits.substring(
      0,
      normalizedDigits.length.clamp(0, available),
    );
    if (accepted.length < normalizedDigits.length) {
      _pendingNotice = digitLimitNotice;
    }
    if (_isImmediatelyBeforeFractionOperand) {
      final needsMultiplication =
          _caretPosition < _expression.length &&
          _isFractionMarker(_expression[_caretPosition]);
      final insertion = needsMultiplication ? '$accepted×' : accepted;
      _expression =
          '${_expression.substring(0, _caretPosition)}'
          '$insertion'
          '${_expression.substring(_caretPosition)}';
      _caretPosition += accepted.length;
      notifyListeners();
      return;
    }
    if (_characterBeforeCaret == ')' ||
        _characterBeforeCaret == '%' ||
        _isFractionMarker(_characterBeforeCaret)) {
      _insertAtCaret('×');
    }

    _insertAtCaret(accepted);
    notifyListeners();
  }

  void _insertDecimalPoint() {
    if (_activeFractionMarker != null) {
      _insertFractionDecimalPoint();
      return;
    }
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
    if (_activeFractionMarker != null) {
      if (operator != '^') _insertFractionOperator(operator);
      return;
    }
    if (_state == CalculatorState.error) clear();
    if (_state == CalculatorState.result) {
      _startExpressionFromDisplayedResult();
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

  void _startExpressionFromDisplayedResult() {
    final fraction = _resultFraction;
    if (_resultDisplayMode == ResultDisplayMode.decimal || fraction == null) {
      _expression = _rawResult;
      _caretPosition = _expression.length;
    } else {
      _fractions.clear();
      final marker = String.fromCharCode(0xE000 + _nextFractionId++);
      if (_resultDisplayMode == ResultDisplayMode.improperFraction) {
        _fractions[marker] = FractionInputState(
          numeratorText: fraction.numerator.toString(),
          denominatorText: fraction.denominator.toString(),
        );
      } else {
        final absoluteNumerator = fraction.numerator.abs();
        final wholeNumber = absoluteNumerator ~/ fraction.denominator;
        final remainder = absoluteNumerator % fraction.denominator;
        final signedWholeNumber = fraction.numerator < 0
            ? -wholeNumber
            : wholeNumber;
        _fractions[marker] = FractionInputState(
          wholeNumberText: wholeNumber == 0 ? '' : signedWholeNumber.toString(),
          numeratorText: wholeNumber == 0 && fraction.numerator < 0
              ? '-$remainder'
              : remainder.toString(),
          denominatorText: fraction.denominator.toString(),
        );
      }
      _expression = marker;
      _caretPosition = 1;
    }
    _state = CalculatorState.input;
    _resultDisplayMode = ResultDisplayMode.decimal;
    _resultFraction = null;
    _activeFractionMarker = null;
    _activeFractionField = null;
    _activeFractionCaretOffset = 0;
  }

  void _insertParenthesis() {
    if (_activeFractionMarker != null) {
      _insertFractionParenthesis();
      return;
    }
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
    final marker = _activeFractionMarker!;
    final fraction = _fractions[marker]!;
    final field = _activeFractionField!;
    final target = _fractionFieldValue(fraction, field);
    final normalizedDigits = target.isEmpty && digits == '00' ? '0' : digits;
    final digitCount = target.split('').where(_isDigit).length;
    final available = fractionDigitLimit - digitCount;
    if (available <= 0) {
      _pendingNotice = digitLimitNotice;
      return;
    }
    final accepted = normalizedDigits.substring(
      0,
      normalizedDigits.length.clamp(0, available),
    );
    final offset = _activeFractionCaretOffset.clamp(0, target.length);
    final value =
        '${target.substring(0, offset)}'
        '$accepted'
        '${target.substring(offset)}';
    _activeFractionCaretOffset = offset + accepted.length;
    if (accepted.length < normalizedDigits.length) {
      _pendingNotice = digitLimitNotice;
    }
    _setFractionFieldValue(marker, field, value);
  }

  void _insertFractionDecimalPoint() {
    final fraction = _fractions[_activeFractionMarker]!;
    final field = _activeFractionField!;
    if (field == FractionField.wholeNumber) return;

    final value = _fractionFieldValue(fraction, field);
    final offset = _activeFractionCaretOffset.clamp(0, value.length);
    var numberStart = offset;
    while (numberStart > 0 &&
        (_isDigit(value[numberStart - 1]) || value[numberStart - 1] == '.')) {
      numberStart--;
    }
    var numberEnd = offset;
    while (numberEnd < value.length &&
        (_isDigit(value[numberEnd]) || value[numberEnd] == '.')) {
      numberEnd++;
    }
    if (value.substring(numberStart, numberEnd).contains('.')) return;

    _insertIntoActiveFraction(numberStart == offset ? '0.' : '.');
  }

  void _insertFractionOperator(String operator) {
    final fraction = _fractions[_activeFractionMarker]!;
    final field = _activeFractionField!;
    if (field == FractionField.wholeNumber) return;

    final value = _fractionFieldValue(fraction, field);
    final offset = _activeFractionCaretOffset.clamp(0, value.length);
    if (operator == '−' && offset == 0) {
      _insertMinusBeforeActiveFraction();
      return;
    }
    final previous = offset == 0 ? '' : value[offset - 1];
    if (offset == 0 || previous == '(') {
      if (operator == '−') _insertIntoActiveFraction(operator);
      return;
    }
    if (_isOperator(previous)) {
      if (operator == '−' && previous != '−') {
        _insertIntoActiveFraction(operator);
      } else {
        final updated =
            '${value.substring(0, offset - 1)}$operator${value.substring(offset)}';
        _setFractionFieldValue(_activeFractionMarker!, field, updated);
      }
      notifyListeners();
      return;
    }
    if (previous != '.') _insertIntoActiveFraction(operator);
  }

  void _insertMinusBeforeActiveFraction() {
    final marker = _activeFractionMarker!;
    final markerIndex = _expression.indexOf(marker);
    if (markerIndex < 0) return;
    if (markerIndex > 0 && _expression[markerIndex - 1] == '−') return;

    _expression =
        '${_expression.substring(0, markerIndex)}'
        '−${_expression.substring(markerIndex)}';
    _caretPosition = markerIndex + 1;
    notifyListeners();
  }

  void _insertFractionParenthesis() {
    final fraction = _fractions[_activeFractionMarker]!;
    final field = _activeFractionField!;
    if (field == FractionField.wholeNumber) return;

    final value = _fractionFieldValue(fraction, field);
    final offset = _activeFractionCaretOffset.clamp(0, value.length);
    final beforeCaret = value.substring(0, offset);
    final previous = offset == 0 ? '' : value[offset - 1];
    final openCount = '('.allMatches(beforeCaret).length;
    final closeCount = ')'.allMatches(beforeCaret).length;
    if (offset == 0 || _isOperator(previous) || previous == '(') {
      _insertIntoActiveFraction('(');
    } else if (openCount > closeCount) {
      _insertIntoActiveFraction(')');
    } else {
      _insertIntoActiveFraction('×(');
    }
  }

  String? _insertFractionFunction(String label) {
    final fraction = _fractions[_activeFractionMarker]!;
    final field = _activeFractionField!;
    if (field == FractionField.wholeNumber) {
      return '帯分数の整数部分には関数を入力できません';
    }

    final value = _fractionFieldValue(fraction, field);
    final offset = _activeFractionCaretOffset.clamp(0, value.length);
    final previous = offset == 0 ? '' : value[offset - 1];
    final hasLeftOperand = _fractionCharacterIsOperand(previous);
    final needsLeftOperand = const {'x²', 'x³', 'x!'}.contains(label);
    if (needsLeftOperand && !hasLeftOperand) {
      return '先に数値を入力してください';
    }

    final insertion = switch (label) {
      'π' || 'e' || 'φ' => label,
      'log' => 'log(',
      'ln' => 'ln(',
      'log₂' => 'log₂(',
      '√' => '√(',
      '³√' => '³√(',
      '|x|' => 'abs(',
      'x²' => '^2',
      'x³' => '^3',
      '1/x' => '1÷(',
      '10ˣ' => '10^(',
      'eˣ' => 'e^(',
      'x!' => '!',
      'sin' ||
      'cos' ||
      'tan' ||
      'sin⁻¹' ||
      'cos⁻¹' ||
      'tan⁻¹' ||
      'sinh' ||
      'cosh' ||
      'tanh' ||
      'sinh⁻¹' ||
      'cosh⁻¹' ||
      'tanh⁻¹' => '$label(',
      _ => null,
    };
    if (insertion == null) return 'この関数はまだ利用できません';

    final prefix = !needsLeftOperand && hasLeftOperand ? '×' : '';
    _insertIntoActiveFraction('$prefix$insertion');
    return null;
  }

  bool _fractionCharacterIsOperand(String character) =>
      _isDigit(character) ||
      character == ')' ||
      character == '%' ||
      character == '!' ||
      character == 'π' ||
      character == 'φ' ||
      character == 'e';

  void _insertIntoActiveFraction(String insertion) {
    final fraction = _fractions[_activeFractionMarker]!;
    final field = _activeFractionField!;
    final value = _fractionFieldValue(fraction, field);
    final offset = _activeFractionCaretOffset.clamp(0, value.length);
    final updated =
        '${value.substring(0, offset)}$insertion${value.substring(offset)}';
    _setFractionFieldValue(_activeFractionMarker!, field, updated);
    _activeFractionCaretOffset = offset + insertion.length;
    notifyListeners();
  }

  void _backspaceFraction() {
    final marker = _activeFractionMarker!;
    final fraction = _fractions[marker]!;
    final field = _activeFractionField!;
    final value = _fractionFieldValue(fraction, field);
    if (_activeFractionCaretOffset > 0) {
      final offset = _activeFractionCaretOffset.clamp(0, value.length);
      final functionToken = _fractionFunctionTokenBeforeCaret(value, offset);
      if (functionToken != null) {
        final updated =
            '${value.substring(0, offset - functionToken.length)}'
            '${value.substring(offset)}';
        _setFractionFieldValue(marker, field, updated);
        _activeFractionCaretOffset = offset - functionToken.length;
        _updatePreviewResult();
        notifyListeners();
        return;
      }
      final updated =
          '${value.substring(0, offset - 1)}${value.substring(offset)}';
      _setFractionFieldValue(marker, field, updated);
      _activeFractionCaretOffset = offset - 1;
      _updatePreviewResult();
      notifyListeners();
      return;
    }

    if (field == FractionField.denominator) {
      _activeFractionField = FractionField.numerator;
      _activeFractionCaretOffset = fraction.numeratorText.length;
    } else if (field == FractionField.numerator &&
        fraction.wholeNumberText.isNotEmpty) {
      _activeFractionField = FractionField.wholeNumber;
      _activeFractionCaretOffset = fraction.wholeNumberText.length;
    } else if (field == FractionField.wholeNumber) {
      _activeFractionMarker = null;
      _activeFractionField = null;
      _activeFractionCaretOffset = 0;
      _caretPosition = _expression.indexOf(marker);
    } else {
      final index = _expression.indexOf(marker);
      _expression =
          '${_expression.substring(0, index)}'
          '${_expression.substring(index + 1)}';
      _fractions.remove(marker);
      _activeFractionMarker = null;
      _activeFractionField = null;
      _activeFractionCaretOffset = 0;
      _caretPosition = index;
    }
    _updatePreviewResult();
    notifyListeners();
  }

  String? _fractionFunctionTokenBeforeCaret(String value, int offset) {
    final beforeCaret = value.substring(0, offset);
    for (final token in const [
      'sinh⁻¹(',
      'cosh⁻¹(',
      'tanh⁻¹(',
      'sin⁻¹(',
      'cos⁻¹(',
      'tan⁻¹(',
      'sinh(',
      'cosh(',
      'tanh(',
      'sin(',
      'cos(',
      'tan(',
      'log₂(',
      'abs(',
      'log(',
      '10^(',
      '1÷(',
      '³√(',
      'ln(',
      'e^(',
      '√(',
      '^2',
      '^3',
      '!',
    ]) {
      if (beforeCaret.endsWith(token)) return token;
    }
    return null;
  }

  String _fractionFieldValue(FractionInputState fraction, FractionField field) {
    return switch (field) {
      FractionField.wholeNumber => fraction.wholeNumberText,
      FractionField.numerator => fraction.numeratorText,
      FractionField.denominator => fraction.denominatorText,
    };
  }

  void _setFractionFieldValue(
    String marker,
    FractionField field,
    String value,
  ) {
    final current = _fractions[marker]!;
    _fractions[marker] = switch (field) {
      FractionField.wholeNumber => current.copyWith(wholeNumberText: value),
      FractionField.numerator => current.copyWith(numeratorText: value),
      FractionField.denominator => current.copyWith(denominatorText: value),
    };
  }

  void _replaceBeforeCaret(String value) {
    _expression =
        '${_expression.substring(0, _caretPosition - 1)}'
        '$value'
        '${_expression.substring(_caretPosition)}';
  }

  String get _characterBeforeCaret =>
      _caretPosition == 0 ? '' : _expression[_caretPosition - 1];

  bool get _isImmediatelyBeforeFractionOperand {
    if (_caretPosition >= _expression.length) return false;
    if (_isFractionMarker(_expression[_caretPosition])) return true;
    return _expression[_caretPosition] == '×' &&
        _caretPosition + 1 < _expression.length &&
        _isFractionMarker(_expression[_caretPosition + 1]);
  }

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

  bool get _hasOperandBeforeCaret {
    if (_caretPosition == 0) return false;
    final previous = _characterBeforeCaret;
    return _isDigit(previous) ||
        previous == ')' ||
        previous == '%' ||
        previous == '!' ||
        previous == 'π' ||
        previous == 'φ' ||
        previous == 'e' ||
        _isFractionMarker(previous);
  }

  bool _isFractionMarker(String character) =>
      character.isNotEmpty && _fractions.containsKey(character);

  String _fractionAsLinearText(String marker) {
    final fraction = _fractions[marker]!;
    final numerator = fraction.numeratorText.isEmpty
        ? '□'
        : _fractionPartAsLinearText(fraction.numeratorText);
    final denominator = fraction.denominatorText.isEmpty
        ? '□'
        : _fractionPartAsLinearText(fraction.denominatorText);
    final whole = fraction.wholeNumberText.isEmpty
        ? ''
        : '${fraction.wholeNumberText} ';
    return '$whole$numerator/$denominator';
  }

  String _fractionPartAsLinearText(String value) {
    if (value.split('').every((character) => _isDigit(character)) ||
        (value.startsWith('−') &&
            value.substring(1).split('').every(_isDigit))) {
      return value;
    }
    return '($value)';
  }

  String _expandFractionsForCalculation() {
    final buffer = StringBuffer();
    for (final character in _expression.split('')) {
      if (!_isFractionMarker(character)) {
        buffer.write(character);
        continue;
      }

      buffer.write(_fractionExpressionForCalculation(_fractions[character]!));
    }
    return buffer.toString();
  }

  String _fractionExpressionForCalculation(FractionInputState fraction) {
    if (!fraction.isComplete) {
      throw const CalculationException('計算できません');
    }
    final numerator = _completeFractionPart(fraction.numeratorText);
    final denominator = _completeFractionPart(fraction.denominatorText);
    final exactFractionExpression = _exactDecimalFractionExpression(
      numerator,
      denominator,
    );
    if (exactFractionExpression == null) {
      final denominatorValue = _engine.evaluate(
        denominator,
        angleUnit: _angleUnit,
      );
      if (denominatorValue == 0) {
        throw const CalculationException('分母に0は入力できません');
      }
    }
    final fractionExpression =
        exactFractionExpression ?? '(($numerator)÷($denominator))';
    final whole = int.tryParse(fraction.wholeNumberText) ?? 0;
    if (whole == 0) return fractionExpression;
    if (whole < 0) return '($whole−$fractionExpression)';
    return '($whole+$fractionExpression)';
  }

  String? _exactDecimalFractionExpression(
    String numerator,
    String denominator,
  ) {
    final exactNumerator = _ExactDecimal.tryParse(numerator);
    final exactDenominator = _ExactDecimal.tryParse(denominator);
    if (exactNumerator == null || exactDenominator == null) return null;
    if (exactDenominator.unscaled == BigInt.zero) {
      throw const CalculationException('分母に0は入力できません');
    }

    var normalizedNumerator =
        exactNumerator.unscaled * exactDenominator.scaleFactor;
    var normalizedDenominator =
        exactDenominator.unscaled * exactNumerator.scaleFactor;
    if (normalizedDenominator.isNegative) {
      normalizedNumerator = -normalizedNumerator;
      normalizedDenominator = -normalizedDenominator;
    }
    final divisor = normalizedNumerator.abs().gcd(normalizedDenominator.abs());
    normalizedNumerator ~/= divisor;
    normalizedDenominator ~/= divisor;
    return '(($normalizedNumerator)÷($normalizedDenominator))';
  }

  String _completeFractionPart(String value) {
    var openParentheses = 0;
    for (final character in value.split('')) {
      if (character == '(') {
        openParentheses++;
      } else if (character == ')') {
        if (openParentheses == 0) {
          throw const CalculationException('計算できません');
        }
        openParentheses--;
      }
    }
    return '$value${List.filled(openParentheses, ')').join()}';
  }

  String _expressionForCalculation() {
    final expression = _expandFractionsForCalculation();
    var openParentheses = 0;
    for (final character in expression.split('')) {
      if (character == '(') {
        openParentheses++;
      } else if (character == ')') {
        if (openParentheses == 0) return expression;
        openParentheses--;
      }
    }
    return '$expression${List.filled(openParentheses, ')').join()}';
  }

  String? _functionTokenBeforeCaret() {
    final beforeCaret = _expression.substring(0, _caretPosition);
    for (final token in const [
      'sinh⁻¹(',
      'cosh⁻¹(',
      'tanh⁻¹(',
      'sin⁻¹(',
      'cos⁻¹(',
      'tan⁻¹(',
      'sinh(',
      'cosh(',
      'tanh(',
      'sin(',
      'cos(',
      'tan(',
      'log₂(',
      'abs(',
      'log(',
      '10^(',
      '³√(',
      'ln(',
      'e^(',
      '√(',
      '^2',
      '^3',
      '!',
    ]) {
      if (beforeCaret.endsWith(token)) return token;
    }
    return null;
  }

  void _setError(String message) {
    _errorMessage = message;
    _result = '';
    _state = CalculatorState.error;
    _canCycleFraction = false;
    _isPreviewResult = false;
    _resultDisplayMode = ResultDisplayMode.decimal;
    _resultFraction = null;
    _exactResult = null;
  }

  void _updatePreviewResult() {
    if (_state != CalculatorState.input) {
      _isPreviewResult = false;
      return;
    }
    if (_expression.isEmpty) {
      _result = '';
      _rawResult = '';
      _errorMessage = null;
      _isPreviewResult = false;
      notifyListeners();
      return;
    }
    try {
      final evaluation = _evaluateCurrentExpression();
      _exactResult = evaluation.exact;
      _result = evaluation.exact == null
          ? _formatNumber(evaluation.approximate)
          : _formatExactNumber(evaluation.exact!);
      _rawResult = evaluation.exact == null
          ? _rawNumber(evaluation.approximate)
          : _roundedExactPlainNumber(evaluation.exact!);
      _isPreviewResult = true;
    } catch (_) {
      _result = '0';
      _exactResult = null;
      _isPreviewResult = false;
    }
    notifyListeners();
  }

  ({_ExactRational? exact, double approximate}) _evaluateCurrentExpression() {
    final expression = _expressionForCalculation();
    final exact = _ExactExpressionParser.tryEvaluate(expression);
    if (exact != null) {
      return (exact: exact, approximate: exact.toDouble());
    }
    return (
      exact: null,
      approximate: _engine.evaluate(expression, angleUnit: _angleUnit),
    );
  }

  String _formatExactNumber(_ExactRational value) {
    final plain = _roundedExactPlainNumber(value);
    final parts = plain.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final digits = parts.first.replaceFirst('-', '');
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return ['$sign$grouped', if (parts.length == 2) parts[1]].join('.');
  }

  String _roundedExactPlainNumber(_ExactRational value) {
    if (value.numerator == BigInt.zero) return '0';
    final negative = value.numerator.isNegative;
    final factor = BigInt.from(10).pow(_decimalPlaces);
    final scaledNumerator = value.numerator.abs() * factor;
    var quotient = scaledNumerator ~/ value.denominator;
    final remainder = scaledNumerator.remainder(value.denominator);
    final increment = switch (_roundingMode) {
      CalculatorRoundingMode.halfUp =>
        remainder * BigInt.from(2) >= value.denominator,
      CalculatorRoundingMode.ceiling => !negative && remainder != BigInt.zero,
      CalculatorRoundingMode.floor => negative && remainder != BigInt.zero,
    };
    if (increment) quotient += BigInt.one;

    var digits = quotient.toString().padLeft(_decimalPlaces + 1, '0');
    final integerLength = digits.length - _decimalPlaces;
    var result = _decimalPlaces == 0
        ? digits
        : '${digits.substring(0, integerLength)}.'
              '${digits.substring(integerLength)}';
    result = result
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return negative ? '-$result' : result;
  }

  String _rawNumber(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(12)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatNumber(double value) {
    if (value.abs() > standardNumberDisplayLimit) {
      return _formatScientificNumber(value);
    }
    final plain = _roundedPlainNumber(value);
    final parts = plain.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final digits = parts.first.replaceFirst('-', '');
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return ['$sign$grouped', if (parts.length == 2) parts[1]].join('.');
  }

  String _roundedPlainNumber(double value) {
    final factor = math.pow(10, _decimalPlaces).toDouble();
    final scaled = value * factor;
    final rounded = switch (_roundingMode) {
      CalculatorRoundingMode.halfUp => scaled.roundToDouble(),
      CalculatorRoundingMode.ceiling => scaled.ceilToDouble(),
      CalculatorRoundingMode.floor => scaled.floorToDouble(),
    };
    final result = rounded / factor;
    if (result == result.truncateToDouble()) return result.toInt().toString();
    return result
        .toStringAsFixed(_decimalPlaces)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatScientificNumber(double value) {
    final scientific = value.toStringAsExponential(9);
    final parts = scientific.split('e');
    final coefficient = parts.first
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    final exponent = int.parse(parts.last);
    return '$coefficient × 10${_superscript(exponent)}';
  }

  String _superscript(int value) {
    const digits = {
      '-': '⁻',
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
    };
    return value.toString().split('').map((digit) => digits[digit]!).join();
  }

  void _cycleResultDisplay() {
    final fraction = _resultFraction;
    if (fraction == null) {
      _pendingNotice = '分数に変換できません';
      notifyListeners();
      return;
    }

    switch (_resultDisplayMode) {
      case ResultDisplayMode.decimal:
        _resultDisplayMode = ResultDisplayMode.improperFraction;
        _result = '${fraction.numerator}/${fraction.denominator}';
      case ResultDisplayMode.improperFraction:
        _resultDisplayMode = ResultDisplayMode.mixedFraction;
        _result = _mixedFractionText(fraction);
      case ResultDisplayMode.mixedFraction:
        _resultDisplayMode = ResultDisplayMode.decimal;
        _result = _formatNumber(double.parse(_rawResult));
    }
    notifyListeners();
  }

  String _mixedFractionText(_ResultFraction fraction) {
    final absoluteNumerator = fraction.numerator.abs();
    final wholeNumber = absoluteNumerator ~/ fraction.denominator;
    final remainder = absoluteNumerator % fraction.denominator;
    final sign = fraction.numerator < 0 ? '−' : '';
    if (wholeNumber == 0) return '$sign$remainder/${fraction.denominator}';
    return '$sign$wholeNumber $remainder/${fraction.denominator}';
  }

  _ResultFraction? _findSimpleFraction(double value) {
    if (!value.isFinite || value == value.truncateToDouble()) return null;
    final absoluteValue = value.abs();
    for (var denominator = 1; denominator <= 999; denominator++) {
      final numerator = (absoluteValue * denominator).round();
      if (numerator > 999) continue;
      if ((absoluteValue - numerator / denominator).abs() < 1e-6) {
        return _ResultFraction(
          numerator: value < 0 ? -numerator : numerator,
          denominator: denominator,
        );
      }
    }
    return null;
  }
}
