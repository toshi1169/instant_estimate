import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/estimate_info.dart';

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
  late final _siteName = TextEditingController(
    text: widget.initialInfo.siteName,
  );
  late final _clientName = TextEditingController(
    text: widget.initialInfo.clientName,
  );
  late final _estimateNumber = TextEditingController(
    text: widget.initialInfo.estimateNumber,
  );
  late final _notes = TextEditingController(text: widget.initialInfo.notes);
  late DateTime _createdDate = widget.initialInfo.createdDate;

  @override
  void dispose() {
    _estimateName.dispose();
    _siteName.dispose();
    _clientName.dispose();
    _estimateNumber.dispose();
    _notes.dispose();
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
        siteName: _siteName.text.trim(),
        clientName: _clientName.text.trim(),
        createdDate: _createdDate,
        estimateNumber: _estimateNumber.text.trim(),
        notes: _notes.text.trim(),
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
            _field(
              _estimateName,
              strings.text('見積名'),
              hint: strings.text('例：○○邸 外構工事'),
              key: const Key('estimateInfoNameField'),
            ),
            _field(
              _siteName,
              strings.text('現場名'),
              key: const Key('estimateInfoSiteField'),
            ),
            _field(
              _clientName,
              strings.text('宛名'),
              key: const Key('estimateInfoClientField'),
            ),
            _field(
              _estimateNumber,
              strings.text('見積番号'),
              key: const Key('estimateInfoNumberField'),
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
              _notes,
              strings.text('備考'),
              key: const Key('estimateInfoNotesField'),
              maxLines: 4,
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
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: key,
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}

String _date(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
