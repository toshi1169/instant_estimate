import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../estimate/domain/estimate_totals.dart';

String formatTaxRateBasisPoints(int basisPoints) {
  validateEstimateTaxRateBasisPoints(basisPoints);
  final whole = basisPoints ~/ 100;
  final fraction = basisPoints % 100;
  if (fraction == 0) return '$whole%';
  final digits = fraction % 10 == 0
      ? '${fraction ~/ 10}'
      : fraction.toString().padLeft(2, '0');
  return '$whole.$digits%';
}

int? parseTaxRateBasisPoints(String source) {
  final normalized = source.trim().replaceAll(',', '.');
  if (!RegExp(
    r'^(?:100(?:\.0{1,2})?|\d{1,2}(?:\.\d{1,2})?)$',
  ).hasMatch(normalized)) {
    return null;
  }
  final value = double.tryParse(normalized);
  if (value == null) return null;
  final basisPoints = (value * 100).round();
  if (basisPoints < minEstimateTaxRateBasisPoints ||
      basisPoints > maxEstimateTaxRateBasisPoints) {
    return null;
  }
  return basisPoints;
}

class TaxRateInputFormatter extends TextInputFormatter {
  const TaxRateInputFormatter();

  static final _pattern = RegExp(
    r'^(?:|100(?:[.,]0{0,2})?|\d{0,2}(?:[.,]\d{0,2})?)$',
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _pattern.hasMatch(newValue.text) ? newValue : oldValue;
}

class EstimateTaxSettingsScreen extends StatefulWidget {
  const EstimateTaxSettingsScreen({
    required this.title,
    required this.taxEnabled,
    required this.taxRateBasisPoints,
    required this.onTaxEnabledChanged,
    required this.onTaxRateBasisPointsChanged,
    this.keyPrefix = 'defaultEstimate',
    super.key,
  });

  final String title;
  final bool taxEnabled;
  final int taxRateBasisPoints;
  final ValueChanged<bool> onTaxEnabledChanged;
  final ValueChanged<int> onTaxRateBasisPointsChanged;
  final String keyPrefix;

  @override
  State<EstimateTaxSettingsScreen> createState() =>
      _EstimateTaxSettingsScreenState();
}

class _EstimateTaxSettingsScreenState extends State<EstimateTaxSettingsScreen> {
  late bool _taxEnabled = widget.taxEnabled;
  late int _taxRateBasisPoints = widget.taxRateBasisPoints;
  late final TextEditingController _rateController = TextEditingController(
    text: formatTaxRateBasisPoints(_taxRateBasisPoints).replaceAll('%', ''),
  );

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _commitRate() {
    final parsed = parseTaxRateBasisPoints(_rateController.text);
    if (parsed == null) {
      _rateController.text = formatTaxRateBasisPoints(
        _taxRateBasisPoints,
      ).replaceAll('%', '');
      return;
    }
    _taxRateBasisPoints = parsed;
    widget.onTaxRateBasisPointsChanged(parsed);
    _rateController.text = formatTaxRateBasisPoints(parsed).replaceAll('%', '');
  }

  void _updateRateIfValid(String value) {
    final parsed = parseTaxRateBasisPoints(value);
    if (parsed == null || parsed == _taxRateBasisPoints) return;
    _taxRateBasisPoints = parsed;
    widget.onTaxRateBasisPointsChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    key: Key('${widget.keyPrefix}TaxEnabledSetting'),
                    secondary: const Icon(Icons.receipt_long_outlined),
                    title: Text(strings.applyTax),
                    value: _taxEnabled,
                    onChanged: (value) {
                      setState(() => _taxEnabled = value);
                      widget.onTaxEnabledChanged(value);
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: TextField(
                      key: Key('${widget.keyPrefix}TaxRateSetting'),
                      controller: _rateController,
                      enabled: _taxEnabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: const [TaxRateInputFormatter()],
                      decoration: InputDecoration(
                        labelText: strings.taxRate,
                        suffixText: '%',
                        helperText: strings.taxRateNotice,
                        helperMaxLines: 3,
                      ),
                      onChanged: _updateRateIfValid,
                      onSubmitted: (_) {
                        _commitRate();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      onTapOutside: (_) {
                        _commitRate();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
