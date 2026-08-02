import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/estimate_item_draft.dart';

enum EstimateItemEditorAction { continueCalculating, openEstimate }

class EstimateItemEditorResult {
  const EstimateItemEditorResult({required this.draft, required this.action});

  final EstimateItemDraft draft;
  final EstimateItemEditorAction action;
}

class EstimateItemEditorScreen extends StatefulWidget {
  const EstimateItemEditorScreen({required this.initialDraft, super.key});

  final EstimateItemDraft initialDraft;

  @override
  State<EstimateItemEditorScreen> createState() =>
      _EstimateItemEditorScreenState();
}

class _EstimateItemEditorScreenState extends State<EstimateItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _trade = TextEditingController(text: widget.initialDraft.trade);
  late final _name = TextEditingController(text: widget.initialDraft.name);
  late final _specification = TextEditingController(
    text: widget.initialDraft.specification,
  );
  late final _quantity = TextEditingController(
    text: _editableNumber(widget.initialDraft.quantity),
  );
  late final _unit = TextEditingController(text: widget.initialDraft.unit);
  late final _unitPrice = TextEditingController(
    text: _editableNumber(widget.initialDraft.unitPrice),
  );
  late final _description = TextEditingController(
    text: widget.initialDraft.description,
  );

  @override
  void dispose() {
    _trade.dispose();
    _name.dispose();
    _specification.dispose();
    _quantity.dispose();
    _unit.dispose();
    _unitPrice.dispose();
    _description.dispose();
    super.dispose();
  }

  double? get _quantityValue => _parseNumber(_quantity.text);
  double? get _unitPriceValue => _parseNumber(_unitPrice.text);

  double? get _amount {
    final quantity = _quantityValue;
    final unitPrice = _unitPriceValue;
    if (quantity == null || unitPrice == null) return null;
    return quantity * unitPrice;
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _parseNumber(value) == null ? '数値を入力してください' : null;
  }

  void _complete(EstimateItemEditorAction action) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      EstimateItemEditorResult(
        action: action,
        draft: widget.initialDraft.copyWith(
          trade: _trade.text.trim(),
          name: _name.text.trim(),
          specification: _specification.text.trim(),
          quantity: _quantityValue,
          clearQuantity: _quantity.text.trim().isEmpty,
          unit: _unit.text.trim(),
          unitPrice: _unitPriceValue,
          clearUnitPrice: _unitPrice.text.trim().isEmpty,
          description: _description.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('見積明細へ追加')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            key: const Key('estimateItemEditor'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('追加先'),
                  subtitle: const Text('名称未設定の見積'),
                  trailing: TextButton(
                    onPressed: null,
                    child: const Text('変更'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _field(_trade, '工種', key: const Key('estimateTradeField')),
              _field(_name, '名称', key: const Key('estimateNameField')),
              _field(
                _specification,
                '仕様',
                key: const Key('estimateSpecificationField'),
                maxLines: 2,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _numberField(
                      _quantity,
                      '数量',
                      key: const Key('estimateQuantityField'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _unit,
                      '単位',
                      key: const Key('estimateUnitField'),
                    ),
                  ),
                ],
              ),
              _numberField(
                _unitPrice,
                '単価',
                key: const Key('estimateUnitPriceField'),
                prefixText: '¥ ',
              ),
              ListenableBuilder(
                listenable: Listenable.merge([_quantity, _unitPrice]),
                builder: (context, _) => InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '金額（数量 × 単価）',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _amount == null ? '—' : '¥ ${_displayAmount(_amount!)}',
                    key: const Key('estimateAmountValue'),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _field(
                _description,
                '摘要',
                key: const Key('estimateDescriptionField'),
                maxLines: 3,
              ),
              if (widget.initialDraft.calculationBasis.isNotEmpty)
                ExpansionTile(
                  key: const Key('calculationBasisTile'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('計算根拠'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(widget.initialDraft.calculationBasis),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('addEstimateAndContinue'),
                onPressed: () =>
                    _complete(EstimateItemEditorAction.continueCalculating),
                child: const Text('追加して続ける'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('addEstimateAndOpen'),
                onPressed: () =>
                    _complete(EstimateItemEditorAction.openEstimate),
                child: const Text('追加して見積を開く'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required Key key,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    required Key key,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,+\-eE]')),
        ],
        validator: _validateNumber,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

double? _parseNumber(String value) {
  final normalized = value.replaceAll(',', '').trim();
  if (normalized.isEmpty) return null;
  final parsed = double.tryParse(normalized);
  return parsed != null && parsed.isFinite ? parsed : null;
}

String _editableNumber(double? value) {
  if (value == null) return '';
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
}

String _displayAmount(double value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return rounded < 0 ? '-$grouped' : grouped;
}
