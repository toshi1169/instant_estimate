import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/slope_calculator.dart';

enum _SlopeUseCase { drainage, road, face, roof }

enum _SlopeInputMethod {
  heightAndLength,
  horizontalAndRatio,
  heightAndHorizontal,
  lengthAndRatio,
}

enum _SlopeField { horizontal, height, length, percent, ratio, angle }

class SlopeCalculationScreen extends StatefulWidget {
  const SlopeCalculationScreen({
    required this.onSendToEstimate,
    this.settings = const AppSettings(),
    super.key,
  });

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;
  final AppSettings settings;

  @override
  State<SlopeCalculationScreen> createState() => _SlopeCalculationScreenState();
}

class _SlopeCalculationScreenState extends State<SlopeCalculationScreen> {
  final _controllers = <_SlopeField, TextEditingController>{
    for (final field in _SlopeField.values) field: TextEditingController(),
  };
  final _extensionController = TextEditingController(text: '1.00');

  _SlopeUseCase _useCase = _SlopeUseCase.face;
  _SlopeInputMethod _inputMethod = _SlopeInputMethod.heightAndLength;
  SlopeCalculationResult? _result;
  String? _errorMessage;
  bool _useMillimeters = false;
  bool _updatingControllers = false;

  @override
  void initState() {
    super.initState();
    _controllers[_SlopeField.height]!.text = '3.00';
    _controllers[_SlopeField.length]!.text = '5.00';
    _recalculate(notify: false);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _extensionController.dispose();
    super.dispose();
  }

