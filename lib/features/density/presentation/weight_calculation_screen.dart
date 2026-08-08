import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/weight_calculator.dart';

class WeightCalculationScreen extends StatefulWidget {
  const WeightCalculationScreen({
    required this.onSendToEstimate,
    this.settings = const AppSettings(),
    this.onSettingsChanged,
    super.key,
  });

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;
  final AppSettings settings;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  State<WeightCalculationScreen> createState() =>
      _WeightCalculationScreenState();
}

class _WeightCalculationScreenState extends State<WeightCalculationScreen> {
  static const _customMaterial = 'その他';
  static const _addMaterial = '__add_material__';

  final _formKey = GlobalKey<FormState>();
  final _volumeController = TextEditingController();
  final _densityController = TextEditingController(
    text: _formatNumber(densityMaterialPresets.first.density),
  );
  final _customMaterialController = TextEditingController();

  String _selectedMaterial = densityMaterialPresets.first.name;
  late List<DensityMaterialPreset> _registeredMaterials;
  WeightCalculationResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _registeredMaterials = [...widget.settings.customDensityMaterials];
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _densityController.dispose();
    _customMaterialController.dispose();
    super.dispose();
  }

  String get _materialName => _selectedMaterial == _customMaterial
      ? _customMaterialController.text.trim()
      : _selectedMaterial;

  Future<void> _selectMaterial(String? value) async {
    if (value == null) return;
    if (value == _addMaterial) {
      final material = await _showAddMaterialDialog();
      if (material == null || !mounted) return;
      setState(() {
        _registeredMaterials = [..._registeredMaterials, material];
        _selectedMaterial = material.name;
        _densityController.text = _formatNumber(material.density);
        _result = null;
        _errorMessage = null;
      });
      widget.onSettingsChanged?.call(
        widget.settings.copyWith(customDensityMaterials: _registeredMaterials),
      );
      return;
    }
    DensityMaterialPreset? preset;
    for (final material in [
      ...densityMaterialPresets,
      ..._registeredMaterials,
    ]) {
      if (material.name == value) preset = material;
    }
    setState(() {
      _selectedMaterial = value;
      if (preset != null) {
        _densityController.text = _formatNumber(preset.density);
      }
      _result = null;
      _errorMessage = null;
    });
  }

  Future<DensityMaterialPreset?> _showAddMaterialDialog() async {
    return showDialog<DensityMaterialPreset>(
      context: context,
      builder: (_) => _AddDensityMaterialDialog(
        reservedNames: <String>{
          _customMaterial,
          _addMaterial,
          ...densityMaterialPresets.map((material) => material.name),
          ..._registeredMaterials.map((material) => material.name),
        },
      ),
    );
  }

  void _deleteSelectedMaterial() {
    final name = _selectedMaterial;
    if (!_registeredMaterials.any((material) => material.name == name)) return;
    setState(() {
      _registeredMaterials = _registeredMaterials
          .where((material) => material.name != name)
          .toList(growable: false);
      _selectedMaterial = densityMaterialPresets.first.name;
      _densityController.text = _formatNumber(
        densityMaterialPresets.first.density,
      );
      _result = null;
      _errorMessage = null;
    });
    widget.onSettingsChanged?.call(
      widget.settings.copyWith(customDensityMaterials: _registeredMaterials),
    );
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final result = WeightCalculator.calculate(
        volumeCubicMeters: _parse(_volumeController.text),
        densityTonnesPerCubicMeter: _parse(_densityController.text),
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

  void _clear() {
    setState(() {
      _selectedMaterial = densityMaterialPresets.first.name;
      _volumeController.clear();
      _densityController.text = _formatNumber(
        densityMaterialPresets.first.density,
      );
      _customMaterialController.clear();
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _sendToEstimate() async {
    final result = _result;
    if (result == null) return;
    final volume = _formatNumber(result.volumeCubicMeters);
    final density = _formatNumber(result.densityTonnesPerCubicMeter);
    final weight = _formatNumber(result.weightTonnes);
    final specification = '材料=$_materialName 体積=${volume}m³ 比重=${density}t/m³';
    await widget.onSendToEstimate(
      EstimateItemDraft(
        name: _materialName,
        specification: specification,
        quantity: result.weightTonnes,
        unit: 't',
        calculationBasis: '$volume × $density ＝ ${weight}t',
        originalQuantity: result.weightTonnes,
      ),
    );
  }

  double _parse(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));

  String? _validatePositiveNumber(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite || number <= 0) {
      return '0より大きい数値を入力';
    }
    return null;
  }

  String? _validateMaterialName(String? value) {
    if ((value ?? '').trim().isEmpty) return '材料名を入力';
    return null;
  }

  static String _formatNumber(double value) {
    final text = value.toStringAsFixed(3);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('比重・重量計算'),
        actions: [TextButton(onPressed: _clear, child: const Text('クリア'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Text(
              '材料と体積から重量を計算します。初期の比重は目安のため、現場条件に合わせて変更できます。',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    key: const Key('densityMaterial'),
                    initialValue: _selectedMaterial,
                    decoration: const InputDecoration(labelText: '材料'),
                    items: [
                      for (final material in densityMaterialPresets)
                        DropdownMenuItem(
                          value: material.name,
                          child: Text(material.name),
                        ),
                      for (final material in _registeredMaterials)
                        DropdownMenuItem(
                          value: material.name,
                          child: Text('${material.name}（登録）'),
                        ),
                      const DropdownMenuItem(
                        value: _customMaterial,
                        child: Text(_customMaterial),
                      ),
                      const DropdownMenuItem(
                        value: _addMaterial,
                        child: Row(
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('材料を追加'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: _selectMaterial,
                  ),
                  if (_registeredMaterials.any(
                    (material) => material.name == _selectedMaterial,
                  )) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const Key('deleteDensityMaterial'),
                        onPressed: _deleteSelectedMaterial,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('登録材料を削除'),
                      ),
                    ),
                  ],
                  if (_selectedMaterial == _customMaterial) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('customDensityMaterialName'),
                      controller: _customMaterialController,
                      decoration: const InputDecoration(labelText: '材料名'),
                      validator: _validateMaterialName,
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('densityVolume'),
                    controller: _volumeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '体積',
                      suffixText: 'm³',
                    ),
                    validator: _validatePositiveNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('densityValue'),
                    controller: _densityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '比重',
                      suffixText: 't/m³',
                    ),
                    validator: _validatePositiveNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: const Key('calculateWeight'),
              onPressed: _calculate,
              icon: const Icon(Icons.scale_outlined),
              label: const Text('重量を計算'),
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
                  _errorMessage!,
                  key: const Key('weightCalculationError'),
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_result case final result?) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('weightCalculationResult'),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('計算結果', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(
                      '${_formatNumber(result.weightTonnes)} t',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatNumber(result.weightKilograms)} kg',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleMedium,
                    ),
                    const Divider(height: 26),
                    Text(
                      '${_formatNumber(result.volumeCubicMeters)}m³ × '
                      '${_formatNumber(result.densityTonnesPerCubicMeter)}t/m³',
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('sendWeightToEstimate'),
                onPressed: _sendToEstimate,
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('見積明細へ追加'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddDensityMaterialDialog extends StatefulWidget {
  const _AddDensityMaterialDialog({required this.reservedNames});

  final Set<String> reservedNames;

  @override
  State<_AddDensityMaterialDialog> createState() =>
      _AddDensityMaterialDialogState();
}

class _AddDensityMaterialDialogState extends State<_AddDensityMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _densityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _densityController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return '材料名を入力';
    if (widget.reservedNames.contains(name)) {
      return '同じ材料名が登録されています';
    }
    return null;
  }

  String? _validateDensity(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite || number <= 0) {
      return '0より大きい数値を入力';
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      DensityMaterialPreset(
        name: _nameController.text.trim(),
        density: double.parse(
          _densityController.text.trim().replaceAll(',', '.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('材料を追加'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('newDensityMaterialName'),
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '材料名'),
              validator: _validateName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('newDensityMaterialValue'),
              controller: _densityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: '比重',
                suffixText: 't/m³',
              ),
              validator: _validateDensity,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          key: const Key('saveDensityMaterial'),
          onPressed: _save,
          child: const Text('追加'),
        ),
      ],
    );
  }
}
