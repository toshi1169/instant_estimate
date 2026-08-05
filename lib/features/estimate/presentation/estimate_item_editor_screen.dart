import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/estimate_item_draft.dart';
import '../domain/unit_price_master.dart';

enum EstimateItemEditorAction { continueCalculating, openEstimate }

class EstimateItemEditorResult {
  const EstimateItemEditorResult({
    required this.draft,
    required this.action,
    this.saveToUnitPriceMaster = false,
  });

  final EstimateItemDraft draft;
  final EstimateItemEditorAction action;
  final bool saveToUnitPriceMaster;
}

class EstimateItemEditorScreen extends StatefulWidget {
  const EstimateItemEditorScreen({
    required this.initialDraft,
    this.isEditing = false,
    this.showOpenEstimateAction = true,
    this.estimateTitle = '名称未設定の見積',
    this.unitPriceMasters = const [],
    super.key,
  });

  final EstimateItemDraft initialDraft;
  final bool isEditing;
  final bool showOpenEstimateAction;
  final String estimateTitle;
  final List<UnitPriceMaster> unitPriceMasters;

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
  bool _saveToUnitPriceMaster = false;

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
        saveToUnitPriceMaster:
            _saveToUnitPriceMaster &&
            _name.text.trim().isNotEmpty &&
            _unitPriceValue != null,
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

  Future<void> _selectUnitPriceMaster() async {
    var filtered = widget.unitPriceMasters;
    final selected = await showModalBottomSheet<UnitPriceMaster>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '単価マスタから選択',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${filtered.length} / ${widget.unitPriceMasters.length}件',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    key: const Key('selectUnitPriceMasterSearch'),
                    autofocus: widget.unitPriceMasters.length > 8,
                    onChanged: (query) {
                      setModalState(() {
                        filtered = widget.unitPriceMasters
                            .where(
                              (price) =>
                                  matchesUnitPriceMasterQuery(price, query),
                            )
                            .toList(growable: false);
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: '単価を検索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('一致する単価がありません'))
                      : ListView.separated(
                          key: const Key('selectUnitPriceMasterList'),
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final price = filtered[index];
                            return ListTile(
                              key: Key('selectUnitPrice-${price.id}'),
                              title: Text(price.name),
                              subtitle: Text(
                                [
                                  if (price.trade.isNotEmpty) price.trade,
                                  if (price.specification.isNotEmpty)
                                    price.specification,
                                  if (price.unit.isNotEmpty) price.unit,
                                ].join(' ／ '),
                              ),
                              trailing: Text(
                                price.unitPrice == null
                                    ? '未入力'
                                    : '¥ ${_displayAmount(price.unitPrice!)}',
                              ),
                              onTap: () => Navigator.of(context).pop(price),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _trade.text = selected.trade;
      _name.text = selected.name;
      _specification.text = selected.specification;
      _unit.text = selected.unit;
      _unitPrice.text = _editableNumber(selected.unitPrice);
      _description.text = selected.description;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '見積明細を編集' : '見積明細へ追加')),
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
                  subtitle: Text(widget.estimateTitle),
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
              OutlinedButton.icon(
                key: const Key('selectUnitPriceMaster'),
                onPressed: widget.unitPriceMasters.isEmpty
                    ? null
                    : _selectUnitPriceMaster,
                icon: const Icon(Icons.price_check_outlined),
                label: Text(
                  widget.unitPriceMasters.isEmpty
                      ? '単価マスタ（登録なし）'
                      : '単価マスタから選択（${widget.unitPriceMasters.length}件）',
                ),
              ),
              const SizedBox(height: 12),
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
              ListenableBuilder(
                listenable: Listenable.merge([_name, _unitPrice]),
                builder: (context, _) {
                  final canSave =
                      _name.text.trim().isNotEmpty && _unitPriceValue != null;
                  return CheckboxListTile(
                    key: const Key('saveEstimateToUnitPriceMaster'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _saveToUnitPriceMaster && canSave,
                    onChanged: canSave
                        ? (value) => setState(
                            () => _saveToUnitPriceMaster = value ?? false,
                          )
                        : null,
                    title: const Text('この内容を単価マスタへ登録'),
                    subtitle: Text(
                      canSave ? '次回から単価マスタで検索・選択できます' : '名称と単価を入力すると登録できます',
                    ),
                  );
                },
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
              if (widget.isEditing)
                FilledButton(
                  key: const Key('saveEstimateChanges'),
                  onPressed: () =>
                      _complete(EstimateItemEditorAction.continueCalculating),
                  child: const Text('変更を保存'),
                )
              else ...[
                FilledButton(
                  key: const Key('addEstimateAndContinue'),
                  onPressed: () =>
                      _complete(EstimateItemEditorAction.continueCalculating),
                  child: Text(
                    widget.showOpenEstimateAction ? '追加して続ける' : '見積明細へ追加',
                  ),
                ),
                if (widget.showOpenEstimateAction) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('addEstimateAndOpen'),
                    onPressed: () =>
                        _complete(EstimateItemEditorAction.openEstimate),
                    child: const Text('追加して見積を開く'),
                  ),
                ],
              ],
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
