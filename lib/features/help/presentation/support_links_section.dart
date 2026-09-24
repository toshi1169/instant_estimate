import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';

const supportUrl = 'https://matsumotoboundary.com/support/';
const supportPrivacyPolicyUrl = 'https://matsumotoboundary.com/privacy/';

typedef SupportLinkLauncher = Future<bool> Function(Uri uri);

class SupportLinksSection extends StatelessWidget {
  const SupportLinksSection({this.linkLauncher, super.key});

  final SupportLinkLauncher? linkLauncher;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.supportTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                key: const Key('supportContactLink'),
                leading: const Icon(Icons.support_agent_outlined),
                title: Text(strings.reportFeedbackAndIssues),
                subtitle: Text(strings.supportDescription),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openExternalUrl(context, Uri.parse(supportUrl)),
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('supportPrivacyPolicyLink'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(strings.privacyPolicy),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openExternalUrl(
                  context,
                  Uri.parse(supportPrivacyPolicyUrl),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened =
          await (linkLauncher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).externalLinkOpenFailed),
        ),
      );
    }
  }
}
