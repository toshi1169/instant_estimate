import 'package:flutter/material.dart';

import '../../../core/domain/app_access_plan.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/technical_term_info.dart';
import '../../advertising/domain/rewarded_ad_policy.dart';
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
    required this.accessPlan,
    this.isRewardedAdRequired,
    this.enableGoogleMobileAds = false,
    super.key,
  });

  final ValueChanged<CalculatorSideMenuDestination> onSelected;
  final bool showAds;
  final AppAccessPlan accessPlan;
  final bool Function(RewardedAdEntryPoint)? isRewardedAdRequired;
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
              subtitle: _adFreeStatus(accessPlan, strings),
              subtitleKey: const Key('sideMenuAdFreeStatus'),
              statusActive: accessPlan != AppAccessPlan.free,
              onTap: () => onSelected(CalculatorSideMenuDestination.adFree),
            ),
            _MenuTile(
              key: const Key('sideMenuFull'),
              icon: Icons.workspace_premium_outlined,
              label: strings.fullPlan,
              subtitle: _fullPlanStatus(accessPlan, strings),
              subtitleKey: const Key('sideMenuFullStatus'),
              statusActive: accessPlan == AppAccessPlan.full,
              onTap: () => onSelected(CalculatorSideMenuDestination.full),
            ),
            const Divider(height: 24),
            _MenuTile(
              key: const Key('sideMenuConstructionCalculations'),
              icon: Icons.engineering_outlined,
              label: strings.convenientCalculations,
              rewardedAdIconKey: const Key(
                'sideMenuRewardedAd-convenientCalculations',
              ),
              showRewardedAd:
                  isRewardedAdRequired?.call(
                    RewardedAdEntryPoint.convenientCalculation,
                  ) ??
                  false,
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
              rewardedAdIconKey: const Key(
                'sideMenuRewardedAd-estimateAndUnitPriceMaster',
              ),
              showRewardedAd:
                  isRewardedAdRequired?.call(
                    RewardedAdEntryPoint.instantEstimate,
                  ) ??
                  false,
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.instantEstimate),
            ),
            const Divider(height: 24),
            _MenuTile(
              key: const Key('sideMenuUnitPriceMaster'),
              icon: Icons.price_change_outlined,
              label: strings.unitPriceMaster,
              rewardedAdIconKey: const Key(
                'sideMenuRewardedAd-estimateAndUnitPriceMaster',
              ),
              showRewardedAd:
                  isRewardedAdRequired?.call(
                    RewardedAdEntryPoint.unitPriceMaster,
                  ) ??
                  false,
              onTap: () =>
                  onSelected(CalculatorSideMenuDestination.unitPriceMaster),
            ),
            _MenuTile(
              key: const Key('sideMenuProductivityMaster'),
              icon: Icons.analytics_outlined,
              label: strings.productivityMaster,
              infoTitle: !strings.isJapanese
                  ? strings.productivityTermTitle
                  : null,
              infoExplanation: !strings.isJapanese
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
    this.subtitle,
    this.subtitleKey,
    this.statusActive = false,
    this.showRewardedAd = false,
    this.rewardedAdIconKey,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? infoTitle;
  final String? infoExplanation;
  final String? subtitle;
  final Key? subtitleKey;
  final bool statusActive;
  final bool showRewardedAd;
  final Key? rewardedAdIconKey;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 54,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      horizontalTitleGap: 10,
      leading: Icon(icon),
      title: Row(
        children: [
          Flexible(child: Text(label)),
          if (infoTitle != null && infoExplanation != null)
            TechnicalTermInfo(title: infoTitle!, explanation: infoExplanation!),
        ],
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              key: subtitleKey,
              style: TextStyle(
                color: statusActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: statusActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRewardedAd) ...[
            ExcludeSemantics(
              child: Icon(
                Icons.videocam_outlined,
                key: rewardedAdIconKey,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

String _adFreeStatus(AppAccessPlan plan, AppLocalizations strings) =>
    switch (plan) {
      AppAccessPlan.free => strings.text('未購入'),
      AppAccessPlan.adFree => strings.text('購入済み'),
      AppAccessPlan.full => strings.text('完全版特典で有効'),
    };

String _fullPlanStatus(AppAccessPlan plan, AppLocalizations strings) =>
    plan == AppAccessPlan.full ? strings.text('契約中') : strings.text('未契約');
