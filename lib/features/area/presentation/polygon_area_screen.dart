import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/polygon_area_calculator.dart';

class PolygonAreaScreen extends StatefulWidget {
  const PolygonAreaScreen({
    required this.onSendToEstimate,
    this.settings = const AppSettings(),
    super.key,
  });

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;
  final AppSettings settings;

  @override
  State<PolygonAreaScreen> createState() => _PolygonAreaScreenState();
}

class _PolygonAreaScreenState extends State<PolygonAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _outerControllers = List.generate(5, (_) => TextEditingController());
  final _diagonalControllers = List.generate(2, (_) => TextEditingController());
  PolygonAreaResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in [..._outerControllers, ..._diagonalControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSide() {
    if (_outerControllers.length >= 20) return;
    setState(() {
      _outerControllers.add(TextEditingController());
      _diagonalControllers.add(TextEditingController());
      _result = null;
      _errorMessage = null;
    });
  }

  void _removeSide() {
    if (_outerControllers.length <= 5) return;
    setState(() {
      _outerControllers.removeLast().dispose();
      _diagonalControllers.removeLast().dispose();
      _result = null;
      _errorMessage = null;
    });
  }

  void _clear() {
    for (final controller in [..._outerControllers, ..._diagonalControllers]) {
      controller.clear();
    }
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final result = PolygonAreaCalculator.calculate(
        outerSides: _values(_outerControllers),
        diagonals: _values(_diagonalControllers),
      );
      setState(() {
        _result = result;
        _errorMessage = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _errorMessage = error.message;
      });
    }
  }

  List<double> _values(List<TextEditingController> controllers) => [
    for (final controller in controllers)
      double.parse(controller.text.replaceAll(',', '.')),
  ];

  Future<void> _sendToEstimate() async {
    final result = _result;
    if (result == null) return;
    final strings = AppLocalizations.of(context);
    final outerSides = _values(_outerControllers);
    final diagonals = _values(_diagonalControllers);
    final outerLabel = strings.choose(
      japanese: '外周',
      english: 'Outer sides',
      simplifiedChinese: '外周边',
      traditionalChinese: '外周邊',
    );
    final specification =
        '$outerLabel ${outerSides.map((value) => '${_format(value)}m').join('・')} / '
        '${strings.text('対角線')} '
        '${diagonals.map((value) => '${_format(value)}m').join('・')}';
    final triangle = strings.choose(
      japanese: '三角形',
      english: 'Triangle',
      simplifiedChinese: '三角形',
      traditionalChinese: '三角形',
    );
    final triangleText = result.triangleAreas.indexed
        .map((entry) => '$triangle${entry.$1 + 1} ${_format(entry.$2)}m²')
        .join(' ＋ ');
    await widget.onSendToEstimate(
      EstimateItemDraft(
        name: strings.text('面積'),
        specification: specification,
        quantity: widget.settings.roundEstimateQuantity(result.totalArea),
        unit: 'm²',
        calculationBasis:
            '$specification\n$triangleText ＝ ${_format(result.totalArea)}m²',
        originalQuantity: result.totalArea,
      ),
    );
  }

  String? _validateLength(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (number == null || !number.isFinite || number <= 0) {
      return AppLocalizations.of(context).text('0より大きい数値を入力');
    }
    return null;
  }

  String _format(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('5辺以上面積計算')),
        actions: [
          TextButton(onPressed: _clear, child: Text(strings.text('クリア'))),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(strings.text('頂点Aから対角線を引いて三角形に分割し、ヘロンの公式で面積を自動合算します。')),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  strings.choose(
                    japanese: '${_outerControllers.length}辺',
                    english: '${_outerControllers.length} sides',
                    simplifiedChinese: '${_outerControllers.length}条边',
                    traditionalChinese: '${_outerControllers.length}條邊',
                    vietnamese: '${_outerControllers.length} cạnh',
                    indonesian: '${_outerControllers.length} sisi',
                  ),
                  key: const Key('polygonSideCount'),
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  key: const Key('removePolygonSide'),
                  onPressed: _outerControllers.length > 5 ? _removeSide : null,
                  tooltip: strings.text('辺を減らす'),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  key: const Key('addPolygonSide'),
                  onPressed: _outerControllers.length < 20 ? _addSide : null,
                  tooltip: strings.text('辺を増やす'),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(strings.text('外周の辺'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (
                    var index = 0;
                    index < _outerControllers.length;
                    index++
                  ) ...[
                    _lengthField(
                      controller: _outerControllers[index],
                      fieldKey: Key('polygonOuterSide$index'),
                      label: strings.choose(
                        japanese:
                            '辺 ${_vertexName(index)}${_vertexName(index + 1)}',
                        english:
                            'Side ${_vertexName(index)}${_vertexName(index + 1)}',
                        simplifiedChinese:
                            '边 ${_vertexName(index)}${_vertexName(index + 1)}',
                        traditionalChinese:
                            '邊 ${_vertexName(index)}${_vertexName(index + 1)}',
                        vietnamese:
                            'Cạnh ${_vertexName(index)}${_vertexName(index + 1)}',
                        indonesian:
                            'Sisi ${_vertexName(index)}${_vertexName(index + 1)}',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    strings.text('頂点Aからの対角線'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (
                    var index = 0;
                    index < _diagonalControllers.length;
                    index++
                  ) ...[
                    _lengthField(
                      controller: _diagonalControllers[index],
                      fieldKey: Key('polygonDiagonal$index'),
                      label: strings.choose(
                        japanese: '対角線 A${_vertexName(index + 2)}',
                        english: 'Diagonal A${_vertexName(index + 2)}',
                        simplifiedChinese: '对角线 A${_vertexName(index + 2)}',
                        traditionalChinese: '對角線 A${_vertexName(index + 2)}',
                        vietnamese: 'Đường chéo A${_vertexName(index + 2)}',
                        indonesian: 'Diagonal A${_vertexName(index + 2)}',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              key: const Key('calculatePolygonArea'),
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined),
              label: Text(strings.text('面積を計算')),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                key: const Key('polygonAreaError'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  strings.text(_errorMessage!),
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('polygonAreaResult'),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.text('計算結果'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_format(result.totalArea)} m²',
                      key: const Key('polygonAreaTotal'),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 26),
                    for (final (index, area) in result.triangleAreas.indexed)
                      Text(
                        strings.choose(
                          japanese: '三角形${index + 1}　${_format(area)} m²',
                          english: 'Triangle ${index + 1}  ${_format(area)} m²',
                          simplifiedChinese:
                              '三角形${index + 1}　${_format(area)} m²',
                          traditionalChinese:
                              '三角形${index + 1}　${_format(area)} m²',
                          vietnamese:
                              'Tam giác ${index + 1}  ${_format(area)} m²',
                          indonesian:
                              'Segitiga ${index + 1}  ${_format(area)} m²',
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('sendPolygonAreaToEstimate'),
                onPressed: _sendToEstimate,
                icon: const Icon(Icons.request_quote_outlined),
                label: Text(strings.text('見積明細へ追加')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lengthField({
    required TextEditingController controller,
    required Key fieldKey,
    required String label,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: 'm'),
      validator: _validateLength,
    );
  }

  String _vertexName(int index) {
    if (index == _outerControllers.length) return 'A';
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  }
}
