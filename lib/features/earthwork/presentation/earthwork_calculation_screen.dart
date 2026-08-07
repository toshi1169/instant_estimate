import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../domain/earthwork_calculator.dart';

enum _EarthworkEstimateTarget { excavation, backfill, haul, dump }

class EarthworkCalculationScreen extends StatefulWidget {
  const EarthworkCalculationScreen({required this.onSendToEstimate, super.key});

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;

  @override
  State<EarthworkCalculationScreen> createState() =>
      _EarthworkCalculationScreenState();
}

class _EarthworkCalculationScreenState
    extends State<EarthworkCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _structureController = TextEditingController(text: '0');
  final _factorController = TextEditingController(text: '1.25');
  final _dumpCapacityController = TextEditingController(text: '4');

  EarthworkCalculationResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _structureController.dispose();
    _factorController.dispose();
    _dumpCapacityController.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final result = EarthworkCalculator.calculate(
        lengthMeters: _parse(_lengthController.text),
        widthMeters: _parse(_widthController.text),
        depthMeters: _parse(_depthController.text),
        structureVolumeCubicMeters: _parseOptional(_structureController.text),
        soilChangeFactor: _parse(_factorController.text),
        dumpCapacityCubicMeters: _parse(_dumpCapacityController.text),
      );
      setState(() {
        _result = result;
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
      _lengthController.clear();
      _widthController.clear();
      _depthController.clear();
      _structureController.text = '0';
      _factorController.text = '1.25';
      _dumpCapacityController.text = '4';
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _sendToEstimate(_EarthworkEstimateTarget target) async {
    final result = _result;
    if (result == null) return;
    final dimensions =
        'L=${_format(result.lengthMeters)}m '
        'W=${_format(result.widthMeters)}m '
        'H=${_format(result.depthMeters)}m';
    late final EstimateItemDraft draft;
    switch (target) {
      case _EarthworkEstimateTarget.excavation:
        draft = EstimateItemDraft(
          trade: '土工',
          name: '掘削',
          specification: dimensions,
          quantity: result.excavationVolume,
          unit: 'm³',
          calculationBasis:
              '${_format(result.lengthMeters)} × '
              '${_format(result.widthMeters)} × '
              '${_format(result.depthMeters)} ＝ '
              '${_format(result.excavationVolume)}m³',
          originalQuantity: result.excavationVolume,
        );
      case _EarthworkEstimateTarget.backfill:
        draft = EstimateItemDraft(
          trade: '土工',
          name: '埋戻し',
          specification:
              '$dimensions 構造物=${_format(result.structureVolumeCubicMeters)}m³',
          quantity: result.backfillVolume,
          unit: 'm³',
          calculationBasis:
              '掘削量${_format(result.excavationVolume)} － '
              '構造物${_format(result.structureVolumeCubicMeters)} ＝ '
              '${_format(result.backfillVolume)}m³',
          originalQuantity: result.backfillVolume,
        );
      case _EarthworkEstimateTarget.haul:
        draft = EstimateItemDraft(
          trade: '土工',
          name: '搬出土',
          specification:
              '$dimensions 土量変化率=${_format(result.soilChangeFactor)}',
          quantity: result.haulVolume,
          unit: 'm³',
          calculationBasis:
              '掘削量${_format(result.excavationVolume)} × '
              '変化率${_format(result.soilChangeFactor)} ＝ '
              '${_format(result.haulVolume)}m³',
          originalQuantity: result.haulVolume,
        );
      case _EarthworkEstimateTarget.dump:
        draft = EstimateItemDraft(
          trade: '土工',
          name: 'ダンプ運搬',
          specification:
              '搬出土=${_format(result.haulVolume)}m³ '
              '積載容量=${_format(result.dumpCapacityCubicMeters)}m³/台',
          quantity: result.dumpTrips.toDouble(),
          unit: '台',
          calculationBasis:
              '${_format(result.haulVolume)} ÷ '
              '${_format(result.dumpCapacityCubicMeters)} ＝ '
              '${result.dumpTrips}台（切上げ）',
          originalQuantity: result.dumpTrips.toDouble(),
        );
    }
    await widget.onSendToEstimate(draft);
  }

  double _parse(String text) => double.parse(text.trim().replaceAll(',', '.'));

  double _parseOptional(String text) => text.trim().isEmpty ? 0 : _parse(text);

  String? _validatePositive(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite || number <= 0) {
      return '0より大きい数値を入力';
    }
    return null;
  }

  String? _validateNonNegative(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final number = double.tryParse(value!.trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite || number < 0) {
      return '0以上の数値を入力';
    }
    return null;
  }

  String _format(double value) {
    final text = value.toStringAsFixed(3);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('土量計算'),
        actions: [TextButton(onPressed: _clear, child: const Text('クリア'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(
              '掘削寸法から、掘削・埋戻し・搬出土・ダンプ必要台数をまとめて計算します。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          keyName: 'earthworkLength',
                          controller: _lengthController,
                          label: '長さ',
                          suffix: 'm',
                          validator: _validatePositive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          keyName: 'earthworkWidth',
                          controller: _widthController,
                          label: '幅',
                          suffix: 'm',
                          validator: _validatePositive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    keyName: 'earthworkDepth',
                    controller: _depthController,
                    label: '深さ',
                    suffix: 'm',
                    validator: _validatePositive,
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    keyName: 'earthworkStructureVolume',
                    controller: _structureController,
                    label: '構造物体積（埋戻し控除）',
                    suffix: 'm³',
                    validator: _validateNonNegative,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          keyName: 'earthworkSoilFactor',
                          controller: _factorController,
                          label: '土量変化率',
                          validator: _validatePositive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          keyName: 'earthworkDumpCapacity',
                          controller: _dumpCapacityController,
                          label: '積載容量',
                          suffix: 'm³/台',
                          validator: _validatePositive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: const Key('calculateEarthwork'),
              onPressed: _calculate,
              icon: const Icon(Icons.landscape_outlined),
              label: const Text('土量を計算'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const Key('earthworkCalculationError'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: 18),
              Text('計算結果', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              _ResultCard(
                key: const Key('earthworkExcavationResult'),
                label: '掘削量',
                value: '${_format(result.excavationVolume)} m³',
                onSend: () =>
                    _sendToEstimate(_EarthworkEstimateTarget.excavation),
              ),
              _ResultCard(
                key: const Key('earthworkBackfillResult'),
                label: '埋戻し量',
                value: '${_format(result.backfillVolume)} m³',
                onSend: result.backfillVolume == 0
                    ? null
                    : () => _sendToEstimate(_EarthworkEstimateTarget.backfill),
              ),
              _ResultCard(
                key: const Key('earthworkHaulResult'),
                label: '搬出土量',
                value: '${_format(result.haulVolume)} m³',
                onSend: () => _sendToEstimate(_EarthworkEstimateTarget.haul),
              ),
              _ResultCard(
                key: const Key('earthworkDumpResult'),
                label: 'ダンプ必要台数',
                value: '${result.dumpTrips} 台',
                note: '端数切上げ',
                onSend: () => _sendToEstimate(_EarthworkEstimateTarget.dump),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? suffix,
  }) {
    return TextFormField(
      key: Key(keyName),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: validator,
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.label,
    required this.value,
    required this.onSend,
    this.note,
    super.key,
  });

  final String label;
  final String value;
  final String? note;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (note != null)
                    Text(note!, style: theme.textTheme.bodySmall),
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
