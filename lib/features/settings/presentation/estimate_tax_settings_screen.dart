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
    this.onContinue,
    this.keyPrefix = 'defaultEstimate',
    super.key,
  });

  final String title;
  final bool taxEnabled;
  final int taxRateBasisPoints;
  final ValueChanged<bool> onTaxEnabledChanged;
  final ValueChanged<int> onTaxRateBasisPointsChanged;
  final Future<void> Function()? onContinue;
  final String keyPrefix;

  @override
  State<EstimateTaxSettingsScreen> createState() =>
      _EstimateTaxSettingsScreenState();
}

class _EstimateTaxSettingsScreenState extends State<EstimateTaxSettingsScreen> {
  late bool _taxEnabled = widget.taxEnabled;
  late int _taxRateBasisPoints = widget.taxRateBasisPoints;
  bool _isRateInputValid = true;
  bool _isContinuing = false;
  late final TextEditingController _rateController = TextEditingController(
    text: formatTaxRateBasisPoints(_taxRateBasisPoints).replaceAll('%', ''),
  );

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  bool _commitRate({bool restoreInvalidValue = true}) {
    final parsed = parseTaxRateBasisPoints(_rateController.text);
    if (parsed == null) {
      if (restoreInvalidValue) {
        _rateController.text = formatTaxRateBasisPoints(
          _taxRateBasisPoints,
        ).replaceAll('%', '');
        setState(() => _isRateInputValid = true);
      } else {
        setState(() => _isRateInputValid = false);
      }
      return false;
    }
    _taxRateBasisPoints = parsed;
    widget.onTaxRateBasisPointsChanged(parsed);
    _rateController.text = formatTaxRateBasisPoints(parsed).replaceAll('%', '');
    setState(() => _isRateInputValid = true);
    return true;
  }

  void _updateRateIfValid(String value) {
    final parsed = parseTaxRateBasisPoints(value);
    setState(() => _isRateInputValid = parsed != null);
    if (parsed == null || parsed == _taxRateBasisPoints) return;
    _taxRateBasisPoints = parsed;
    widget.onTaxRateBasisPointsChanged(parsed);
  }

  Future<void> _continue() async {
    final onContinue = widget.onContinue;
    if (onContinue == null || _isContinuing) return;
    if (!_commitRate(restoreInvalidValue: false)) return;
    setState(() => _isContinuing = true);
    await onContinue();
    if (mounted) setState(() => _isContinuing = false);
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
                      if (!value && !_isRateInputValid) {
                        _commitRate();
                      }
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
      bottomNavigationBar: widget.onContinue == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                key: const Key('completeInitialTaxSetup'),
                onPressed: _isRateInputValid && !_isContinuing
                    ? _continue
                    : null,
                child: _isContinuing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.continueInitialTaxSetup),
              ),
            ),
    );
  }
}
