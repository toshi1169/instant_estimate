import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/slope_calculator.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _horizontalController = TextEditingController();
  final _valueController = TextEditingController();
  SlopeInputType _inputType = SlopeInputType.heightDifference;
  SlopeCalculationResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _horizontalController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      setState(() {
        _result = SlopeCalculator.calculate(
          horizontalDistanceMeters: _parse(_horizontalController.text),
          inputType: _inputType,
          inputValue: _parse(_valueController.text),
        );
        _errorMessage = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _errorMessage = error.message;
      });
    }
  }

  void _clear() {
    setState(() {
      _horizontalController.clear();
      _valueController.clear();
      _inputType = SlopeInputType.heightDifference;
      _result = null;
      _errorMessage = null;
    });
  }

  double _parse(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));

  String? _validatePositive(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite || number <= 0) {
      return '0より大きい数値を入力';
    }
    return null;
  }

  String? _validateInput(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite || number < 0) {
      return '0以上の数値を入力';
    }
    if (_inputType == SlopeInputType.gradientRatio && number == 0) {
      return '0より大きい数値を入力';
    }
    if (_inputType == SlopeInputType.angleDegrees && number >= 90) {
      return '90度未満で入力';
    }
    return null;
  }

  String get _inputLabel => switch (_inputType) {
    SlopeInputType.heightDifference => '高低差',
    SlopeInputType.gradientPercent => '勾配',
    SlopeInputType.gradientRatio => '勾配比 1 : n の n',
    SlopeInputType.angleDegrees => '角度',
  };

  String? get _inputSuffix => switch (_inputType) {
    SlopeInputType.heightDifference => 'm',
    SlopeInputType.gradientPercent => '%',
    SlopeInputType.gradientRatio => null,
    SlopeInputType.angleDegrees => '°',
  };

  String _format(double value) {
    final text = value.toStringAsFixed(3);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String _specification(SlopeCalculationResult result) {
    final ratio = result.gradientRatioDenominator;
    return '水平距離 ${_format(result.horizontalDistanceMeters)}m / '
        '勾配 ${_format(result.gradientPercent)}% / '
        '${ratio == null ? '水平' : '1 : ${_format(ratio)}'}';
  }

  Future<void> _sendLength({
    required String name,
    required double quantity,
  }) async {
    final result = _result;
    if (result == null) return;
    await widget.onSendToEstimate(
      EstimateItemDraft(
        trade: '勾配・法面',
        name: name,
        specification: _specification(result),
        quantity: widget.settings.roundEstimateQuantity(quantity),
        unit: 'm',
        calculationBasis: name == '高低差'
            ? '${_format(result.horizontalDistanceMeters)}m × '
                  '${_format(result.gradientPercent)}%'
            : '√(${_format(result.horizontalDistanceMeters)}² + '
                  '${_format(result.heightDifferenceMeters)}²)',
        originalQuantity: quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('勾配計算'),
        actions: [TextButton(onPressed: _clear, child: const Text('クリア'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(
              '水平距離と1つの条件から、勾配・角度・高低差・斜距離を相互換算します。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('slopeHorizontalDistance'),
                    controller: _horizontalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '水平距離',
                      suffixText: 'm',
                    ),
                    validator: _validatePositive,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SlopeInputType>(
                    key: const Key('slopeInputType'),
                    initialValue: _inputType,
                    decoration: const InputDecoration(labelText: '入力する条件'),
                    items: const [
                      DropdownMenuItem(
                        value: SlopeInputType.heightDifference,
                        child: Text('高低差'),
                      ),
                      DropdownMenuItem(
                        value: SlopeInputType.gradientPercent,
                        child: Text('勾配（%）'),
                      ),
                      DropdownMenuItem(
                        value: SlopeInputType.gradientRatio,
                        child: Text('勾配比（1 : n）'),
                      ),
                      DropdownMenuItem(
                        value: SlopeInputType.angleDegrees,
                        child: Text('角度（°）'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _inputType = value;
                        _valueController.clear();
                        _result = null;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('slopeInputValue'),
                    controller: _valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: _inputLabel,
                      suffixText: _inputSuffix,
                    ),
                    validator: _validateInput,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: const Key('calculateSlope'),
              onPressed: _calculate,
              icon: const Icon(Icons.show_chart),
              label: const Text('勾配を計算'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  key: const Key('slopeCalculationError'),
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('slopeCalculationResult'),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('計算結果', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _ResultLine(
                      label: '勾配',
                      value: '${_format(result.gradientPercent)} %',
                    ),
                    _ResultLine(
                      label: '勾配比',
                      value: result.gradientRatioDenominator == null
                          ? '水平'
                          : '1 : ${_format(result.gradientRatioDenominator!)}',
                    ),
                    _ResultLine(
                      label: '角度',
                      value: '${_format(result.angleDegrees)} °',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _EstimateResultCard(
                key: const Key('slopeHeightResult'),
                label: '高低差',
                value: '${_format(result.heightDifferenceMeters)} m',
                onSend: () => _sendLength(
                  name: '高低差',
                  quantity: result.heightDifferenceMeters,
                ),
              ),
              const SizedBox(height: 10),
              _EstimateResultCard(
                key: const Key('slopeLengthResult'),
                label: '斜距離',
                value: '${_format(result.slopeLengthMeters)} m',
                onSend: () => _sendLength(
                  name: '斜距離',
                  quantity: result.slopeLengthMeters,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              '※ 勾配・角度は入力条件により換算した参考値です。設計図書・現場条件を確認してください。',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateResultCard extends StatelessWidget {
  const _EstimateResultCard({
    required this.label,
    required this.value,
    required this.onSend,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('見積へ'),
            ),
          ],
        ),
      ),
    );
  }
}
