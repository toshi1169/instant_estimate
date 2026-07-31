import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/calculation_history_store.dart';
import '../domain/calculation_engine.dart';

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

class ExpressionFractionSegment extends ExpressionDisplaySegment {
  const ExpressionFractionSegment({
    required this.marker,
    required this.wholeNumber,
    required this.numerator,
    required this.denominator,
    required this.activeField,
    required this.activeCaretOffset,
  });

  final String marker;
  final String wholeNumber;
  final String numerator;
  final String denominator;
  final FractionField? activeField;
  final int? activeCaretOffset;
}

class _EditableFraction {
  _EditableFraction({this.wholeNumber = ''});

  String wholeNumber;
  String numerator = '';
  String denominator = '';

  bool get isComplete => numerator.isNotEmpty && denominator.isNotEmpty;
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
  });

  static const int fractionDigitLimit = 10;
  static const double standardNumberDisplayLimit = 10000000000000000;

  final CalculationEngine _engine;
  final CalculationHistoryStore? historyStore;
  final List<CalculationHistoryEntry> _history = [];
  Future<void> _pendingHistorySave = Future.value();
  bool _historyLoaded = false;
  bool _historyLoadComplete = false;

  String _expression = '';
  String _result = '0';
  String _rawResult = '0';
  String? _errorMessage;
  CalculatorState _state = CalculatorState.input;
  bool _canCycleFraction = false;
  bool _isPreviewResult = false;
  ResultDisplayMode _resultDisplayMode = ResultDisplayMode.decimal;
  _ResultFraction? _resultFraction;
  String? _pendingNotice;
  int _caretPosition = 0;
  final Map<String, _EditableFraction> _fractions = {};
  String? _activeFractionMarker;
  FractionField? _activeFractionField;
  int _activeFractionCaretOffset = 0;
  int _nextFractionId = 0;

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
            activeCaretOffset: _activeFractionMarker == character
                ? _activeFractionCaretOffset
                : null,
          ),
        );
      } else if (_isOperator(character)) {
        if (textBuffer.isNotEmpty && !textBuffer.toString().endsWith(' ')) {
          appendText(' ', index, index);
        }
        appendText(character, index, index + 1);
        appendText(' ', index + 1, index + 1);
      } else {
        appendText(character, index, index + 1);
      }
    }
    flushText();
    return segments;
  }

  String? press(String key) {
    _pendingNotice = null;
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
  }

  void calculate() {
    if (_expression.isEmpty || _state == CalculatorState.error) return;
    if (_state == CalculatorState.result) {
      _cycleResultDisplay();
      return;
    }

    try {
      final value = _engine.evaluate(_expandFractionsForCalculation());
      _rawResult = _plainNumber(value);
      _result = _formatNumber(value);
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
        _activeFractionCaretOffset = fraction.numerator.length;
      } else if (_activeFractionField == FractionField.numerator) {
        _activeFractionField = FractionField.denominator;
        _activeFractionCaretOffset = fraction.denominator.length;
      } else if (fraction.denominator.isNotEmpty) {
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
    _fractions[marker] = _EditableFraction(wholeNumber: wholeNumber);
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
      _activeFractionCaretOffset = 0;
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
    _activeFractionCaretOffset = 0;
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
    _isPreviewResult = false;
    _resultDisplayMode = ResultDisplayMode.decimal;
    _resultFraction = null;
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
      _fractions[marker] =
          _EditableFraction(wholeNumber: isMixedFraction ? match.group(1)! : '')
            ..numerator = isMixedFraction ? match.group(2)! : match.group(4)!
            ..denominator = isMixedFraction ? match.group(3)! : match.group(5)!;
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
    if (_isImmediatelyBeforeFractionOperand) {
      final needsMultiplication =
          _caretPosition < _expression.length &&
          _isFractionMarker(_expression[_caretPosition]);
      final insertion = needsMultiplication ? '$digits×' : digits;
      _expression =
          '${_expression.substring(0, _caretPosition)}'
          '$insertion'
          '${_expression.substring(_caretPosition)}';
      _caretPosition += digits.length;
      notifyListeners();
      return;
    }
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
        _fractions[marker] = _EditableFraction()
          ..numerator = fraction.numerator.toString()
          ..denominator = fraction.denominator.toString();
      } else {
        final absoluteNumerator = fraction.numerator.abs();
        final wholeNumber = absoluteNumerator ~/ fraction.denominator;
        final remainder = absoluteNumerator % fraction.denominator;
        final signedWholeNumber = fraction.numerator < 0
            ? -wholeNumber
            : wholeNumber;
        _fractions[marker] =
            _EditableFraction(
                wholeNumber: wholeNumber == 0
                    ? ''
                    : signedWholeNumber.toString(),
              )
              ..numerator = wholeNumber == 0 && fraction.numerator < 0
                  ? '-$remainder'
                  : remainder.toString()
              ..denominator = fraction.denominator.toString();
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
    final field = _activeFractionField!;
    final target = _fractionFieldValue(fraction, field);
    final normalizedDigits = target.isEmpty && digits == '00' ? '0' : digits;
    final available = fractionDigitLimit - target.length;
    if (available <= 0) {
      _pendingNotice = 'これ以上入力できません';
      notifyListeners();
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
      _pendingNotice = 'これ以上入力できません';
    }
    _setFractionFieldValue(fraction, field, value);
    notifyListeners();
  }

  void _backspaceFraction() {
    final marker = _activeFractionMarker!;
    final fraction = _fractions[marker]!;
    final field = _activeFractionField!;
    final value = _fractionFieldValue(fraction, field);
    if (_activeFractionCaretOffset > 0) {
      final offset = _activeFractionCaretOffset.clamp(0, value.length);
      final updated =
          '${value.substring(0, offset - 1)}${value.substring(offset)}';
      _setFractionFieldValue(fraction, field, updated);
      _activeFractionCaretOffset = offset - 1;
      notifyListeners();
      return;
    }

    if (field == FractionField.denominator) {
      _activeFractionField = FractionField.numerator;
      _activeFractionCaretOffset = fraction.numerator.length;
    } else if (field == FractionField.numerator &&
        fraction.wholeNumber.isNotEmpty) {
      _activeFractionField = FractionField.wholeNumber;
      _activeFractionCaretOffset = fraction.wholeNumber.length;
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
    notifyListeners();
  }

  String _fractionFieldValue(_EditableFraction fraction, FractionField field) {
    return switch (field) {
      FractionField.wholeNumber => fraction.wholeNumber,
      FractionField.numerator => fraction.numerator,
      FractionField.denominator => fraction.denominator,
    };
  }

  void _setFractionFieldValue(
    _EditableFraction fraction,
    FractionField field,
    String value,
  ) {
    switch (field) {
      case FractionField.wholeNumber:
        fraction.wholeNumber = value;
      case FractionField.numerator:
        fraction.numerator = value;
      case FractionField.denominator:
        fraction.denominator = value;
    }
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
      final improperNumerator = whole < 0
          ? whole * denominator - numerator.abs()
          : whole * denominator + numerator;
      buffer.write('($improperNumerator÷$denominator)');
    }
    return buffer.toString();
  }

  void _setError(String message) {
    _errorMessage = message;
    _result = '';
    _state = CalculatorState.error;
    _canCycleFraction = false;
    _isPreviewResult = false;
    _resultDisplayMode = ResultDisplayMode.decimal;
    _resultFraction = null;
  }

  void _updatePreviewResult() {
    if (_state != CalculatorState.input || _expression.isEmpty) {
      _isPreviewResult = false;
      return;
    }
    try {
      final value = _engine.evaluate(_expandFractionsForCalculation());
      _result = _formatNumber(value);
      _rawResult = _plainNumber(value);
      _isPreviewResult = true;
    } catch (_) {
      _result = '0';
      _isPreviewResult = false;
    }
    notifyListeners();
  }

  String _plainNumber(double value) {
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
    final plain = _plainNumber(value);
    final parts = plain.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final digits = parts.first.replaceFirst('-', '');
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return ['$sign$grouped', if (parts.length == 2) parts[1]].join('.');
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
