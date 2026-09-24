import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/estimate_info.dart';
import 'estimate_pdf_script_notice.dart';
import 'estimate_text_guidance.dart';

class EstimateInfoEditorScreen extends StatefulWidget {
  const EstimateInfoEditorScreen({required this.initialInfo, super.key});

  final EstimateInfo initialInfo;

  @override
  State<EstimateInfoEditorScreen> createState() =>
      _EstimateInfoEditorScreenState();
}

class _EstimateInfoEditorScreenState extends State<EstimateInfoEditorScreen> {
  late final _estimateName = TextEditingController(
    text: widget.initialInfo.estimateName == '名称未設定の見積'
        ? ''
        : widget.initialInfo.estimateName,
  );
  late final _notes = TextEditingController(text: widget.initialInfo.notes);
  late final _proviso = TextEditingController(text: widget.initialInfo.proviso);
  late final _validityPeriod = TextEditingController(
    text: widget.initialInfo.validityPeriod,
  );
  late final _constructionPeriod = TextEditingController(
    text: widget.initialInfo.constructionPeriod,
  );
  late final _paymentTerms = TextEditingController(
    text: widget.initialInfo.paymentTerms,
  );
  late DateTime _createdDate = widget.initialInfo.createdDate;

  @override
  void dispose() {
    _estimateName.dispose();
    _notes.dispose();
    _proviso.dispose();
    _validityPeriod.dispose();
    _constructionPeriod.dispose();
    _paymentTerms.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _createdDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _createdDate = selected);
  }

  void _save() {
    Navigator.of(context).pop(
      widget.initialInfo.copyWith(
        estimateName: _estimateName.text.trim().isEmpty
            ? '名称未設定の見積'
            : _estimateName.text.trim(),
        createdDate: _createdDate,
        notes: _notes.text.trim(),
        proviso: _proviso.text.trim(),
        validityPeriod: _validityPeriod.text.trim(),
        constructionPeriod: _constructionPeriod.text.trim(),
        paymentTerms: _paymentTerms.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('見積基本情報'))),
      body: SafeArea(
        child: ListView(
          key: const Key('estimateInfoEditor'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (strings.formalPdfScriptSupportNotice != null) ...[
              const EstimatePdfScriptNotice(
                key: Key('estimateInfoPdfScriptNotice'),
              ),
              const SizedBox(height: 12),
            ],
            _field(
              _estimateName,
              strings.choose(
                japanese: '見積名・現場名',
                english: 'Estimate / site name',
                simplifiedChinese: '估算名称・现场名称',
                traditionalChinese: '估算名稱・現場名稱',
                vietnamese: 'Tên báo giá / công trường',
                indonesian: 'Nama penawaran / proyek',
                filipino: 'Pangalan ng pagtataya / proyekto',
                myanmar: 'ခန့်မှန်းချက် / လုပ်ငန်းခွင်အမည်',
              ),
              hint: strings.text('例：○○邸 外構工事'),
              key: const Key('estimateInfoNameField'),
              maxLines: 2,
              guidanceKey: const Key('estimateInfoNameGuidance'),
            ),
            ListTile(
              key: const Key('estimateInfoDateField'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              title: Text(strings.text('作成日')),
              subtitle: Text(_date(_createdDate)),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            _field(
              _proviso,
              strings.choose(
                japanese: '但し書き',
                english: 'Proviso',
                simplifiedChinese: '附加说明',
                traditionalChinese: '附加說明',
                vietnamese: 'Điều khoản ghi chú',
                indonesian: 'Catatan ketentuan',
                filipino: 'Tanging kondisyon',
                myanmar: 'ခြွင်းချက်မှတ်ချက်',
              ),
              key: const Key('estimateInfoProvisoField'),
              maxLines: 3,
              guidanceKey: const Key('estimateInfoProvisoGuidance'),
            ),
            _field(
              _validityPeriod,
              strings.choose(
                japanese: '見積有効期限',
                english: 'Estimate validity',
                simplifiedChinese: '报价有效期',
                traditionalChinese: '報價有效期限',
                vietnamese: 'Thời hạn hiệu lực báo giá',
                indonesian: 'Masa berlaku penawaran',
                filipino: 'Bisa ng pagtataya',
                myanmar: 'ခန့်မှန်းချက်သက်တမ်း',
              ),
              key: const Key('estimateInfoValidityPeriodField'),
              guidanceKey: const Key('estimateInfoValidityPeriodGuidance'),
              japaneseCharacterLimit: 20,
              japaneseLineLimit: 1,
            ),
            _field(
              _constructionPeriod,
              strings.choose(
                japanese: '工期',
                english: 'Construction period',
                simplifiedChinese: '工期',
                traditionalChinese: '工期',
                vietnamese: 'Thời gian thi công',
                indonesian: 'Masa pelaksanaan',
                filipino: 'Panahon ng paggawa',
                myanmar: 'ဆောက်လုပ်ရေးကာလ',
              ),
              key: const Key('estimateInfoConstructionPeriodField'),
              guidanceKey: const Key('estimateInfoConstructionPeriodGuidance'),
              japaneseCharacterLimit: 20,
              japaneseLineLimit: 1,
            ),
            _field(
              _paymentTerms,
              strings.choose(
                japanese: '支払条件',
                english: 'Payment terms',
                simplifiedChinese: '付款条件',
                traditionalChinese: '付款條件',
                vietnamese: 'Điều khoản thanh toán',
                indonesian: 'Ketentuan pembayaran',
                filipino: 'Mga tuntunin sa pagbabayad',
                myanmar: 'ငွေပေးချေမှုစည်းကမ်းချက်များ',
              ),
              key: const Key('estimateInfoPaymentTermsField'),
              guidanceKey: const Key('estimateInfoPaymentTermsGuidance'),
              japaneseCharacterLimit: 20,
              japaneseLineLimit: 1,
            ),
            _field(
              _notes,
              strings.text('備考'),
              key: const Key('estimateInfoNotesField'),
              maxLines: 4,
              guidanceKey: const Key('estimateInfoNotesGuidance'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('saveEstimateInfo'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(strings.text('基本情報を保存')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required Key key,
    String? hint,
    int maxLines = 1,
    Key? guidanceKey,
    int? japaneseCharacterLimit,
    int? japaneseLineLimit,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: key,
          controller: controller,
          maxLines: maxLines,
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
        if (guidanceKey != null)
          EstimateTextGuidance(
            controller: controller,
            counterKey: guidanceKey,
            japaneseCharacterLimit: japaneseCharacterLimit,
            japaneseLineLimit: japaneseLineLimit,
          ),
      ],
    ),
  );
}

String _date(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
