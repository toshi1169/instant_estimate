import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/unit_converter.dart';

class UnitConversionScreen extends StatefulWidget {
  const UnitConversionScreen({this.settings = const AppSettings(), super.key});

  final AppSettings settings;

  @override
  State<UnitConversionScreen> createState() => _UnitConversionScreenState();
}

class _UnitConversionScreenState extends State<UnitConversionScreen> {
  static const _converter = UnitConverter();
  final _valueController = TextEditingController();
  final _loosenFactorController = TextEditingController(text: '1.25');
  final _compactionFactorController = TextEditingController(text: '0.90');

  UnitConversionCategory _category = UnitConversionCategory.length;
  late String _fromUnitId;
  late String _toUnitId;
  double? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    final units = _converter.unitsFor(_category);
    _fromUnitId = units.first.id;
    _toUnitId = units[1].id;
    _valueController.addListener(_recalculate);
    _loosenFactorController.addListener(_recalculate);
    _compactionFactorController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _valueController
      ..removeListener(_recalculate)
      ..dispose();
    _loosenFactorController
      ..removeListener(_recalculate)
      ..dispose();
    _compactionFactorController
      ..removeListener(_recalculate)
      ..dispose();
    super.dispose();
  }

  double? _parse(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', ''));
  }

  void _recalculate() {
    final value = _parse(_valueController);
    double? result;
    String? error;
    if (_valueController.text.trim().isNotEmpty) {
      if (value == null) {
        error = '有効な数値を入力してください';
      } else {
        try {
          result = _converter.convert(
            category: _category,
            value: value,
            fromUnitId: _fromUnitId,
            toUnitId: _toUnitId,
            loosenFactor: _parse(_loosenFactorController) ?? double.nan,
            compactionFactor: _parse(_compactionFactorController) ?? double.nan,
          );
        } on FormatException catch (exception) {
          error = exception.message.toString();
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _error = error;
    });
  }

  void _changeCategory(UnitConversionCategory? category) {
    if (category == null || category == _category) return;
    final units = _converter.unitsFor(category);
    setState(() {
      _category = category;
      _fromUnitId = units.first.id;
      _toUnitId = units[1].id;
      _result = null;
      _error = null;
    });
    _recalculate();
  }

  void _swapUnits() {
    setState(() {
      final previousFrom = _fromUnitId;
      _fromUnitId = _toUnitId;
      _toUnitId = previousFrom;
    });
    _recalculate();
  }

  void _clear() {
    _valueController.clear();
    if (_category == UnitConversionCategory.earthwork) {
      _loosenFactorController.text = '1.25';
      _compactionFactorController.text = '0.90';
    }
  }

  String _format(double value) {
    final rounded = widget.settings.roundCalculationValue(value);
    if (rounded != 0 && rounded.abs() >= 1e16) {
      return rounded.toStringAsExponential(widget.settings.decimalPlaces);
    }
    return rounded.toStringAsFixed(widget.settings.decimalPlaces);
  }

  String _resultText(double result) {
    final unit = _converter
        .unitsFor(_category)
        .firstWhere((unit) => unit.id == _toUnitId);
    if (_category == UnitConversionCategory.gradient && unit.id == 'ratio') {
      return '1 : ${_format(result)}';
    }
    final suffix = _category == UnitConversionCategory.earthwork
        ? '${unit.label} ㎥'
        : unit.label;
    return '${_format(result)} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final units = _converter.unitsFor(_category);
    return Scaffold(
      key: const Key('unitConversionScreen'),
      appBar: AppBar(
        title: Text(strings.unitConversion),
        actions: [
          TextButton(onPressed: _clear, child: Text(strings.text('クリア'))),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<UnitConversionCategory>(
                  key: const Key('unitConversionCategory'),
                  initialValue: _category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: strings.text('変換する種類'),
                    prefixIcon: const Icon(Icons.swap_horiz),
                  ),
                  items: [
                    for (final category in UnitConversionCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(
                          strings.text(category.label),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _changeCategory,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      key: const Key('unitConversionValue'),
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                      ],
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      decoration: InputDecoration(
                        labelText: strings.text('変換する値'),
                        hintText: strings.text('数値を入力'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _unitDropdown(
                            key: const Key('unitConversionFrom'),
                            label: strings.text('変換前'),
                            value: _fromUnitId,
                            units: units,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _fromUnitId = value);
                              _recalculate();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: IconButton.filledTonal(
                            key: const Key('swapConversionUnits'),
                            tooltip: strings.text('単位を入れ替える'),
                            onPressed: _swapUnits,
                            icon: const Icon(Icons.swap_horiz),
                          ),
                        ),
                        Expanded(
                          child: _unitDropdown(
                            key: const Key('unitConversionTo'),
                            label: strings.text('変換後'),
                            value: _toUnitId,
                            units: units,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _toUnitId = value);
                              _recalculate();
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_category == UnitConversionCategory.earthwork) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _factorField(
                              key: const Key('loosenFactor'),
                              label: strings.text('ほぐし係数'),
                              controller: _loosenFactorController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _factorField(
                              key: const Key('compactionFactor'),
                              label: strings.text('締固め係数'),
                              controller: _compactionFactorController,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _resultCard(),
            const SizedBox(height: 14),
            _noteCard(),
          ],
        ),
      ),
    );
  }

  Widget _unitDropdown({
    required Key key,
    required String label,
    required String value,
    required List<UnitConversionUnit> units,
    required ValueChanged<String?> onChanged,
  }) {
    final strings = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final unit in units)
          DropdownMenuItem(
            value: unit.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.specializedUnit(unit.id, unit.label),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (strings.isSpecializedUnit(unit.id)) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    key: Key('unitInfo-${unit.id}'),
                    tooltip: strings.showUnitInformation,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                    onPressed: () => _showUnitInformation(unit),
                  ),
                ],
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _showUnitInformation(UnitConversionUnit unit) async {
    final strings = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.specializedUnit(unit.id, unit.label)),
        content: Text(strings.specializedUnitExplanation(unit.id)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.text('閉じる')),
          ),
        ],
      ),
    );
  }

  Widget _factorField({
    required Key key,
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _resultCard() {
    final theme = Theme.of(context);
    if (_error != null) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            _error!,
            key: const Key('unitConversionError'),
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        ),
      );
    }
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).text('変換結果'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              _result == null ? '—' : _resultText(_result!),
              key: const Key('unitConversionResult'),
              textAlign: TextAlign.end,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteCard() {
    final strings = AppLocalizations.of(context);
    final japaneseText = switch (_category) {
      UnitConversionCategory.length => '尺・寸・間は、1尺＝10/33mを基準に変換します。',
      UnitConversionCategory.area => '坪は、1坪＝400/121㎡（約3.30579㎡）を基準に変換します。',
      UnitConversionCategory.weight =>
        '俵は品目によって重量が異なります。この画面では参考値として米1俵＝60kgで変換します。',
      UnitConversionCategory.gradient => '1:nは、垂直1に対する水平距離nとして変換します。',
      UnitConversionCategory.earthwork =>
        '地山を基準に、ほぐし土量＝地山土量×ほぐし係数、締固め土量＝地山土量×締固め係数で変換します。係数は土質・施工条件に合わせて変更してください。',
      _ => '変換結果は設定画面の小数点以下桁数と丸め方法を反映します。',
    };
    final text = strings.text(japaneseText);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
