import 'package:flutter/material.dart';

import '../../../core/domain/transport_vehicle.dart';
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
    setState(() => _customVehicles = [..._customVehicles, vehicle]);
    widget.onSettingsChanged?.call(
      widget.settings.copyWith(customTransportVehicles: _customVehicles),
    );
    return vehicle;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('土量計算'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '掘削・搬出'),
              Tab(text: '埋戻し'),
              Tab(text: '盛土'),
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
