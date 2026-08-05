import 'package:flutter/material.dart';

import '../../area/presentation/quadrilateral_area_screen.dart';

class ConstructionCalculationsScreen extends StatelessWidget {
  const ConstructionCalculationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('建築・土木系計算')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _CalculationTile(
              key: const Key('openAreaCalculation'),
              icon: Icons.square_foot_outlined,
              title: '面積計算',
              subtitle: '4辺と対角線から面積を算出',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const QuadrilateralAreaScreen(),
                ),
              ),
            ),
            const _CalculationTile(
              icon: Icons.scale_outlined,
              title: '比重・重量計算',
              subtitle: '次の工程で追加',
            ),
            const _CalculationTile(
              icon: Icons.landscape_outlined,
              title: '土量計算',
              subtitle: '今後追加',
            ),
            const _CalculationTile(
              icon: Icons.show_chart,
              title: '勾配計算',
              subtitle: '今後追加',
            ),
            const _CalculationTile(
              icon: Icons.terrain_outlined,
              title: '法面計算',
              subtitle: '今後追加',
            ),
            const _CalculationTile(
              icon: Icons.groups_outlined,
              title: '歩掛・生産性',
              subtitle: '今後追加',
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
