import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
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
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('歩掛・生産性計算'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SegmentedButton<_Mode>(
              segments: [
                ButtonSegment(
                  value: _Mode.labor,
                  label: Text(strings.text('必要人工')),
                ),
                ButtonSegment(
                  value: _Mode.days,
                  label: Text(strings.text('必要日数')),
                ),
                ButtonSegment(
                  value: _Mode.actual,
                  label: Text(strings.text('生産性・実績')),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _mode = value.first),
            ),
            const SizedBox(height: 16),
            _Section(
              title: strings.text('作業情報'),
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('productivityTrade'),
                  initialValue: _trade,
                  decoration: InputDecoration(labelText: strings.text('工種')),
                  items: _trades
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(strings.text(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _trade = value),
                ),
                _field(_task, strings.text('作業名称')),
                if (_mode == _Mode.actual) ...[
                  _field(_site, strings.text('現場名')),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.text('施工日')),
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
                      child: _field(
                        _quantity,
                        strings.text('施工数量'),
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: InputDecoration(
                          labelText: strings.text('単位'),
                        ),
                        items: _units
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(strings.productivityUnit(value)),
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
                  strings.text(
                    _mode == _Mode.actual ? '基準歩掛（任意・人工/単位）' : '基準歩掛（人工/単位）',
                  ),
                  numeric: true,
                ),
                _field(
                  _workers,
                  strings.text(_mode == _Mode.labor ? '作業人数（任意）' : '作業人数'),
                  numeric: true,
                ),
                if (_mode == _Mode.labor)
                  _field(_days, strings.text('作業日数（任意・小数可）'), numeric: true),
                if (_mode == _Mode.actual)
                  _field(_days, strings.text('作業日数（小数可）'), numeric: true),
                _field(
                  _hours,
                  strings.text(
                    _mode == _Mode.actual ? '実作業時間（任意）' : '1日の作業時間（任意）',
                  ),
                  numeric: true,
                ),
                if (_mode == _Mode.actual)
                  _field(_conditions, strings.text('施工条件・備考（任意）'), maxLines: 3),
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
    final strings = AppLocalizations.of(context);
    final result = _plan;
    return _Section(
      title: strings.text('計算結果'),
      children: result == null
          ? [Text(strings.text('施工数量と基準歩掛を入力してください'))]
          : [
              _resultRow(
                strings.text('必要人工'),
                '${_f(result.requiredLabor, 2)} ${_laborDayUnit(strings)}',
              ),
              if (result.requiredDays != null)
                _resultRow(
                  strings.text('必要日数'),
                  '${_f(result.requiredDays!, 2)} ${_dayUnit(strings)}',
                ),
              if (_mode == _Mode.days && result.totalWorkHours != null)
                _resultRow(
                  strings.text('延べ作業時間'),
                  '${_f(result.totalWorkHours!, 2)} ${_hourUnit(strings)}',
                ),
            ],
    );
  }

  Widget _actualResult() {
    final strings = AppLocalizations.of(context);
    final result = _actual;
    return _Section(
      title: strings.text('計算結果'),
      children: [
        if (result == null)
          Text(strings.text('施工数量・作業人数・作業日数を入力してください'))
        else ...[
          _resultRow(
            strings.text('実人工'),
            '${_f(result.actualLabor, 2)} ${_laborDayUnit(strings)}',
          ),
          _resultRow(
            strings.text('実績歩掛'),
            _laborRate(strings, result.actualLaborRate),
          ),
          _resultRow(
            strings.text('1人工生産性'),
            _productivity(strings, result.productivityPerLabor),
          ),
          if (result.laborRateDifference != null) ...[
            const Divider(),
            _resultRow(
              strings.text('基準歩掛'),
              _laborRate(strings, _number(_standard)!),
            ),
            _resultRow(
              strings.text('差'),
              _laborRate(
                strings,
                result.laborRateDifference!,
                showPositiveSign: true,
              ),
            ),
            _resultRow(
              strings.text('効率差'),
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
              label: Text(strings.text('実績として保存')),
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
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
    final strings = AppLocalizations.of(context);
    final result = _actual;
    if (result == null ||
        _trade == null ||
        _task.text.trim().isEmpty ||
        _site.text.trim().isEmpty ||
        _unit == null) {
      _message(strings.text('工種・作業名称・現場名・数量・単位・人数・日数を入力してください'));
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
      if (mounted) {
        _message(strings.text('歩掛・生産性マスタへ保存しました'));
      }
    } on ProductivityLimitException catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).text('保存上限に達しました')),
          content: Text(strings.productivityLimitMessage(error.limit)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).text('閉じる')),
            ),
          ],
        ),
      );
    } catch (_) {
      _message(strings.text('実績を保存できませんでした'));
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

  String _laborRate(
    AppLocalizations strings,
    double value, {
    bool showPositiveSign = false,
  }) {
    final sign = showPositiveSign && value >= 0 ? '+' : '';
    final unit = strings.productivityUnit(_unit ?? '単位');
    final suffix = strings.choose(
      japanese: '人工/$unit',
      english: 'labor-days/$unit',
      simplifiedChinese: '人工/$unit',
    );
    return '$sign${_f(value, 3)} $suffix';
  }

  String _productivity(AppLocalizations strings, double value) {
    final unit = strings.productivityUnit(_unit ?? '単位');
    final suffix = strings.choose(
      japanese: '$unit/人工',
      english: '$unit/labor-day',
      simplifiedChinese: '$unit/人工',
    );
    return '${_f(value, 2)} $suffix';
  }

  String _laborDayUnit(AppLocalizations strings) => strings.choose(
    japanese: '人工',
    english: 'labor-days',
    simplifiedChinese: '人工',
  );

  String _dayUnit(AppLocalizations strings) =>
      strings.choose(japanese: '日', english: 'days', simplifiedChinese: '天');

  String _hourUnit(AppLocalizations strings) =>
      strings.choose(japanese: '時間', english: 'hours', simplifiedChinese: '小时');
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
