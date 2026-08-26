import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('disclaimerScreen'),
      appBar: AppBar(title: Text(l10n.disclaimerTitle)),
      body: SafeArea(
        child: ListView(
          key: const Key('disclaimerList'),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              l10n.disclaimerBody,
              key: const Key('disclaimerBody'),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
