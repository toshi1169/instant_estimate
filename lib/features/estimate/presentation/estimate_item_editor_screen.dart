import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/estimate_document.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';
import '../domain/estimate_item_symbol.dart';
import '../domain/unit_price_master.dart';
import 'estimate_text_guidance.dart';

enum EstimateItemEditorAction { continueCalculating, openEstimate }

class EstimateItemEditorResult {
  const EstimateItemEditorResult({
    required this.draft,
    required this.action,
    this.saveToUnitPriceMaster = false,
    this.estimateId,
  });

  final EstimateItemDraft draft;
  final EstimateItemEditorAction action;
  final bool saveToUnitPriceMaster;
  final String? estimateId;
}

class EstimateItemEditorScreen extends StatefulWidget {
  const EstimateItemEditorScreen({
    required this.initialDraft,
    this.settings = const AppSettings(),
    this.isEditing = false,
    this.showOpenEstimateAction = true,
    this.estimateTitle = '名称未設定の見積',
    this.estimates = const [],
    this.initialEstimateId,
    this.unitPriceMasters = const [],
    super.key,
  });

  final EstimateItemDraft initialDraft;
  final AppSettings settings;
  final bool isEditing;
  final bool showOpenEstimateAction;
  final String estimateTitle;
  final List<EstimateDocument> estimates;
  final String? initialEstimateId;
  final List<UnitPriceMaster> unitPriceMasters;

  @override
  State<EstimateItemEditorScreen> createState() =>
      _EstimateItemEditorScreenState();
}

