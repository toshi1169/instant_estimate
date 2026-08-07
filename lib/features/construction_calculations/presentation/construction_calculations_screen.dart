import 'package:flutter/material.dart';

import '../../area/presentation/quadrilateral_area_screen.dart';
import '../../density/presentation/weight_calculation_screen.dart';
import '../../earthwork/presentation/earthwork_calculation_screen.dart';
import '../../estimate/domain/estimate_item_draft.dart';
import '../../settings/domain/app_settings.dart';
import '../../slope/presentation/slope_calculation_screen.dart';
import '../../productivity/application/productivity_controller.dart';
import '../../productivity/presentation/productivity_calculation_screen.dart';

class ConstructionCalculationsScreen extends StatelessWidget {
  const ConstructionCalculationsScreen({
    required this.onSendToEstimate,
    required this.productivityController,
    this.settings = const AppSettings(),
    this.onSettingsChanged,
    super.key,
  });

  final Future<void> Function(EstimateItemDraft draft) onSendToEstimate;
  final ProductivityController productivityController;
  final AppSettings settings;
  final ValueChanged<AppSettings>? onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('建築・土木系計算')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _CalculationTile(
              key: const Key('openEarthworkCalculation'),
              icon: Icons.landscape_outlined,
              title: '土量計算',
              subtitle: '掘削・埋戻し・搬出土・運搬回数',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EarthworkCalculationScreen(
                    onSendToEstimate: onSendToEstimate,
                    settings: settings,
                    onSettingsChanged: onSettingsChanged,
                  ),
                ),
              ),
            ),
            _CalculationTile(
              key: const Key('openWeightCalculation'),
              icon: Icons.scale_outlined,
              title: '比重・重量計算',
              subtitle: '材料と体積から重量を算出',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WeightCalculationScreen(
                    onSendToEstimate: onSendToEstimate,
                  ),
                ),
              ),
            ),
            _CalculationTile(
              key: const Key('openSlopeCalculation'),
              icon: Icons.show_chart,
              title: '勾配計算',
              subtitle: '高さ・水平距離・法長・角度を算出',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SlopeCalculationScreen(settings: settings),
                ),
              ),
            ),
            const _CalculationTile(
              icon: Icons.compare_arrows_outlined,
              title: '対比計算',
              subtitle: '今後追加',
            ),
            _CalculationTile(
              key: const Key('openAreaCalculation'),
              icon: Icons.square_foot_outlined,
              title: '面積計算',
              subtitle: '4辺と対角線から面積を算出',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => QuadrilateralAreaScreen(
                    onSendToEstimate: onSendToEstimate,
                  ),
                ),
              ),
            ),
            _CalculationTile(
              key: const Key('openProductivityCalculation'),
              icon: Icons.groups_outlined,
              title: '歩掛・生産性計算',
              subtitle: '必要人工・必要日数・施工実績を計算',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProductivityCalculationScreen(
                    controller: productivityController,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculationTile extends StatelessWidget {
  const _CalculationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          minTileHeight: 72,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right),
          enabled: onTap != null,
          onTap: onTap,
        ),
      ),
    );
  }
}
