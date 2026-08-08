import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../settings/domain/app_settings.dart';
import '../domain/ratio_calculator.dart';

class RatioCalculationScreen extends StatefulWidget {
  const RatioCalculationScreen({
    this.settings = const AppSettings(),
    super.key,
  });

  final AppSettings settings;

  @override
  State<RatioCalculationScreen> createState() => _RatioCalculationScreenState();
}

class _RatioCalculationScreenState extends State<RatioCalculationScreen> {
  static const _calculator = RatioCalculator();
  final _controllers = <RatioTerm, TextEditingController>{
    for (final term in RatioTerm.values) term: TextEditingController(),
  };

  RatioCalculationResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers.values) {
      controller.addListener(_recalculate);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller
        ..removeListener(_recalculate)
        ..dispose();
    }
    super.dispose();
  }

  double? _valueOf(RatioTerm term) {
    final text = _controllers[term]!.text.trim().replaceAll(',', '');
    return text.isEmpty ? null : double.tryParse(text);
  }

  void _recalculate() {
    final enteredCount = _controllers.values
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
    RatioCalculationResult? result;
    String? error;
    if (enteredCount == 3) {
      try {
        result = _calculator.calculate(
          a: _valueOf(RatioTerm.a),
          b: _valueOf(RatioTerm.b),
          c: _valueOf(RatioTerm.c),
          d: _valueOf(RatioTerm.d),
        );
      } on FormatException catch (exception) {
        error = exception.message.toString();
      }
    } else if (enteredCount == 4) {
      error = '計算する1項目を空欄にしてください';
    }
    if (mounted) {
      setState(() {
        _result = result;
        _error = error;
      });
    }
  }

  String _format(double value) {
    final rounded = widget.settings.roundEstimateQuantity(value);
    return rounded.toStringAsFixed(widget.settings.decimalPlaces);
  }

  void _clear() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('対比計算'),
        actions: [
          TextButton(onPressed: _clear, child: const Text('クリア')),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      'A：B ＝ C：D',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '4項目のうち3項目を入力すると、\n空欄の値を自動計算します。',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field(RatioTerm.a)),
                        const _EquationMark('：'),
                        Expanded(child: _field(RatioTerm.b)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: _EquationMark('＝'),
                    ),
                    Row(
                      children: [
                        Expanded(child: _field(RatioTerm.c)),
                        const _EquationMark('：'),
                        Expanded(child: _field(RatioTerm.d)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_result != null) _resultCard(_result!),
            if (_error != null) _errorCard(_error!),
            if (_result == null && _error == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('例：A＝2、B＝5、C＝8 と入力すると、D＝20 を算出します。'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(RatioTerm term) {
    final calculated = _result != null && _result!.missingTerm == term
        ? _format(_result!.value)
        : null;
    return TextField(
      key: Key('ratio${term.name.toUpperCase()}'),
      controller: _controllers[term],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: term.name.toUpperCase(),
        hintText: calculated ?? '入力',
        hintStyle: calculated == null
            ? null
            : TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        helperText: calculated == null ? null : '自動計算',
      ),
    );
  }

  Widget _resultCard(RatioCalculationResult result) {
    final label = result.missingTerm.name.toUpperCase();
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('計算結果', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Text(
              '$label ＝ ${_format(result.value)}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(result.formula, textAlign: TextAlign.end),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

class _EquationMark extends StatelessWidget {
  const _EquationMark(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
