import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads installed package metadata once for this view, without a build-time
/// version fallback that could display an old release number.
class InstalledAppVersion extends StatefulWidget {
  const InstalledAppVersion({this.loadVersion = _installedVersion, super.key});

  final Future<String> Function() loadVersion;

  static Future<String> _installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  @override
  State<InstalledAppVersion> createState() => _InstalledAppVersionState();
}

class _InstalledAppVersionState extends State<InstalledAppVersion> {
  late final Future<String> _version = Future.sync(widget.loadVersion);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: _version,
      builder: (context, snapshot) {
        final version = snapshot.data?.trim();
        return Text(
          'Version ${version == null || version.isEmpty ? '—' : version}',
          key: const Key('sideMenuVersion'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
