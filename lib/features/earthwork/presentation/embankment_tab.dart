import 'package:flutter/material.dart';

import '../../../core/domain/transport_vehicle.dart';
import '../../../core/localization/app_localizations.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/earthwork_calculator.dart';
import 'earthwork_common_widgets.dart';

class EmbankmentTab extends StatefulWidget {
  const EmbankmentTab({
    required this.settings,
    required this.vehicles,
    required this.onAddVehicle,
    required this.onSendToEstimate,
    super.key,
  });

  final AppSettings settings;
  final List<TransportVehicle> vehicles;
  final Future<TransportVehicle?> Function() onAddVehicle;
  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;

  @override
  State<EmbankmentTab> createState() => _EmbankmentTabState();
}

class _EmbankmentTabState extends State<EmbankmentTab> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _compactionController = TextEditingController(text: '0.90');
  final _looseFactorController = TextEditingController(text: '1.25');
  final _customSlopeController = TextEditingController(text: '1.5');
  final _capacityController = TextEditingController(text: '3');
  String _selectedVehicleId = InitialTransportVehicles.defaultVehicleId;
  String _slopePreset = '1.5';
  bool _hasSlope = false;
  EmbankmentCalculationResult? _result;
  String? _error;

  TransportVehicle get _selectedVehicle => widget.vehicles.firstWhere(
    (vehicle) => vehicle.id == _selectedVehicleId,
    orElse: () => InitialTransportVehicles.standard.firstWhere(
      (vehicle) => vehicle.id == InitialTransportVehicles.defaultVehicleId,
    ),
  );

  double get _slopeRatio => _slopePreset == 'custom'
      ? parseEarthworkNumber(_customSlopeController.text)
      : double.parse(_slopePreset);

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _compactionController.dispose();
    _looseFactorController.dispose();
    _customSlopeController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final result = EarthworkCalculator.calculateEmbankment(
        topLengthMeters: parseEarthworkNumber(_lengthController.text),
        topWidthMeters: parseEarthworkNumber(_widthController.text),
        heightMeters: parseEarthworkNumber(_heightController.text),
        hasSlope: _hasSlope,
        slopeRatioHorizontal: _hasSlope ? _slopeRatio : 0,
        compactionFactor: parseEarthworkNumber(_compactionController.text),
        looseFactor: parseEarthworkNumber(_looseFactorController.text),
        loadCapacityCubicMeters: parseEarthworkNumber(_capacityController.text),
      );
      setState(() {
        _result = result;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error.message.toString();
      });
    }
  }

  void _clear() {
    setState(() {
      _lengthController.clear();
      _widthController.clear();
      _heightController.clear();
      _compactionController.text = '0.90';
      _looseFactorController.text = '1.25';
      _customSlopeController.text = '1.5';
      _hasSlope = false;
      _slopePreset = '1.5';
      _selectedVehicleId = InitialTransportVehicles.defaultVehicleId;
      _capacityController.text = '3';
      _result = null;
      _error = null;
    });
  }

  void _selectVehicle(TransportVehicle vehicle) {
    setState(() {
      _selectedVehicleId = vehicle.id;
      _capacityController.text = formatEarthworkNumber(
        vehicle.initialCapacityCubicMeters,
      );
      _result = null;
    });
  }

  Future<void> _send({
    required String name,
    required double quantity,
    required String basis,
    String specification = '',
    String unit = 'm³',
  }) {
    final l10n = AppLocalizations.of(context);
    return widget.onSendToEstimate(
      EstimateItemDraft(
        trade: l10n.text('土工'),
        name: l10n.text(name),
        quantity: widget.settings.roundEstimateQuantity(quantity),
        originalQuantity: quantity,
        unit: unit,
        specification: specification,
        calculationBasis: basis,
      ),
    );
  }

  String _geometrySpecification(EmbankmentGeometry geometry) {
    final l10n = AppLocalizations.of(context);
    final slope = geometry.hasSlope
        ? '・${l10n.text('法勾配（垂直1：水平）')} '
              '1:${formatEarthworkNumber(geometry.slopeRatioHorizontal)}'
        : '・${l10n.text('法面なし')}';
    return '${l10n.text('天端')} L='
        '${formatEarthworkNumber(geometry.topLengthMeters)}m '
        '× W=${formatEarthworkNumber(geometry.topWidthMeters)}m '
        '× H=${formatEarthworkNumber(geometry.heightMeters)}m$slope';
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final geometry = result?.geometry;
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.text('完成形状から必要な搬入土量を算出します。'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(onPressed: _clear, child: Text(l10n.text('入力を消去'))),
            ],
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'embankmentLength',
            controller: _lengthController,
            label: l10n.text('天端の長さ'),
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'embankmentWidth',
            controller: _widthController,
            label: l10n.text('天端の幅'),
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'embankmentHeight',
            controller: _heightController,
            label: l10n.text('盛土高さ'),
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('embankmentHasSlope'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.text('法面あり')),
            subtitle: Text(l10n.text('OFFの場合は直方体として計算')),
            value: _hasSlope,
            onChanged: (value) => setState(() {
              _hasSlope = value;
              _result = null;
            }),
          ),
          if (_hasSlope) ...[
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              key: const Key('embankmentSlopePreset'),
              initialValue: _slopePreset,
              decoration: InputDecoration(labelText: l10n.text('法勾配（垂直1：水平）')),
              items: [
                const DropdownMenuItem(value: '1.5', child: Text('1 : 1.5')),
                const DropdownMenuItem(value: '1.8', child: Text('1 : 1.8')),
                const DropdownMenuItem(value: '2.0', child: Text('1 : 2.0')),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text(l10n.text('任意入力')),
                ),
              ],
              onChanged: (value) => setState(() {
                _slopePreset = value ?? '1.5';
                _result = null;
              }),
            ),
            if (_slopePreset == 'custom') ...[
              const SizedBox(height: 12),
              EarthworkNumberField(
                keyName: 'embankmentCustomSlope',
                controller: _customSlopeController,
                label: l10n.text('任意の水平比'),
                helperText: l10n.text('例：1 : 1.7 の場合は 1.7'),
                validator: validatePositiveEarthworkNumber,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              l10n.text('※候補は参考値です。設計図書や現場条件に合わせて確認・変更してください。'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'embankmentCompactionFactor',
            controller: _compactionController,
            label: l10n.text('締固め係数'),
            helperText: l10n.text('初期参考値 0.90'),
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'embankmentLooseFactor',
            controller: _looseFactorController,
            label: l10n.text('搬入時のほぐし係数'),
            helperText: l10n.text('初期参考値 1.25'),
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 16),
          TransportVehicleFields(
            vehicles: widget.vehicles,
            selectedVehicleId: _selectedVehicleId,
            capacityController: _capacityController,
            onVehicleSelected: _selectVehicle,
            onAddVehicle: widget.onAddVehicle,
            capacityKeyName: 'embankmentLoadCapacity',
            vehicleKeyName: 'embankmentVehicle',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('calculateEmbankment'),
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: Text(l10n.text('計算する')),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.text(_error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (geometry != null && geometry.heightMeters >= 2) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.text(
                          '注意\n盛土高さが大きい場合は、地盤条件・法面安定・排水条件・'
                          '設計図書・関係法令等を確認してください。',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (result != null && geometry != null) ...[
            const SizedBox(height: 20),
            EarthworkResultCard(
              label: l10n.text('完成盛土量'),
              value: '${formatEarthworkNumber(result.completedVolume)} m³',
              onSend: () => _send(
                name: '盛土',
                quantity: result.completedVolume,
                specification: _geometrySpecification(geometry),
                basis:
                    '${l10n.text('完成形状')} = '
                    '${formatEarthworkNumber(result.completedVolume)}m³',
              ),
            ),
            EarthworkResultCard(
              label: l10n.text('締固めを考慮した必要土量'),
              value: '${formatEarthworkNumber(result.requiredBankVolume)} m³',
              note:
                  '${l10n.text('完成盛土量 ÷ 締固め係数')} '
                  '${formatEarthworkNumber(result.compactionFactor)}',
              onSend: () => _send(
                name: '盛土必要土',
                quantity: result.requiredBankVolume,
                specification:
                    '${l10n.text('締固め係数')} '
                    '${formatEarthworkNumber(result.compactionFactor)}',
                basis:
                    '${formatEarthworkNumber(result.completedVolume)} ÷ '
                    '${formatEarthworkNumber(result.compactionFactor)} = '
                    '${formatEarthworkNumber(result.requiredBankVolume)}m³',
              ),
            ),
            EarthworkResultCard(
              label: l10n.text('必要搬入土量'),
              value:
                  '${formatEarthworkNumber(result.requiredIncomingLooseVolume)} m³',
              note:
                  '${l10n.text('必要土量 × ほぐし係数')} '
                  '${formatEarthworkNumber(result.looseFactor)}',
              onSend: () => _send(
                name: '搬入土',
                quantity: result.requiredIncomingLooseVolume,
                specification:
                    '${l10n.text('ほぐし係数')} '
                    '${formatEarthworkNumber(result.looseFactor)}',
                basis:
                    '${formatEarthworkNumber(result.requiredBankVolume)} × '
                    '${formatEarthworkNumber(result.looseFactor)} = '
                    '${formatEarthworkNumber(result.requiredIncomingLooseVolume)}m³',
              ),
            ),
            EarthworkResultCard(
              label: l10n.text('必要運搬回数'),
              value: '${result.transportTrips} ${l10n.text('回')}',
              note: l10n.text('端数切り上げ'),
              onSend: () => _send(
                name: '土砂運搬',
                quantity: result.transportTrips.toDouble(),
                unit: l10n.text('回'),
                specification:
                    '${_selectedVehicle.isCustom ? _selectedVehicle.name : l10n.text(_selectedVehicle.name)}・'
                    '${l10n.text('積載容量')} '
                    '${formatEarthworkNumber(result.loadCapacityCubicMeters)}${l10n.text('m³/回')}',
                basis:
                    '${formatEarthworkNumber(result.requiredIncomingLooseVolume)} ÷ '
                    '${formatEarthworkNumber(result.loadCapacityCubicMeters)} = '
                    '${result.transportTrips}${l10n.text('回（切り上げ）')}',
              ),
            ),
            if (geometry.hasSlope)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.text('法面形状（参考）'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.text('片側水平距離')}：'
                        '${formatEarthworkNumber(geometry.slopeHorizontalRun)} m',
                      ),
                      Text(
                        '${l10n.text('法長')}：'
                        '${formatEarthworkNumber(geometry.slopeLength)} m',
                      ),
                      Text(
                        '${l10n.text('底面')}：'
                        '${formatEarthworkNumber(geometry.bottomLengthMeters)} m '
                        '× ${formatEarthworkNumber(geometry.bottomWidthMeters)} m',
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const EarthworkReferenceNote(),
        ],
      ),
    );
  }
}
