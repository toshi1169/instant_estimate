import 'package:flutter/material.dart';

import '../../../core/domain/transport_vehicle.dart';
import '../../../core/domain/persistent_id.dart';
import '../../../core/localization/app_localizations.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import 'backfill_tab.dart';
import 'embankment_tab.dart';
import 'earthwork_common_widgets.dart';
import 'excavation_haul_tab.dart';

class EarthworkCalculationScreen extends StatefulWidget {
  const EarthworkCalculationScreen({
    required this.onSendToEstimate,
    this.settings = const AppSettings(),
    this.onSettingsChanged,
    super.key,
  });

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;
  final AppSettings settings;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  State<EarthworkCalculationScreen> createState() =>
      _EarthworkCalculationScreenState();
}

class _EarthworkCalculationScreenState
    extends State<EarthworkCalculationScreen> {
  late List<TransportVehicle> _customVehicles;

  List<TransportVehicle> get _vehicles => <TransportVehicle>[
    ...InitialTransportVehicles.all,
    ..._customVehicles,
  ];

  @override
  void initState() {
    super.initState();
    _customVehicles = [...widget.settings.customTransportVehicles];
  }

  Future<TransportVehicle?> _addVehicle() async {
    final vehicle = await showAddTransportVehicleDialog(context);
    if (vehicle == null || !mounted) return null;
    final used = _vehicles.map((existing) => existing.id);
    final uniqueVehicle = used.contains(vehicle.id)
        ? TransportVehicle(
            id: PersistentId.create(excluding: used),
            name: vehicle.name,
            initialCapacityCubicMeters: vehicle.initialCapacityCubicMeters,
            maximumPayloadTons: vehicle.maximumPayloadTons,
            approximateCapacityLabel: vehicle.approximateCapacityLabel,
            isCrawler: vehicle.isCrawler,
            isCustom: vehicle.isCustom,
          )
        : vehicle;
    setState(() => _customVehicles = [..._customVehicles, uniqueVehicle]);
    widget.onSettingsChanged?.call(
      widget.settings.copyWith(customTransportVehicles: _customVehicles),
    );
    return uniqueVehicle;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(strings.text('土量計算')),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: strings.text('掘削・搬出')),
              Tab(text: strings.text('埋戻し')),
              Tab(text: strings.text('盛土')),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              ExcavationHaulTab(
                settings: widget.settings,
                vehicles: _vehicles,
                onAddVehicle: _addVehicle,
                onSendToEstimate: widget.onSendToEstimate,
              ),
              BackfillTab(
                settings: widget.settings,
                onSendToEstimate: widget.onSendToEstimate,
              ),
              EmbankmentTab(
                settings: widget.settings,
                vehicles: _vehicles,
                onAddVehicle: _addVehicle,
                onSendToEstimate: widget.onSendToEstimate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
