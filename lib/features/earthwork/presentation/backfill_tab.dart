import 'package:flutter/material.dart';

import '../../estimate/domain/estimate_item_draft.dart';
import '../domain/earthwork_calculator.dart';
import 'earthwork_common_widgets.dart';

class BackfillTab extends StatefulWidget {
  const BackfillTab({required this.onSendToEstimate, super.key});

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;

  @override
  State<BackfillTab> createState() => _BackfillTabState();
}

class _BackfillTabState extends State<BackfillTab> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _structureController = TextEditingController(text: '0');
  final _compactionController = TextEditingController(text: '0.90');
  BackfillCalculationResult? _result;
  String? _error;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _structureController.dispose();
    _compactionController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final result = EarthworkCalculator.calculateBackfill(
        lengthMeters: parseEarthworkNumber(_lengthController.text),
        widthMeters: parseEarthworkNumber(_widthController.text),
        depthMeters: parseEarthworkNumber(_depthController.text),
        structureVolumeCubicMeters: parseOptionalEarthworkNumber(
          _structureController.text,
        ),
        compactionFactor: parseEarthworkNumber(_compactionController.text),
      );
      setState(() {
        _result = result;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error.message.toString();
      });
    }
  }

  void _clear() {
    setState(() {
      _lengthController.clear();
      _widthController.clear();
      _depthController.clear();
      _structureController.text = '0';
      _compactionController.text = '0.90';
      _result = null;
      _error = null;
    });
  }

  String get _dimensions =>
      'L=${formatEarthworkNumber(parseEarthworkNumber(_lengthController.text))}m '
      '× W=${formatEarthworkNumber(parseEarthworkNumber(_widthController.text))}m '
      '× H=${formatEarthworkNumber(parseEarthworkNumber(_depthController.text))}m';

  Future<void> _send({
    required String name,
    required double quantity,
    required String basis,
    String specification = '',
  }) {
    return widget.onSendToEstimate(
      EstimateItemDraft(
        trade: '土工',
        name: name,
        quantity: quantity,
        originalQuantity: quantity,
        unit: 'm³',
        specification: specification,
        calculationBasis: basis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '構造物施工後に戻す土量を算出します。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(onPressed: _clear, child: const Text('入力を消去')),
            ],
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'backfillLength',
            controller: _lengthController,
            label: '長さ',
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'backfillWidth',
            controller: _widthController,
            label: '幅',
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'backfillDepth',
            controller: _depthController,
            label: '深さ',
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'earthworkStructureVolume',
            controller: _structureController,
            label: '控除する構造物体積（任意）',
            suffix: 'm³',
            helperText: '入力しない場合は0m³',
            validator: validateNonNegativeEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'backfillCompactionFactor',
            controller: _compactionController,
            label: '締固め係数',
            helperText: '初期参考値 0.90（現場条件に合わせて変更可能）',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('calculateBackfill'),
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('計算する'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            EarthworkResultCard(
              label: '掘削体積',
              value: '${formatEarthworkNumber(result.excavationVolume)} m³',
              onSend: () => _send(
                name: '掘削',
                quantity: result.excavationVolume,
                specification: _dimensions,
                basis:
                    '$_dimensions = ${formatEarthworkNumber(result.excavationVolume)}m³',
              ),
            ),
            EarthworkResultCard(
              label: '埋戻し対象体積',
              value: '${formatEarthworkNumber(result.backfillTargetVolume)} m³',
              note: '掘削体積 − 控除する構造物体積',
              onSend: () => _send(
                name: '埋戻し',
                quantity: result.backfillTargetVolume,
                specification:
                    '控除 ${formatEarthworkNumber(result.structureVolumeCubicMeters)}m³',
                basis:
                    '${formatEarthworkNumber(result.excavationVolume)} − '
                    '${formatEarthworkNumber(result.structureVolumeCubicMeters)} = '
                    '${formatEarthworkNumber(result.backfillTargetVolume)}m³',
              ),
            ),
            EarthworkResultCard(
              label: '必要土量',
              value: '${formatEarthworkNumber(result.requiredBankVolume)} m³',
              note:
                  '埋戻し対象体積 ÷ 締固め係数 ${formatEarthworkNumber(result.compactionFactor)}',
              onSend: () => _send(
                name: '埋戻し必要土',
                quantity: result.requiredBankVolume,
                specification:
                    '締固め係数 ${formatEarthworkNumber(result.compactionFactor)}',
                basis:
                    '${formatEarthworkNumber(result.backfillTargetVolume)} ÷ '
                    '${formatEarthworkNumber(result.compactionFactor)} = '
                    '${formatEarthworkNumber(result.requiredBankVolume)}m³',
              ),
            ),
            EarthworkResultCard(
              label: result.hasSurplus ? '余剰土量' : '不足土量',
              value: '${formatEarthworkNumber(result.balanceVolume.abs())} m³',
              onSend: () => _send(
                name: result.hasSurplus ? '余剰土' : '不足土',
                quantity: result.balanceVolume.abs(),
                basis:
                    '${formatEarthworkNumber(result.excavationVolume)} − '
                    '${formatEarthworkNumber(result.requiredBankVolume)} = '
                    '${formatEarthworkNumber(result.balanceVolume)}m³',
              ),
            ),
          ],
          const EarthworkReferenceNote(),
        ],
      ),
    );
  }
}