  Set<_SlopeField> get _editableFields => switch (_inputMethod) {
    _SlopeInputMethod.heightAndLength => {
      _SlopeField.height,
      _SlopeField.length,
    },
    _SlopeInputMethod.horizontalAndRatio => {
      _SlopeField.horizontal,
      _SlopeField.ratio,
    },
    _SlopeInputMethod.heightAndHorizontal => {
      _SlopeField.height,
      _SlopeField.horizontal,
    },
    _SlopeInputMethod.lengthAndRatio => {_SlopeField.length, _SlopeField.ratio},
  };

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
    try {
      final result = switch (_inputMethod) {
        _SlopeInputMethod.heightAndLength =>
          SlopeCalculator.fromHeightAndSlopeLength(
            heightDifferenceMeters:
                _lengthInMeters(_SlopeField.height) ?? double.nan,
            slopeLengthMeters:
                _lengthInMeters(_SlopeField.length) ?? double.nan,
          ),
        _SlopeInputMethod.horizontalAndRatio => SlopeCalculator.calculate(
          horizontalDistanceMeters:
              _lengthInMeters(_SlopeField.horizontal) ?? double.nan,
          inputType: SlopeInputType.gradientRatio,
          inputValue: _number(_SlopeField.ratio) ?? double.nan,
        ),
        _SlopeInputMethod.heightAndHorizontal => SlopeCalculator.calculate(
          horizontalDistanceMeters:
              _lengthInMeters(_SlopeField.horizontal) ?? double.nan,
          inputType: SlopeInputType.heightDifference,
          inputValue: _lengthInMeters(_SlopeField.height) ?? double.nan,
        ),
        _SlopeInputMethod.lengthAndRatio =>
          SlopeCalculator.fromSlopeLengthAndGradientRatio(
            slopeLengthMeters:
                _lengthInMeters(_SlopeField.length) ?? double.nan,
            gradientRatioDenominator: _number(_SlopeField.ratio) ?? double.nan,
          ),
      };
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
      if (!_editableFields.contains(entry.key)) {
        _controllers[entry.key]!.text = _format(entry.value);
      }
    }
    _updatingControllers = false;
  }

  void _clearCalculatedFields() {
    _updatingControllers = true;
    for (final field in _SlopeField.values) {
      if (!_editableFields.contains(field)) _controllers[field]!.clear();
    }
    _updatingControllers = false;
  }

  void _changeInputMethod(_SlopeInputMethod method) {
    final result = _result;
    setState(() {
      _inputMethod = method;
      _errorMessage = null;
      if (result != null) _applyResult(result);
    });
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
    _extensionController.text = _useMillimeters ? '1000.00' : '1.00';
    _updatingControllers = false;
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Text(
            '入力方法から2項目の組合せを選び、白い入力欄へ数値を入力してください。'
            '残りの値は自動計算されます。法勾配 1:n は、縦1に対する水平距離nを表します。',
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
    final rounded = widget.settings.roundEstimateQuantity(value);
    return rounded.toStringAsFixed(widget.settings.decimalPlaces);
  }

  String _compact(double value) {
    final text = _format(value);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Future<void> _sendAreaToEstimate() async {
    final result = _result;
    if (result == null || _extensionMeters <= 0) return;
    final area = _faceArea;
    final name = switch (_useCase) {
      _SlopeUseCase.drainage => '排水勾配施工',
      _SlopeUseCase.road => '道路勾配施工',
      _SlopeUseCase.face => '法面工',
      _SlopeUseCase.roof => '屋根勾配施工',
    };
    await widget.onSendToEstimate(
      EstimateItemDraft(
        trade: '勾配・法面',
        name: name,
        specification:
            '法勾配 1 : ${_compact(result.gradientRatioDenominator ?? 0)} / '
            '角度 ${_compact(result.angleDegrees)}°',
        quantity: widget.settings.roundEstimateQuantity(area),
        unit: 'm²',
        calculationBasis:
            '法長 ${_compact(result.slopeLengthMeters)}m × '
            '延長 ${_compact(_extensionMeters)}m',
        originalQuantity: area,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('勾配・法面計算'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: '入力方法',
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
              child: const Text('クリア'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            _UseCaseSelector(
              selected: _useCase,
              onChanged: (value) => setState(() => _useCase = value),
            ),
            const SizedBox(height: 14),
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
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '入力項目（選択した2つから自動計算）',
              child: Column(
                children: [
                  _InputRow(
                    key: const Key('slopeHorizontalDistance'),
                    label: '水平距離（H）',
                    controller: _controllers[_SlopeField.horizontal]!,
                    suffix: _lengthUnit,
                    enabled: _editableFields.contains(_SlopeField.horizontal),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    key: const Key('slopeHeight'),
                    label: '高さ（V）',
                    controller: _controllers[_SlopeField.height]!,
                    suffix: _lengthUnit,
                    enabled: _editableFields.contains(_SlopeField.height),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    key: const Key('slopeLength'),
                    label: '法長（L）',
                    controller: _controllers[_SlopeField.length]!,
                    suffix: _lengthUnit,
                    enabled: _editableFields.contains(_SlopeField.length),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    label: '勾配',
                    controller: _controllers[_SlopeField.percent]!,
                    suffix: '%',
                    enabled: false,
                    onChanged: (_) {},
                  ),
                  _InputRow(
                    label: '法勾配',
                    prefix: '1 :',
                    controller: _controllers[_SlopeField.ratio]!,
                    enabled: _editableFields.contains(_SlopeField.ratio),
                    onChanged: (_) => _recalculate(),
                  ),
                  _InputRow(
                    label: '角度（θ）',
                    controller: _controllers[_SlopeField.angle]!,
                    suffix: '°',
                    enabled: false,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                key: const Key('slopeCalculationError'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            _SectionCard(
              key: const Key('slopeCalculationResult'),
              title: '計算結果',
              child: Column(
                children: [
                  _ResultLine(
                    label: '勾配（%）',
                    value: _result == null
                        ? '—'
                        : '${_format(_result!.gradientPercent)} %',
                  ),
                  _ResultLine(
                    label: '法勾配',
                    value: _result == null
                        ? '—'
                        : '1 : ${_format(_result!.gradientRatioDenominator ?? 0)}',
                  ),
                  _ResultLine(
                    label: '角度（θ）',
                    value: _result == null
                        ? '—'
                        : '${_format(_result!.angleDegrees)} °',
                  ),
                  const Divider(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(child: Text('法面積（延長1mあたり）')),
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
                    label: '延長',
                    controller: _extensionController,
                    suffix: _lengthUnit,
                    enabled: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  _ResultLine(
                    label: '法面積（延長分）',
                    value: _result == null || _extensionMeters <= 0
                        ? '—'
                        : '${_format(_faceArea)} m²',
                    emphasize: true,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('sendSlopeAreaToEstimate'),
                      onPressed: _result == null || _extensionMeters <= 0
                          ? null
                          : _sendAreaToEstimate,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('見積へ追加'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('入力方法', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MethodChip(
                  key: const Key('methodHeightLength'),
                  label: '高さ＋法長',
                  selected: _inputMethod == _SlopeInputMethod.heightAndLength,
                  onTap: () =>
                      _changeInputMethod(_SlopeInputMethod.heightAndLength),
                ),
                _MethodChip(
                  label: '水平距離＋法勾配',
                  selected:
                      _inputMethod == _SlopeInputMethod.horizontalAndRatio,
                  onTap: () =>
                      _changeInputMethod(_SlopeInputMethod.horizontalAndRatio),
                ),
                _MethodChip(
                  label: '高さ＋水平距離',
                  selected:
                      _inputMethod == _SlopeInputMethod.heightAndHorizontal,
                  onTap: () =>
                      _changeInputMethod(_SlopeInputMethod.heightAndHorizontal),
                ),
                _MethodChip(
                  label: '法長＋法勾配',
                  selected: _inputMethod == _SlopeInputMethod.lengthAndRatio,
                  onTap: () =>
                      _changeInputMethod(_SlopeInputMethod.lengthAndRatio),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('法勾配プリセット', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final ratio in [0.5, 1.0, 1.2, 1.5, 1.8, 2.0])
                  ChoiceChip(
                    label: Text('1:${ratio.toStringAsFixed(1)}'),
                    selected:
                        (_number(_SlopeField.ratio) ?? -1) == ratio &&
                        _editableFields.contains(_SlopeField.ratio),
                    onSelected: (_) {
                      if (!_editableFields.contains(_SlopeField.ratio)) {
                        _changeInputMethod(
                          _SlopeInputMethod.horizontalAndRatio,
                        );
                      }
                      _controllers[_SlopeField.ratio]!.text = ratio
                          .toStringAsFixed(1);
                      _recalculate();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('単位', style: theme.textTheme.titleMedium),
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

class _UseCaseSelector extends StatelessWidget {
  const _UseCaseSelector({required this.selected, required this.onChanged});

  final _SlopeUseCase selected;
  final ValueChanged<_SlopeUseCase> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      _SlopeUseCase.drainage: '排水勾配',
      _SlopeUseCase.road: '道路勾配',
      _SlopeUseCase.face: '法面',
      _SlopeUseCase.roof: '屋根勾配',
    };
    return Row(
      children: [
        for (final value in _SlopeUseCase.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(labels[value]!, textAlign: TextAlign.center),
                ),
                selected: selected == value,
                onSelected: (_) => onChanged(value),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              ),
            ),
          ),
      ],
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
    required this.enabled,
    required this.onChanged,
    this.prefix,
    this.suffix,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
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
              enabled: enabled,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
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

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
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
  });

  final SlopeCalculationResult? result;
  final Color color;
  final Color fillColor;
  final String unit;
  final String Function(double) format;

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
      '法長 (L)\n${result == null ? '—' : format(result.slopeLengthMeters * (unit == 'mm' ? 1000 : 1))} $unit',
      Offset(size.width * 0.21, size.height * 0.29),
      color,
      13,
    );
    _text(
      canvas,
      '高さ (V)\n${result == null ? '—' : format(result.heightDifferenceMeters * (unit == 'mm' ? 1000 : 1))} $unit',
      Offset(size.width - 66, size.height * 0.42),
      color,
      12,
    );
    _text(
      canvas,
      '水平距離 (H)  ${result == null ? '—' : format(result.horizontalDistanceMeters * (unit == 'mm' ? 1000 : 1))} $unit',
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
          ? '法勾配  —'
          : '法勾配\n1 : ${format(result.gradientRatioDenominator ?? 0)}',
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
        oldDelegate.unit != unit;
  }
}
