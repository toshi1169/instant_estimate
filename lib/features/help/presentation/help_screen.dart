import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../advertising/domain/rewarded_ad_policy.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('helpScreen'),
      appBar: AppBar(title: Text(l10n.help)),
      body: SafeArea(
        child: ListView(
          key: const Key('helpList'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _HelpIntroCard(
              title: l10n.helpIntroTitle,
              body: l10n.helpIntroBody,
            ),
            const SizedBox(height: 14),
            _HelpSection(
              key: const Key('helpSectionCalculator'),
              icon: Icons.calculate_outlined,
              title: l10n.helpCalculatorTitle,
              body: l10n.helpCalculatorBody,
            ),
            _HelpSection(
              key: const Key('helpSectionFraction'),
              icon: Icons.safety_divider_outlined,
              title: l10n.helpFractionTitle,
              body: l10n.helpFractionBody,
            ),
            _HelpSection(
              key: const Key('helpSectionHistory'),
              icon: Icons.history_outlined,
              title: l10n.helpHistoryTitle,
              body: l10n.helpHistoryBody,
            ),
            _HelpSection(
              key: const Key('helpSectionConvenientCalculations'),
              icon: Icons.engineering_outlined,
              title: l10n.helpToolsTitle,
              body: l10n.helpToolsBody,
            ),
            _HelpSection(
              key: const Key('helpSectionEstimate'),
              icon: Icons.request_quote_outlined,
              title: l10n.helpEstimateTitle,
              body: l10n.helpEstimateBody,
            ),
            _HelpSection(
              key: const Key('helpSectionOutput'),
              icon: Icons.file_present_outlined,
              title: l10n.helpOutputTitle,
              body: l10n.helpOutputBody,
            ),
            _HelpSection(
              key: const Key('helpSectionRewardedAds'),
              icon: Icons.ondemand_video_outlined,
              title: l10n.helpRewardedAdsTitle,
              body: l10n.helpRewardedAdsBody(maximumDailyRewardedAds),
            ),
            _HelpSection(
              key: const Key('helpSectionData'),
              icon: Icons.storage_outlined,
              title: l10n.helpDataTitle,
              body: l10n.helpDataBody,
            ),
            _HelpSection(
              key: const Key('helpSectionBackup'),
              icon: Icons.backup_outlined,
              title: l10n.helpBackupTitle,
              body: l10n.helpBackupBody,
            ),
            _HelpSection(
              key: const Key('helpSectionRestore'),
              icon: Icons.restore,
              title: l10n.restoreFromBackup,
              body: l10n.helpRestoreBody,
            ),
            _HelpSection(
              key: const Key('helpSectionDisclaimer'),
              icon: Icons.gavel_outlined,
              title: l10n.disclaimerTitle,
              body: l10n.disclaimerBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpIntroCard extends StatelessWidget {
  const _HelpIntroCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.handyman_outlined,
              color: theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 10), child: Text(body)),
        ],
      ),
    );
  }
}
