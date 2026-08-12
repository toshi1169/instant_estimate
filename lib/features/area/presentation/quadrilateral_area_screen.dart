import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/quadrilateral_area_calculator.dart';

class QuadrilateralAreaScreen extends StatefulWidget {
  const QuadrilateralAreaScreen({
    required this.onSendToEstimate,
    this.settings = const AppSettings(),
    super.key,
  });

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;
  final AppSettings settings;

  @override
  State<QuadrilateralAreaScreen> createState() =>
      _QuadrilateralAreaScreenState();
}

class _QuadrilateralAreaScreenState extends State<QuadrilateralAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = List.generate(5, (_) => TextEditingController());
  QuadrilateralAreaResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final result = QuadrilateralAreaCalculator.calculate(
        sideA: _valueAt(0),
        sideB: _valueAt(1),
        sideC: _valueAt(2),
        sideD: _valueAt(3),
        diagonal: _valueAt(4),
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

  double _valueAt(int index) =>
      double.parse(_controllers[index].text.replaceAll(',', '.'));

  void _clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _sendToEstimate() async {
    final result = _result;
    if (result == null) return;
    final strings = AppLocalizations.of(context);
    final values = [for (var index = 0; index < 5; index++) _valueAt(index)];
    final specification =
        'A=${_format(values[0])}m B=${_format(values[1])}m '
        'C=${_format(values[2])}m D=${_format(values[3])}m '
        '${strings.text('対角線')}=${_format(values[4])}m';
    final triangle = strings.choose(
      japanese: '三角形',
      english: 'Triangle',
      simplifiedChinese: '三角形',
      traditionalChinese: '三角形',
      vietnamese: 'Tam giác',
      indonesian: 'Segitiga',
      filipino: 'Tatsulok',
      myanmar: 'တြိဂံ',
    );
    final calculationBasis =
        '$specification\n'
        '$triangle① ${_format(result.firstTriangleArea)}m² ＋ '
        '$triangle② ${_format(result.secondTriangleArea)}m² '
        '＝ ${_format(result.totalArea)}m²';
    await widget.onSendToEstimate(
      EstimateItemDraft(
        name: strings.text('面積'),
        specification: specification,
        quantity: widget.settings.roundEstimateQuantity(result.totalArea),
        unit: 'm²',
        calculationBasis: calculationBasis,
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

  String _format(double value) {
    final text = value.toStringAsFixed(3);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('4辺面積計算')),
        actions: [
          TextButton(onPressed: _clear, child: Text(strings.text('クリア'))),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(
              strings.text('四角形を対角線で2つの三角形に分け、ヘロンの公式で面積を求めます。'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _ShapeGuide(
              color: theme.colorScheme.onSurfaceVariant,
              diagonalLabel: strings.text('対角線'),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _lengthField(0, strings.text('辺A'))),
                      const SizedBox(width: 12),
                      Expanded(child: _lengthField(1, strings.text('辺B'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _lengthField(2, strings.text('辺C'))),
                      const SizedBox(width: 12),
                      Expanded(child: _lengthField(3, strings.text('辺D'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _lengthField(4, strings.text('対角線')),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: const Key('calculateQuadrilateralArea'),
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined),
              label: Text(strings.text('面積を計算')),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  strings.text(_errorMessage!),
                  key: const Key('quadrilateralAreaError'),
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('quadrilateralAreaResult'),
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
                      textAlign: TextAlign.right,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 26),
                    Text(
                      strings.choose(
                        japanese:
                            '三角形① ${_format(result.firstTriangleArea)} m²'
                            '  ＋  三角形② ${_format(result.secondTriangleArea)} m²',
                        english:
                            'Triangle 1 ${_format(result.firstTriangleArea)} m²'
                            '  +  Triangle 2 ${_format(result.secondTriangleArea)} m²',
                        simplifiedChinese:
                            '三角形① ${_format(result.firstTriangleArea)} m²'
                            '  ＋  三角形② ${_format(result.secondTriangleArea)} m²',
                        traditionalChinese:
                            '三角形① ${_format(result.firstTriangleArea)} m²'
                            '  ＋  三角形② ${_format(result.secondTriangleArea)} m²',
                        vietnamese:
                            'Tam giác 1 ${_format(result.firstTriangleArea)} m²'
                            '  +  Tam giác 2 ${_format(result.secondTriangleArea)} m²',
                        indonesian:
                            'Segitiga 1 ${_format(result.firstTriangleArea)} m²'
                            '  +  Segitiga 2 ${_format(result.secondTriangleArea)} m²',
                        filipino:
                            'Tatsulok 1 ${_format(result.firstTriangleArea)} m²'
                            '  +  Tatsulok 2 ${_format(result.secondTriangleArea)} m²',
                        myanmar:
                            'တြိဂံ 1 ${_format(result.firstTriangleArea)} m²'
                            '  +  တြိဂံ 2 ${_format(result.secondTriangleArea)} m²',
                      ),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('sendQuadrilateralAreaToEstimate'),
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

  Widget _lengthField(int index, String label) {
    return TextFormField(
      key: Key('quadrilateralLength$index'),
      controller: _controllers[index],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: 'm'),
      validator: _validateLength,
      onFieldSubmitted: (_) => _calculate(),
    );
  }
}

class _ShapeGuide extends StatelessWidget {
  const _ShapeGuide({required this.color, required this.diagonalLabel});

  final Color color;
  final String diagonalLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: CustomPaint(painter: _ShapeGuidePainter(color, diagonalLabel)),
    );
  }
}

class _ShapeGuidePainter extends CustomPainter {
  const _ShapeGuidePainter(this.color, this.diagonalLabel);

  final Color color;
  final String diagonalLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width * .18, size.height * .78),
      Offset(size.width * .30, size.height * .18),
      Offset(size.width * .78, size.height * .28),
      Offset(size.width * .86, size.height * .82),
    ];
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final diagonal = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas
      ..drawPath(path, outline)
      ..drawLine(points.first, points[2], diagonal);

    final labels = <(String, Offset)>[
      ('A', Offset(size.width * .18, size.height * .40)),
      ('B', Offset(size.width * .53, size.height * .12)),
      ('C', Offset(size.width * .82, size.height * .50)),
      ('D', Offset(size.width * .52, size.height * .84)),
      (diagonalLabel, Offset(size.width * .46, size.height * .48)),
    ];
    for (final (label, offset) in labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: label == diagonalLabel ? AppColors.accent : color,
            fontSize: 13,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(_ShapeGuidePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.diagonalLabel != diagonalLabel;
}
