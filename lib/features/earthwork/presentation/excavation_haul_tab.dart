import 'package:flutter/material.dart';

import '../../../core/domain/transport_vehicle.dart';
import '../../../core/localization/app_localizations.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/earthwork_calculator.dart';
import 'earthwork_common_widgets.dart';

class ExcavationHaulTab extends StatefulWidget {
  const ExcavationHaulTab({
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
  State<ExcavationHaulTab> createState() => _ExcavationHaulTabState();
}

class _ExcavationHaulTabState extends State<ExcavationHaulTab> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _looseFactorController = TextEditingController(text: '1.25');
  final _capacityController = TextEditingController(text: '3');
  String _selectedVehicleId = InitialTransportVehicles.defaultVehicleId;
  ExcavationHaulResult? _result;
  String? _error;

  TransportVehicle get _selectedVehicle => widget.vehicles.firstWhere(
    (vehicle) => vehicle.id == _selectedVehicleId,
    orElse: () => InitialTransportVehicles.standard.firstWhere(
      (vehicle) => vehicle.id == InitialTransportVehicles.defaultVehicleId,
    ),
  );

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _looseFactorController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final result = EarthworkCalculator.calculateExcavationHaul(
        lengthMeters: parseEarthworkNumber(_lengthController.text),
        widthMeters: parseEarthworkNumber(_widthController.text),
        depthMeters: parseEarthworkNumber(_depthController.text),
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
      _depthController.clear();
      _looseFactorController.text = '1.25';
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

  String get _dimensions =>
      'L=${formatEarthworkNumber(parseEarthworkNumber(_lengthController.text))}m '
      '× W=${formatEarthworkNumber(parseEarthworkNumber(_widthController.text))}m '
      '× H=${formatEarthworkNumber(parseEarthworkNumber(_depthController.text))}m';

  @override
  Widget build(BuildContext context) {
    final result = _result;
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
                  l10n.text('掘削後のほぐし土量と運搬回数を算出します。'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(onPressed: _clear, child: Text(l10n.text('入力を消去'))),
            ],
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'earthworkLength',
            controller: _lengthController,
            label: l10n.text('長さ'),
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'earthworkWidth',
            controller: _widthController,
            label: l10n.text('幅'),
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'earthworkDepth',
            controller: _depthController,
            label: l10n.text('深さ'),
            suffix: 'm',
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 12),
          EarthworkNumberField(
            keyName: 'earthworkLooseFactor',
            controller: _looseFactorController,
            label: l10n.text('ほぐし係数'),
            helperText: l10n.text('初期参考値 1.25（現場条件に合わせて変更可能）'),
            validator: validatePositiveEarthworkNumber,
          ),
          const SizedBox(height: 16),
          TransportVehicleFields(
            vehicles: widget.vehicles,
            selectedVehicleId: _selectedVehicleId,
            capacityController: _capacityController,
            onVehicleSelected: _selectVehicle,
            onAddVehicle: widget.onAddVehicle,
            capacityKeyName: 'earthworkLoadCapacity',
            vehicleKeyName: 'earthworkVehicle',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('calculateEarthwork'),
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
          if (result != null) ...[
            const SizedBox(height: 20),
            KeyedSubtree(
              key: const Key('earthworkExcavationResult'),
              child: EarthworkResultCard(
                label: l10n.text('地山掘削量'),
                value: '${formatEarthworkNumber(result.bankVolume)} m³',
                onSend: () => widget.onSendToEstimate(
                  EstimateItemDraft(
                    trade: l10n.text('土工'),
                    name: l10n.text('掘削'),
                    quantity: result.bankVolume,
                    originalQuantity: result.bankVolume,
                    unit: 'm³',
                    specification: _dimensions,
                    calculationBasis:
                        '$_dimensions = ${formatEarthworkNumber(result.bankVolume)}m³',
                  ),
                ),
              ),
            ),
            KeyedSubtree(
              key: const Key('earthworkHaulResult'),
              child: EarthworkResultCard(
                label: l10n.text('ほぐし土量（搬出土量）'),
                value: '${formatEarthworkNumber(result.looseVolume)} m³',
                note:
                    '${l10n.text('地山掘削量 × ほぐし係数')} '
                    '${formatEarthworkNumber(result.looseFactor)}',
                onSend: () => widget.onSendToEstimate(
                  EstimateItemDraft(
                    trade: l10n.text('土工'),
                    name: l10n.text('搬出土'),
                    quantity: result.looseVolume,
                    originalQuantity: result.looseVolume,
                    unit: 'm³',
                    specification:
                        '${l10n.text('ほぐし係数')} '
                        '${formatEarthworkNumber(result.looseFactor)}',
                    calculationBasis:
                        '${formatEarthworkNumber(result.bankVolume)} × '
                        '${formatEarthworkNumber(result.looseFactor)} = '
                        '${formatEarthworkNumber(result.looseVolume)}m³',
                  ),
                ),
              ),
            ),
            KeyedSubtree(
              key: const Key('earthworkDumpResult'),
              child: EarthworkResultCard(
                label: l10n.text('必要運搬回数'),
                value: '${result.transportTrips} ${l10n.text('回')}',
                note: l10n.text('端数切り上げ'),
                onSend: () => widget.onSendToEstimate(
                  EstimateItemDraft(
                    trade: l10n.text('土工'),
                    name: l10n.text('土砂運搬'),
                    quantity: result.transportTrips.toDouble(),
                    originalQuantity: result.transportTrips.toDouble(),
                    unit: l10n.text('回'),
                    specification:
                        '${_selectedVehicle.isCustom ? _selectedVehicle.name : l10n.text(_selectedVehicle.name)}・'
                        '${l10n.text('積載容量')} '
                        '${formatEarthworkNumber(result.loadCapacityCubicMeters)}${l10n.text('m³/回')}',
                    calculationBasis:
                        '${formatEarthworkNumber(result.looseVolume)} ÷ '
                        '${formatEarthworkNumber(result.loadCapacityCubicMeters)} = '
                        '${result.transportTrips}${l10n.text('回（切り上げ）')}',
                  ),
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
