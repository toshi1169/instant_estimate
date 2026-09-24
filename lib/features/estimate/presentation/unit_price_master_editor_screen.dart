import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/unit_price_master.dart';
import 'estimate_pdf_script_notice.dart';
import 'estimate_text_guidance.dart';

class UnitPriceMasterEditorScreen extends StatefulWidget {
  const UnitPriceMasterEditorScreen({
    this.initialDraft = const UnitPriceMasterDraft(),
    this.isEditing = false,
    super.key,
  });

  final UnitPriceMasterDraft initialDraft;
  final bool isEditing;

  @override
  State<UnitPriceMasterEditorScreen> createState() =>
      _UnitPriceMasterEditorScreenState();
}

class _UnitPriceMasterEditorScreenState
    extends State<UnitPriceMasterEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _trade = TextEditingController(text: widget.initialDraft.trade);
  late final _name = TextEditingController(text: widget.initialDraft.name);
  late final _specification = TextEditingController(
    text: widget.initialDraft.specification,
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
    _unit.dispose();
    _unitPrice.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      UnitPriceMasterDraft(
        trade: _trade.text.trim(),
        name: _name.text.trim(),
        specification: _specification.text.trim(),
        unit: _unit.text.trim(),
        unitPrice: _parseNumber(_unitPrice.text),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text(widget.isEditing ? '単価を編集' : '単価を登録')),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (l10n.formalPdfScriptSupportNotice != null) ...[
                const EstimatePdfScriptNotice(
                  key: Key('unitPricePdfScriptNotice'),
                ),
                const SizedBox(height: 12),
              ],
              _field(_trade, l10n.text('工種'), const Key('unitPriceTradeField')),
              _field(
                _name,
                l10n.text('名称（必須）'),
                const Key('unitPriceNameField'),
                maxLines: null,
                guidanceKey: const Key('unitPriceNameGuidance'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.text('名称を入力してください')
                    : null,
              ),
              _field(
                _specification,
                l10n.text('仕様'),
                const Key('unitPriceSpecificationField'),
                maxLines: null,
                guidanceKey: const Key('unitPriceSpecificationGuidance'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      _unit,
                      l10n.text('単位'),
                      const Key('unitPriceUnitField'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _field(
                      _unitPrice,
                      l10n.text('単価'),
                      const Key('unitPriceValueField'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,+\-eE]'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        return _parseNumber(value) == null
                            ? l10n.text('数値を入力してください')
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              _field(
                _description,
                l10n.text('摘要'),
                const Key('unitPriceDescriptionField'),
                maxLines: null,
                guidanceKey: const Key('unitPriceDescriptionGuidance'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('saveUnitPriceMaster'),
                onPressed: _save,
                child: Text(l10n.text(widget.isEditing ? '変更を保存' : '単価マスタへ登録')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    Key key, {
    int? maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Key? guidanceKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: key,
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
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
