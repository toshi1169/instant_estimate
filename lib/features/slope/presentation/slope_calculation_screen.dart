import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/slope_calculator.dart';

enum _SlopeField { horizontal, height, length, percent, ratio, angle }

class SlopeCalculationScreen extends StatefulWidget {
  const SlopeCalculationScreen({
    this.settings = const AppSettings(),
    super.key,
  });

  final AppSettings settings;

  @override
  State<SlopeCalculationScreen> createState() => _SlopeCalculationScreenState();
}

class _SlopeCalculationScreenState extends State<SlopeCalculationScreen> {
  final _controllers = <_SlopeField, TextEditingController>{
    for (final field in _SlopeField.values) field: TextEditingController(),
  };
  final _extensionController = TextEditingController();

  final List<_SlopeField> _activeFields = [];
  SlopeCalculationResult? _result;
  String? _errorMessage;
  bool _useMillimeters = false;
  bool _updatingControllers = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _extensionController.dispose();
    super.dispose();
  }

  double get _unitFactor => _useMillimeters ? 1000 : 1;
  String get _lengthUnit => _useMillimeters ? 'mm' : 'm';

  double? _number(_SlopeField field) {
    final text = _controllers[field]!.text.trim().replaceAll(',', '.');
    return double.tryParse(text);
  }

  double? _lengthInMeters(_SlopeField field) {
    final value = _number(field);
    return value == null ? null : value / _unitFactor;
  }

  void _recalculate({bool notify = true}) {
    if (_updatingControllers) return;
    if (_activeFields.length < 2 ||
        _activeFields.any(
          (field) => _controllers[field]!.text.trim().isEmpty,
        )) {
      _clearCalculatedFields();
      if (notify && mounted) {
        setState(() {
          _result = null;
          _errorMessage = null;
        });
      } else {
        _result = null;
        _errorMessage = null;
      }
      return;
    }
    try {
      final result = _calculateFromActiveFields();
      _applyResult(result);
      if (notify && mounted) {
        setState(() {
          _result = result;
          _errorMessage = null;
        });
      } else {
        _result = result;
        _errorMessage = null;
      }
    } on FormatException catch (error) {
      _clearCalculatedFields();
      if (notify && mounted) {
        setState(() {
          _result = null;
          _errorMessage = error.message;
        });
      } else {
        _result = null;
        _errorMessage = error.message;
      }
    }
  }

  SlopeCalculationResult _calculateFromActiveFields() {
    final first = _activeFields.first;
    final second = _activeFields.last;
    final lengthFields = {first, second}.where(_isLengthField).toList();
    final slopeFields = {first, second}.where(_isSlopeField).toList();

    if (lengthFields.length == 2) {
      final fields = lengthFields.toSet();
      if (fields.contains(_SlopeField.horizontal) &&
          fields.contains(_SlopeField.height)) {
        return SlopeCalculator.calculate(
          horizontalDistanceMeters:
              _lengthInMeters(_SlopeField.horizontal) ?? double.nan,
          inputType: SlopeInputType.heightDifference,
          inputValue: _lengthInMeters(_SlopeField.height) ?? double.nan,
        );
      }
      if (fields.contains(_SlopeField.horizontal) &&
          fields.contains(_SlopeField.length)) {
        return SlopeCalculator.fromHorizontalAndSlopeLength(
          horizontalDistanceMeters:
              _lengthInMeters(_SlopeField.horizontal) ?? double.nan,
          slopeLengthMeters: _lengthInMeters(_SlopeField.length) ?? double.nan,
        );
      }
      return SlopeCalculator.fromHeightAndSlopeLength(
        heightDifferenceMeters:
            _lengthInMeters(_SlopeField.height) ?? double.nan,
        slopeLengthMeters: _lengthInMeters(_SlopeField.length) ?? double.nan,
      );
    }

    if (lengthFields.length == 1 && slopeFields.length == 1) {
      final lengthField = lengthFields.single;
      final slopeField = slopeFields.single;
      final inputType = _inputTypeFor(slopeField);
      final inputValue = _number(slopeField) ?? double.nan;
      if (lengthField == _SlopeField.horizontal) {
        return SlopeCalculator.calculate(
          horizontalDistanceMeters: _lengthInMeters(lengthField) ?? double.nan,
          inputType: inputType,
          inputValue: inputValue,
        );
      }

      final reference = SlopeCalculator.calculate(
        horizontalDistanceMeters: 1,
        inputType: inputType,
        inputValue: inputValue,
      );
      final length = _lengthInMeters(lengthField) ?? double.nan;
      final horizontalDistance = switch (lengthField) {
        _SlopeField.height =>
          reference.heightDifferenceMeters == 0
              ? double.nan
              : length / reference.heightDifferenceMeters,
        _SlopeField.length => length / reference.slopeLengthMeters,
        _ => double.nan,
      };
      return SlopeCalculator.calculate(
        horizontalDistanceMeters: horizontalDistance,
        inputType: inputType,
        inputValue: inputValue,
      );
    }

    throw const FormatException('距離の項目と1つ以上組み合わせて入力してください');
  }

  bool _isLengthField(_SlopeField field) =>
      field == _SlopeField.horizontal ||
      field == _SlopeField.height ||
      field == _SlopeField.length;

  bool _isSlopeField(_SlopeField field) =>
      field == _SlopeField.percent ||
      field == _SlopeField.ratio ||
      field == _SlopeField.angle;

  SlopeInputType _inputTypeFor(_SlopeField field) => switch (field) {
    _SlopeField.percent => SlopeInputType.gradientPercent,
    _SlopeField.ratio => SlopeInputType.gradientRatio,
    _SlopeField.angle => SlopeInputType.angleDegrees,
    _ => throw const FormatException('勾配の入力項目を選択してください'),
  };

  void _applyResult(SlopeCalculationResult result) {
    _updatingControllers = true;
    final values = <_SlopeField, double>{
      _SlopeField.horizontal: result.horizontalDistanceMeters * _unitFactor,
      _SlopeField.height: result.heightDifferenceMeters * _unitFactor,
      _SlopeField.length: result.slopeLengthMeters * _unitFactor,
      _SlopeField.percent: result.gradientPercent,
      _SlopeField.ratio: result.gradientRatioDenominator ?? 0,
      _SlopeField.angle: result.angleDegrees,
    };
    for (final entry in values.entries) {
      if (!_activeFields.contains(entry.key)) {
        _controllers[entry.key]!.text = _format(entry.value);
      }
    }
    _updatingControllers = false;
  }

  void _clearCalculatedFields() {
    _updatingControllers = true;
    for (final field in _SlopeField.values) {
      if (!_activeFields.contains(field)) _controllers[field]!.clear();
    }
    _updatingControllers = false;
  }

  void _activateField(_SlopeField field) {
    if (_activeFields.contains(field)) return;
    setState(() {
      if (_activeFields.length == 2) {
        _activeFields.removeAt(0);
      }
      _activeFields.add(field);
      _errorMessage = null;
    });
    final controller = _controllers[field]!;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  void _changeUnit(bool millimeters) {
    if (_useMillimeters == millimeters) return;
    final result = _result;
    setState(() {
      _useMillimeters = millimeters;
      if (result != null) {
        _updatingControllers = true;
        _controllers[_SlopeField.horizontal]!.text = _format(
          result.horizontalDistanceMeters * _unitFactor,
        );
        _controllers[_SlopeField.height]!.text = _format(
          result.heightDifferenceMeters * _unitFactor,
        );
        _controllers[_SlopeField.length]!.text = _format(
          result.slopeLengthMeters * _unitFactor,
        );
        final extension = double.tryParse(_extensionController.text) ?? 1;
        _extensionController.text = _format(
          millimeters ? extension * 1000 : extension / 1000,
        );
        _updatingControllers = false;
      }
    });
  }

  void _clear() {
    _updatingControllers = true;
    for (final controller in _controllers.values) {
      controller.clear();
    }
    _extensionController.clear();
    _updatingControllers = false;
    setState(() {
      _activeFields.clear();
      _result = null;
      _errorMessage = null;
    });
  }

  void _showHelp() {
    final strings = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Text(
            strings.text(
              '計算に使う2つの入力欄を順にタップし、数値を入力してください。'
              '残りの値は自動計算されます。法勾配 1:n は、縦1に対する水平距離nを表します。',
            ),
          ),
        ),
      ),
    );
  }

  double get _extensionMeters {
    final value = double.tryParse(
      _extensionController.text.trim().replaceAll(',', '.'),
    );
    return (value ?? 0) / _unitFactor;
  }

  double get _faceArea => (_result?.slopeLengthMeters ?? 0) * _extensionMeters;

  String _format(double value) {
    final rounded = widget.settings.roundCalculationValue(value);
    return rounded.toStringAsFixed(widget.settings.decimalPlaces);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('勾配・法面計算')),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: strings.text('入力方法'),
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: _clear,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(strings.text('クリア')),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                key: const Key('slopeDiagram'),
                painter: _SlopeDiagramPainter(
                  result: _result,
                  color: theme.colorScheme.onSurface,
                  fillColor: AppColors.accent.withValues(alpha: 0.82),
                  unit: _lengthUnit,
                  format: _format,
                  slopeLengthLabel: strings.text('法長'),
                  heightLabel: strings.text('高さ'),
                  horizontalDistanceLabel: strings.text('水平距離'),
                  slopeRatioLabel: strings.text('法勾配'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: strings.text('入力項目（選択した2つから自動計算）'),
              child: Column(
                children: [
                  _InputRow(
                    key: const Key('slopeHorizontalDistance'),
                    label: strings.text('水平距離（H）'),
                    controller: _controllers[_SlopeField.horizontal]!,
                    suffix: _lengthUnit,
                    selected: _activeFields.contains(_SlopeField.horizontal),
                    onTap: () => _activateField(_SlopeField.horizontal),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    key: const Key('slopeHeight'),
                    label: strings.text('高さ（V）'),
                    controller: _controllers[_SlopeField.height]!,
                    suffix: _lengthUnit,
                    selected: _activeFields.contains(_SlopeField.height),
                    onTap: () => _activateField(_SlopeField.height),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    key: const Key('slopeLength'),
                    label: strings.text('法長（L）'),
                    controller: _controllers[_SlopeField.length]!,
                    suffix: _lengthUnit,
                    selected: _activeFields.contains(_SlopeField.length),
                    onTap: () => _activateField(_SlopeField.length),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    key: const Key('slopePercent'),
                    label: strings.text('勾配'),
                    controller: _controllers[_SlopeField.percent]!,
                    suffix: '%',
                    selected: _activeFields.contains(_SlopeField.percent),
                    onTap: () => _activateField(_SlopeField.percent),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    key: const Key('slopeRatio'),
                    label: strings.text('法勾配'),
                    prefix: '1 :',
                    controller: _controllers[_SlopeField.ratio]!,
                    selected: _activeFields.contains(_SlopeField.ratio),
                    onTap: () => _activateField(_SlopeField.ratio),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    key: const Key('slopeAngle'),
                    label: strings.text('角度（θ）'),
                    controller: _controllers[_SlopeField.angle]!,
                    suffix: '°',
                    selected: _activeFields.contains(_SlopeField.angle),
                    onTap: () => _activateField(_SlopeField.angle),
                    onChanged: (_) => _recalculate(),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                strings.text(_errorMessage!),
                key: const Key('slopeCalculationError'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            _SectionCard(
              key: const Key('slopeCalculationResult'),
              title: strings.text('計算結果'),
              child: Column(
                children: [
                  _ResultLine(
                    label: strings.text('勾配（%）'),
                    value: _result == null
                        ? '—'
                        : '${_format(_result!.gradientPercent)} %',
                  ),
                  _ResultLine(
                    label: strings.text('法勾配'),
                    value: _result == null
                        ? '—'
                        : '1 : ${_format(_result!.gradientRatioDenominator ?? 0)}',
                  ),
                  _ResultLine(
                    label: strings.text('角度（θ）'),
                    value: _result == null
                        ? '—'
                        : '${_format(_result!.angleDegrees)} °',
                  ),
                  const Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: Text(strings.text('法面積（延長1mあたり）'))),
                      Text(
                        _result == null
                            ? '—'
                            : _format(_result!.slopeLengthMeters),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('m²'),
                    ],
                  ),
                  const Divider(height: 24),
                  _InputRow(
                    key: const Key('slopeExtension'),
                    label: strings.text('延長'),
                    controller: _extensionController,
                    suffix: _lengthUnit,
                    selected: false,
                    onTap: () {},
                    onChanged: (_) => setState(() {}),
                  ),
                  _ResultLine(
                    label: strings.text('法面積（延長分）'),
                    value: _result == null || _extensionMeters <= 0
                        ? '—'
                        : '${_format(_faceArea)} m²',
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(strings.text('単位'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('m')),
                ButtonSegment(value: true, label: Text('mm')),
              ],
              selected: {_useMillimeters},
              onSelectionChanged: (values) => _changeUnit(values.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    required this.selected,
    required this.onTap,
    required this.onChanged,
    this.prefix,
    this.suffix,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final String? prefix;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (prefix != null) ...[Text(prefix!), const SizedBox(width: 6)],
          SizedBox(
            width: 98,
            height: 42,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              decoration: InputDecoration(
                filled: selected,
                fillColor: AppColors.accent.withValues(alpha: 0.08),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: selected ? AppColors.accent : Colors.grey,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              onTap: onTap,
              onChanged: onChanged,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            SizedBox(width: 30, child: Text(suffix!)),
          ],
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: emphasize ? Colors.red.shade700 : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlopeDiagramPainter extends CustomPainter {
  const _SlopeDiagramPainter({
    required this.result,
    required this.color,
    required this.fillColor,
    required this.unit,
    required this.format,
    required this.slopeLengthLabel,
    required this.heightLabel,
    required this.horizontalDistanceLabel,
    required this.slopeRatioLabel,
  });

  final SlopeCalculationResult? result;
  final Color color;
  final Color fillColor;
  final String unit;
  final String Function(double) format;
  final String slopeLengthLabel;
  final String heightLabel;
  final String horizontalDistanceLabel;
  final String slopeRatioLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final left = Offset(24, size.height - 56);
    final right = Offset(size.width - 54, size.height - 56);
    final top = Offset(right.dx, 50);
    final triangle = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(top.dx, top.dy)
      ..close();
    canvas.drawPath(triangle, Paint()..color = fillColor);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(triangle, linePaint);
    canvas.drawLine(
      Offset(left.dx, left.dy + 18),
      Offset(right.dx, right.dy + 18),
      linePaint,
    );
    canvas.drawLine(
      Offset(right.dx + 20, right.dy),
      Offset(top.dx + 20, top.dy),
      linePaint,
    );

    final result = this.result;
    _text(canvas, 'A', Offset(left.dx - 14, left.dy - 2), color, 13);
    _text(canvas, 'B', Offset(right.dx + 5, right.dy - 2), color, 13);
    _text(canvas, 'C', Offset(top.dx + 4, top.dy - 18), color, 13);
    _text(
      canvas,
      '$slopeLengthLabel (L)\n${result == null ? '—' : format(result.slopeLengthMeters * (unit == 'mm' ? 1000 : 1))} $unit',
      Offset(size.width * 0.21, size.height * 0.29),
      color,
      13,
    );
    _text(
      canvas,
      '$heightLabel (V)\n${result == null ? '—' : format(result.heightDifferenceMeters * (unit == 'mm' ? 1000 : 1))} $unit',
      Offset(size.width - 66, size.height * 0.42),
      color,
      12,
    );
    _text(
      canvas,
      '$horizontalDistanceLabel (H)  ${result == null ? '—' : format(result.horizontalDistanceMeters * (unit == 'mm' ? 1000 : 1))} $unit',
      Offset(size.width * 0.18, size.height - 31),
      color,
      12,
    );
    _text(
      canvas,
      'θ  ${result == null ? '—' : format(result.angleDegrees)}°',
      Offset(left.dx + 48, left.dy - 30),
      Colors.white,
      13,
    );
    _text(
      canvas,
      result == null
          ? '$slopeRatioLabel  —'
          : '$slopeRatioLabel\n1 : ${format(result.gradientRatioDenominator ?? 0)}',
      Offset(size.width * 0.57, size.height * 0.56),
      Colors.white,
      13,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SlopeDiagramPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.color != color ||
        oldDelegate.unit != unit ||
        oldDelegate.slopeLengthLabel != slopeLengthLabel ||
        oldDelegate.heightLabel != heightLabel ||
        oldDelegate.horizontalDistanceLabel != horizontalDistanceLabel ||
        oldDelegate.slopeRatioLabel != slopeRatioLabel;
  }
}