class _EstimateItemEditorScreenState extends State<EstimateItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _constructionSymbol = widget.initialDraft.constructionSymbol;
  late final _trade = TextEditingController(text: widget.initialDraft.trade);
  late final _constructionLocation = TextEditingController(
    text: widget.initialDraft.constructionLocation,
  );
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
  late String? _selectedEstimateId;
  late String _selectedEstimateTitle;

  @override
  void initState() {
    super.initState();
    _selectedEstimateId = widget.initialEstimateId;
    _selectedEstimateTitle = widget.estimateTitle;
    if (_constructionLocation.text.trim().isEmpty) {
      _constructionLocation.text = _mappedLocation(_constructionSymbol) ?? '';
    }
  }

  @override
  void dispose() {
    _trade.dispose();
    _constructionLocation.dispose();
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

  EstimateDocument? get _selectedEstimate => widget.estimates
      .where((estimate) => estimate.info.id == _selectedEstimateId)
      .firstOrNull;

  String? _mappedLocation(String symbol, [EstimateDocument? estimate]) {
    final normalizedSymbol = symbol.trim();
    if (normalizedSymbol.isEmpty) return null;
    return (estimate ?? _selectedEstimate)?.items
        .where(
          (item) =>
              item.constructionSymbol.trim() == normalizedSymbol &&
              item.constructionLocation.trim().isNotEmpty,
        )
        .map((item) => item.constructionLocation.trim())
        .firstOrNull;
  }

  void _selectConstructionSymbol(String? value) {
    final symbol = value?.trim() ?? '';
    setState(() {
      _constructionSymbol = symbol;
      _constructionLocation.text = _mappedLocation(symbol) ?? '';
    });
  }

  List<_PastUnitPriceCandidate> get _pastUnitPrices {
    final candidates = [
      for (final estimate in widget.estimates)
        for (final item in estimate.items)
          if (item.unitPrice != null && item.name.trim().isNotEmpty)
            _PastUnitPriceCandidate(estimate: estimate, item: item),
    ];
    candidates.sort(
      (left, right) => right.item.createdAt.compareTo(left.item.createdAt),
    );
    return candidates;
  }

  double? get _amount {
    final quantity = _quantityValue;
    final unitPrice = _unitPriceValue;
    if (quantity == null || unitPrice == null) return null;
    return quantity * unitPrice;
  }

  String? _validateNumber(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return null;
    return _parseNumber(value) == null ? l10n.text('数値を入力してください') : null;
  }

  void _complete(EstimateItemEditorAction action) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawQuantity = _quantityValue;
    final formalQuantity = rawQuantity == null
        ? null
        : widget.settings.roundEstimateQuantity(rawQuantity);
    final quantityWasChanged = rawQuantity != widget.initialDraft.quantity;
    final shouldKeepOriginalQuantity =
        widget.initialDraft.originalQuantity != null && !quantityWasChanged;
    final originalQuantity = shouldKeepOriginalQuantity
        ? widget.initialDraft.originalQuantity
        : rawQuantity != formalQuantity
        ? rawQuantity
        : null;
    Navigator.of(context).pop(
      EstimateItemEditorResult(
        action: action,
        estimateId: _selectedEstimateId,
        saveToUnitPriceMaster:
            _saveToUnitPriceMaster &&
            _name.text.trim().isNotEmpty &&
            _unitPriceValue != null,
        draft: widget.initialDraft.copyWith(
          constructionSymbol: _constructionSymbol,
          trade: _trade.text.trim(),
          constructionLocation: _constructionLocation.text.trim(),
          name: _name.text.trim(),
          specification: _specification.text.trim(),
          quantity: formalQuantity,
          clearQuantity: _quantity.text.trim().isEmpty,
          unit: _unit.text.trim(),
          unitPrice: _unitPriceValue,
          clearUnitPrice: _unitPrice.text.trim().isEmpty,
          description: _description.text.trim(),
          originalQuantity: originalQuantity,
          clearOriginalQuantity: originalQuantity == null,
        ),
      ),
    );
  }

  Future<void> _selectEstimate() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<EstimateDocument>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    l10n.text('追加先の見積を選択'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(l10n.itemCount(widget.estimates.length)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                key: const Key('estimateDestinationList'),
                shrinkWrap: true,
                itemCount: widget.estimates.length,
                itemBuilder: (context, index) {
                  final estimate = widget.estimates[index];
                  final selected = estimate.info.id == _selectedEstimateId;
                  return ListTile(
                    key: Key('estimateDestination${estimate.info.id}'),
                    leading: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.description_outlined,
                    ),
                    title: Text(l10n.text(estimate.info.displayName)),
                    subtitle: Text(
                      estimate.info.siteName.isEmpty
                          ? l10n.estimateDetails(estimate.items.length)
                          : estimate.info.siteName,
                    ),
                    onTap: () => Navigator.of(context).pop(estimate),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedEstimateId = selected.info.id;
      _selectedEstimateTitle = selected.info.displayName;
      _constructionLocation.text =
          _mappedLocation(_constructionSymbol, selected) ?? '';
    });
  }

  Future<void> _selectUnitPriceMaster() async {
    final l10n = AppLocalizations.of(context);
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
                        l10n.text('単価マスタから選択'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${filtered.length} / ${l10n.itemCount(widget.unitPriceMasters.length)}',
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
                    decoration: InputDecoration(
                      hintText: l10n.text('単価を検索'),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(l10n.text('一致する単価がありません')))
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
                                  if (price.trade.isNotEmpty)
                                    l10n.text(price.trade),
                                  if (price.specification.isNotEmpty)
                                    price.specification,
                                  if (price.unit.isNotEmpty)
                                    l10n.productivityUnit(price.unit),
                                ].join(l10n.listSeparator),
                              ),
                              trailing: Text(
                                price.unitPrice == null
                                    ? l10n.text('未入力')
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

  Future<void> _selectPastUnitPrice() async {
    final l10n = AppLocalizations.of(context);
    final allCandidates = _pastUnitPrices;
    var filtered = allCandidates;
    final selected = await showModalBottomSheet<_PastUnitPriceCandidate>(
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
                        l10n.text('過去の見積から選択'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${filtered.length} / ${l10n.itemCount(allCandidates.length)}',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    key: const Key('selectPastUnitPriceSearch'),
                    autofocus: allCandidates.length > 8,
                    onChanged: (query) {
                      setModalState(() {
                        filtered = allCandidates
                            .where((candidate) => candidate.matches(query))
                            .toList(growable: false);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: l10n.text('過去の名称・工種・現場などを検索'),
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Text(l10n.text('一致する過去明細がありません')))
                      : ListView.separated(
                          key: const Key('selectPastUnitPriceList'),
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final candidate = filtered[index];
                            final item = candidate.item;
                            return ListTile(
                              key: Key(
                                'selectPastUnitPrice-${candidate.estimate.info.id}-${item.id}',
                              ),
                              title: Text(item.name),
                              subtitle: Text(candidate.subtitle(l10n)),
                              trailing: Text(
                                '¥ ${_displayAmount(item.unitPrice!)}',
                              ),
                              onTap: () => Navigator.of(context).pop(candidate),
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
    final item = selected.item;
    setState(() {
      _constructionSymbol = item.constructionSymbol;
      _trade.text = item.trade;
      _constructionLocation.text = item.constructionLocation;
      _name.text = item.name;
      _specification.text = item.specification;
      _unit.text = item.unit;
      _unitPrice.text = _editableNumber(item.unitPrice);
      _description.text = item.description;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text(widget.isEditing ? '見積明細を編集' : '見積明細へ追加')),
      ),
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
                  title: Text(l10n.text('追加先')),
                  subtitle: Text(
                    l10n.text(_selectedEstimateTitle),
                    key: const Key('selectedEstimateDestination'),
                  ),
                  trailing: TextButton(
                    key: const Key('changeEstimateDestination'),
                    onPressed: !widget.isEditing && widget.estimates.length > 1
                        ? _selectEstimate
                        : null,
                    child: Text(l10n.text('変更')),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 88,
                    child: DropdownButtonFormField<String>(
                      key: const Key('estimateConstructionSymbolField'),
                      initialValue: _constructionSymbol,
                      decoration: InputDecoration(
                        labelText: l10n.choose(
                          japanese: '記号',
                          english: 'Symbol',
                          simplifiedChinese: '符号',
                          traditionalChinese: '符號',
                          vietnamese: 'Ký hiệu',
                          indonesian: 'Simbol',
                          filipino: 'Simbolo',
                          myanmar: 'သင်္ကေတ',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('—')),
                        for (final symbol in {
                          ...estimateItemSymbols,
                          if (_constructionSymbol.isNotEmpty)
                            _constructionSymbol,
                        })
                          DropdownMenuItem(value: symbol, child: Text(symbol)),
                      ],
                      onChanged: _selectConstructionSymbol,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _constructionLocation,
                      l10n.choose(
                        japanese: '施工場所',
                        english: 'Work location',
                        simplifiedChinese: '施工地点',
                        traditionalChinese: '施工地點',
                        vietnamese: 'Vị trí thi công',
                        indonesian: 'Lokasi pekerjaan',
                        filipino: 'Lokasyon ng trabaho',
                        myanmar: 'ဆောက်လုပ်ရေးနေရာ',
                      ),
                      key: const Key('estimateConstructionLocationField'),
                      maxLines: null,
                      padding: EdgeInsets.zero,
                      guidanceKey: const Key(
                        'estimateConstructionLocationGuidance',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                _name,
                l10n.text('名称'),
                key: const Key('estimateNameField'),
                maxLines: null,
                guidanceKey: const Key('estimateNameGuidance'),
              ),
              _field(
                _specification,
                l10n.text('仕様'),
                key: const Key('estimateSpecificationField'),
                maxLines: null,
                guidanceKey: const Key('estimateSpecificationGuidance'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _numberField(
                      _quantity,
                      l10n.text('数量'),
                      key: const Key('estimateQuantityField'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _unit,
                      l10n.text('単位'),
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
                      ? l10n.text('単価マスタ（登録なし）')
                      : l10n.selectUnitPriceMasterCount(
                          widget.unitPriceMasters.length,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('selectPastUnitPrice'),
                onPressed: _pastUnitPrices.isEmpty
                    ? null
                    : _selectPastUnitPrice,
                icon: const Icon(Icons.history),
                label: Text(
                  _pastUnitPrices.isEmpty
                      ? l10n.text('過去の見積（履歴なし）')
                      : l10n.selectPastEstimateCount(_pastUnitPrices.length),
                ),
              ),
              const SizedBox(height: 12),
              _numberField(
                _unitPrice,
                l10n.text('単価'),
                key: const Key('estimateUnitPriceField'),
                prefixText: '¥ ',
              ),
              ListenableBuilder(
                listenable: Listenable.merge([_quantity, _unitPrice]),
                builder: (context, _) => InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.text('金額（数量 × 単価）'),
                    border: const OutlineInputBorder(),
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
                    title: Text(l10n.text('この内容を単価マスタへ登録')),
                    subtitle: Text(
                      l10n.text(
                        canSave ? '次回から単価マスタで検索・選択できます' : '名称と単価を入力すると登録できます',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _field(
                _description,
                l10n.text('摘要'),
                key: const Key('estimateDescriptionField'),
                maxLines: null,
                guidanceKey: const Key('estimateDescriptionGuidance'),
              ),
              _field(
                _trade,
                l10n.text('工種'),
                key: const Key('estimateTradeField'),
              ),
              if (widget.initialDraft.calculationBasis.isNotEmpty)
                ExpansionTile(
                  key: const Key('calculationBasisTile'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.text('計算根拠')),
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
                  child: Text(l10n.text('変更を保存')),
                )
              else ...[
                FilledButton(
                  key: const Key('addEstimateAndContinue'),
                  onPressed: () =>
                      _complete(EstimateItemEditorAction.continueCalculating),
                  child: Text(
                    l10n.text(
                      widget.showOpenEstimateAction ? '追加して続ける' : '見積明細へ追加',
                    ),
                  ),
                ),
                if (widget.showOpenEstimateAction) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('addEstimateAndOpen'),
                    onPressed: () =>
                        _complete(EstimateItemEditorAction.openEstimate),
                    child: Text(l10n.text('追加して見積を開く')),
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
    int? maxLines = 1,
    EdgeInsetsGeometry padding = const EdgeInsets.only(bottom: 12),
    Key? guidanceKey,
  }) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: key,
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          if (guidanceKey != null)
            EstimateTextGuidance(
              controller: controller,
              counterKey: guidanceKey,
            ),
        ],
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
        validator: (value) =>
            _validateNumber(value, AppLocalizations.of(context)),
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _PastUnitPriceCandidate {
  const _PastUnitPriceCandidate({required this.estimate, required this.item});

  final EstimateDocument estimate;
  final EstimateItem item;

  String subtitle(AppLocalizations l10n) {
    final date = item.createdAt;
    final parts = [
      l10n.text(estimate.info.displayName),
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
      if (item.trade.isNotEmpty) l10n.text(item.trade),
      if (item.specification.isNotEmpty) item.specification,
      if (item.unit.isNotEmpty) l10n.productivityUnit(item.unit),
    ];
    return parts.join(l10n.listSeparator);
  }

  bool matches(String query) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    if (terms.isEmpty) return true;
    final searchable = [
      estimate.info.displayName,
      estimate.info.siteName,
      item.trade,
      item.name,
      item.specification,
      item.unit,
      item.description,
      item.unitPrice.toString(),
    ].join(' ').toLowerCase();
    return terms.every(searchable.contains);
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
