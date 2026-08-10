import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/technical_term_info.dart';
import '../../advertising/presentation/google_mobile_ads_banner.dart';

enum CalculatorSideMenuDestination {
  settings,
  help,
  adFree,
  full,
  constructionCalculations,
  unitConversion,
  instantEstimate,
  unitPriceMaster,
  productivityMaster,
}

class CalculatorSideMenu extends StatelessWidget {
  const CalculatorSideMenu({
    required this.onSelected,
    required this.showAds,
    this.enableGoogleMobileAds = false,
    super.key,
  });

  final ValueChanged<CalculatorSideMenuDestination> onSelected;
  final bool showAds;
  final bool enableGoogleMobileAds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

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
              label: strings.settings,
              onTap: () => onSelected(CalculatorSideMenuDestination.settings),
            ),
            _MenuTile(
              key: const Key('sideMenuHelp'),
              icon: Icons.help_outline,
              label: strings.help,
              onTap: () => onSelected(CalculatorSideMenuDestination.help),
            ),
            _MenuTile(
              key: const Key('sideMenuAdFree'),
              icon: Icons.block_outlined,
              label: strings.adFreePlan,
              onTap: () => onSelected(CalculatorSideMenuDestination.adFree),
            ),
            _MenuTile(
              key: const Key('sideMenuFull'),
              icon: Icons.workspace_premium_outlined,
              label: strings.fullPlan,
              onTap: () => onSelected(CalculatorSideMenuDestination.full),
            ),
            const Divider(height: 24),
            _MenuTile(
              key: const Key('sideMenuConstructionCalculations'),
              icon: Icons.engineering_outlined,
              label: strings.convenientCalculations,
              onTap: () => onSelected(
                CalculatorSideMenuDestination.constructionCalculations,
              ),
            ),
            _MenuTile(
              key: const Key('sideMenuUnitConversion'),
              icon: Icons.swap_horiz_outlined,
              label: strings.unitConversion,
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.unitConversion),
            ),
            _MenuTile(
              key: const Key('sideMenuInstantEstimate'),
              icon: Icons.request_quote_outlined,
              label: strings.instantEstimate,
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.instantEstimate),
            ),
            const Divider(height: 24),
            _MenuTile(
              key: const Key('sideMenuUnitPriceMaster'),
              icon: Icons.price_change_outlined,
              label: strings.unitPriceMaster,
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.unitPriceMaster),
            ),
            _MenuTile(
              key: const Key('sideMenuProductivityMaster'),
              icon: Icons.analytics_outlined,
              label: strings.productivityMaster,
              infoTitle: strings.isEnglish
                  ? strings.productivityTermTitle
                  : null,
              infoExplanation: strings.isEnglish
                  ? strings.productivityTermExplanation
                  : null,
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.productivityMaster),
            ),
            const Divider(height: 24),
            if (showAds)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: enableGoogleMobileAds ? 8 : 16,
                ),
                child: _SideMenuAdArea(
                  enableGoogleMobileAds: enableGoogleMobileAds,
                  label: strings.adArea,
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

class _SideMenuAdArea extends StatelessWidget {
  const _SideMenuAdArea({
    required this.enableGoogleMobileAds,
    required this.label,
  });

  final bool enableGoogleMobileAds;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = enableGoogleMobileAds ? 250.0 : 82.0;
    final fallback = Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (!enableGoogleMobileAds) {
      return KeyedSubtree(key: const Key('sideMenuAdArea'), child: fallback);
    }

    return GoogleMobileAdsBanner(
      key: const Key('sideMenuAdArea'),
      height: height,
      format: GoogleMobileAdsBannerFormat.mediumRectangle,
      fallback: fallback,
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.infoTitle,
    this.infoExplanation,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? infoTitle;
  final String? infoExplanation;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 54,
      leading: Icon(icon),
      title: Row(
        children: [
          Flexible(child: Text(label)),
          if (infoTitle != null && infoExplanation != null)
            TechnicalTermInfo(title: infoTitle!, explanation: infoExplanation!),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
