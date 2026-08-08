import 'package:flutter/material.dart';

enum CalculatorSideMenuDestination {
  settings,
  help,
  prime,
  ultimate,
  constructionCalculations,
  unitConversion,
  instantEstimate,
  unitPriceMaster,
  productivityMaster,
}

class CalculatorSideMenu extends StatelessWidget {
  const CalculatorSideMenu({required this.onSelected, super.key});

  final ValueChanged<CalculatorSideMenuDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      child: SafeArea(
        child: ListView(
          key: const Key('calculatorSideMenu'),
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _MenuTile(
              key: const Key('sideMenuSettings'),
              icon: Icons.settings_outlined,
              label: '設定',
              onTap: () => onSelected(CalculatorSideMenuDestination.settings),
            ),
            _MenuTile(
              key: const Key('sideMenuHelp'),
              icon: Icons.help_outline,
              label: 'ヘルプ',
              onTap: () => onSelected(CalculatorSideMenuDestination.help),
            ),
            _MenuTile(
              key: const Key('sideMenuPrime'),
              icon: Icons.block_outlined,
              label: 'プライム（広告非表示）',
              onTap: () => onSelected(CalculatorSideMenuDestination.prime),
            ),
            _MenuTile(
              key: const Key('sideMenuUltimate'),
              icon: Icons.workspace_premium_outlined,
              label: 'アルティメット',
              onTap: () => onSelected(CalculatorSideMenuDestination.ultimate),
            ),
            const Divider(height: 24),
            _MenuTile(
              key: const Key('sideMenuConstructionCalculations'),
              icon: Icons.engineering_outlined,
              label: '便利計算一覧',
              onTap: () => onSelected(
                CalculatorSideMenuDestination.constructionCalculations,
              ),
            ),
            _MenuTile(
              key: const Key('sideMenuUnitConversion'),
              icon: Icons.swap_horiz_outlined,
              label: '単位変換',
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.unitConversion),
            ),
            _MenuTile(
              key: const Key('sideMenuInstantEstimate'),
              icon: Icons.request_quote_outlined,
              label: 'インスタント見積',
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.instantEstimate),
            ),
            const Divider(height: 24),
            _MenuTile(
              key: const Key('sideMenuUnitPriceMaster'),
              icon: Icons.price_change_outlined,
              label: '単価マスタ',
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.unitPriceMaster),
            ),
            _MenuTile(
              key: const Key('sideMenuProductivityMaster'),
              icon: Icons.analytics_outlined,
              label: '歩掛・生産性マスタ',
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.productivityMaster),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                key: const Key('sideMenuAdArea'),
                constraints: const BoxConstraints(minHeight: 82),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '広告エリア',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Version 1.0.0',
              key: const Key('sideMenuVersion'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 54,
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
