import 'package:flutter/material.dart';

import '../application/productivity_controller.dart';
import '../domain/productivity_calculator.dart';
import '../domain/productivity_record.dart';

enum _Mode { labor, days, actual }

class ProductivityCalculationScreen extends StatefulWidget {
  const ProductivityCalculationScreen({required this.controller, super.key});
  final ProductivityController controller;

  @override
  State<ProductivityCalculationScreen> createState() =>
      _ProductivityCalculationScreenState();
}

class _ProductivityCalculationScreenState
    extends State<ProductivityCalculationScreen> {
  static const _trades = [
    '土工事',
    '地業工事',
    '鉄筋工事',
    'コンクリート工事',
    '型枠工事',
    '舗装工事',
    '外構工事',
    '内装工事',
    'その他',
  ];
  static const _units = [
    'm',
    'm²',
    'm³',
    'kg',
    't',
    '本',
    '枚',
    '個',
    '箇所',
    '組',
    '式',
  ];
  final _task = TextEditingController();
  final _site = TextEditingController();
  final _quantity = TextEditingController();
  final _standard = TextEditingController();
  final _workers = TextEditingController();
  final _days = TextEditingController();
  final _hours = TextEditingController();
  final _conditions = TextEditingController();
  _Mode _mode = _Mode.labor;
  String? _trade;
  String? _unit;
  DateTime _workDate = DateTime.now();

  @override
  void dispose() {
    for (final controller in [
      _task,
      _site,
      _quantity,
      _standard,
      _workers,
      _days,
      _hours,
      _conditions,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim());
  LaborPlanResult? get _plan {
    final quantity = _number(_quantity), standard = _number(_standard);
    if (quantity == null || quantity <= 0 || standard == null || standard < 0) {
      return null;
    }
    return ProductivityCalculator.plan(
      quantity: quantity,
      standardLaborRate: standard,
      workers: _number(_workers),
      hoursPerDay: _number(_hours),
    );
  }

  ProductivityResult? get _actual {
    final quantity = _number(_quantity),
        workers = _number(_workers),
        days = _number(_days);
    if (quantity == null ||
        quantity <= 0 ||
        workers == null ||
        workers <= 0 ||
        days == null ||
        days <= 0) {
      return null;
    }
    return ProductivityCalculator.actual(
      quantity: quantity,
      workers: workers,
      workDays: days,
      standardLaborRate: _number(_standard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歩掛・生産性計算')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.labor, label: Text('必要人工')),
                ButtonSegment(value: _Mode.days, label: Text('必要日数')),
                ButtonSegment(value: _Mode.actual, label: Text('生産性・実績')),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _mode = value.first),
            ),
            const SizedBox(height: 16),
            _Section(
              title: '作業情報',
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('productivityTrade'),
                  initialValue: _trade,
                  decoration: const InputDecoration(labelText: '工種'),
                  items: _trades
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _trade = value),
                ),
                _field(_task, '作業名称'),
                if (_mode == _Mode.actual) ...[
                  _field(_site, '現場名'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('施工日'),
                    subtitle: Text(_date(_workDate)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _pickDate,
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(_quantity, '施工数量', numeric: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: '単位'),
                        items: _units
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _unit = value),
                      ),
                    ),
                  ],
                ),
                _field(
                  _standard,
                  _mode == _Mode.actual ? '基準歩掛（任意・人工/単位）' : '基準歩掛（人工/単位）',
                  numeric: true,
                ),
                _field(
                  _workers,
                  _mode == _Mode.labor ? '作業人数（任意）' : '作業人数',
                  numeric: true,
                ),
                if (_mode == _Mode.labor)
                  _field(_days, '作業日数（任意・小数可）', numeric: true),
                if (_mode == _Mode.actual)
                  _field(_days, '作業日数（小数可）', numeric: true),
                _field(
                  _hours,
                  _mode == _Mode.actual ? '実作業時間（任意）' : '1日の作業時間（任意）',
                  numeric: true,
                ),
                if (_mode == _Mode.actual)
                  _field(_conditions, '施工条件・備考（任意）', maxLines: 3),
              ],
            ),
            const SizedBox(height: 14),
            if (_mode == _Mode.actual) _actualResult() else _planResult(),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => setState(() {}),
    ),
  );

  Widget _planResult() {
    final result = _plan;
    return _Section(
      title: '計算結果',
      children: result == null
          ? [const Text('施工数量と基準歩掛を入力してください')]
          : [
              _resultRow('必要人工', '${_f(result.requiredLabor, 2)} 人工'),
              if (result.requiredDays != null)
                _resultRow('必要日数', '${_f(result.requiredDays!, 2)} 日'),
              if (_mode == _Mode.days && result.totalWorkHours != null)
                _resultRow('延べ作業時間', '${_f(result.totalWorkHours!, 2)} 時間'),
            ],
    );
  }

  Widget _actualResult() {
    final result = _actual;
    return _Section(
      title: '計算結果',
      children: [
        if (result == null)
          const Text('施工数量・作業人数・作業日数を入力してください')
        else ...[
          _resultRow('実人工', '${_f(result.actualLabor, 2)} 人工'),
          _resultRow(
            '実績歩掛',
            '${_f(result.actualLaborRate, 3)} 人工/${_unit ?? '単位'}',
          ),
          _resultRow(
            '1人工生産性',
            '${_f(result.productivityPerLabor, 2)} ${_unit ?? '単位'}/人工',
          ),
          if (result.laborRateDifference != null) ...[
            const Divider(),
            _resultRow(
              '基準歩掛',
              '${_f(_number(_standard)!, 3)} 人工/${_unit ?? '単位'}',
            ),
            _resultRow(
              '差',
              '${result.laborRateDifference! >= 0 ? '+' : ''}${_f(result.laborRateDifference!, 3)} 人工/${_unit ?? '単位'}',
            ),
            _resultRow(
              '効率差',
              '${result.efficiencyDifferencePercent! >= 0 ? '+' : ''}${_f(result.efficiencyDifferencePercent!, 1)} %',
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('saveProductivityRecord'),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('実績として保存'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _workDate,
    );
    if (selected != null) setState(() => _workDate = selected);
  }

  Future<void> _save() async {
    final result = _actual;
    if (result == null ||
        _trade == null ||
        _task.text.trim().isEmpty ||
        _site.text.trim().isEmpty ||
        _unit == null) {
      _message('工種・作業名称・現場名・数量・単位・人数・日数を入力してください');
      return;
    }
    final now = DateTime.now();
    final record = ProductivityRecord(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      trade: _trade!,
      taskName: _task.text.trim(),
      siteName: _site.text.trim(),
      workDate: _workDate,
      quantity: _number(_quantity)!,
      unit: _unit!,
      workers: _number(_workers)!,
      workDays: _number(_days)!,
      actualWorkHours: _number(_hours),
      actualLabor: result.actualLabor,
      standardLaborRate: _number(_standard),
      actualLaborRate: result.actualLaborRate,
      productivityPerLabor: result.productivityPerLabor,
      conditions: _conditions.text.trim(),
    );
    try {
      await widget.controller.add(record);
      if (mounted) _message('歩掛・生産性マスタへ保存しました');
    } on ProductivityLimitException catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('保存上限に達しました'),
          content: Text(
            '現在のプランでは最大${error.limit}件まで保存できます。アルティメット版では100件まで保存できます。',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (_) {
      _message('実績を保存できませんでした');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _date(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
  String _f(double value, int digits) => value.toStringAsFixed(digits);
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
}
