import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../settings/domain/app_settings.dart';
import '../application/backup_file_export.dart';
import '../application/backup_snapshot_factory.dart';
import '../domain/backup_snapshot.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    required this.snapshotFactory,
    required this.settings,
    this.shareBytes = shareBackupBytes,
    super.key,
  });

  final BackupSnapshotFactory snapshotFactory;
  final AppSettings settings;
  final BackupBytesSharer shareBytes;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late Future<BackupSnapshot> _snapshot = _loadSnapshot();
  bool _sharing = false;

  Future<BackupSnapshot> _loadSnapshot() {
    return widget.snapshotFactory.create(widget.settings);
  }

  Future<void> _export() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final strings = AppLocalizations.of(context);
    BackupSnapshot snapshot;
    try {
      snapshot = await widget.snapshotFactory.create(widget.settings);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharing = false);
      _showMessage(strings.backupGenerationFailed);
      return;
    }
    final document = buildBackupExportDocument(snapshot);
    if (!mounted) return;
    try {
      final box = context.findRenderObject() as RenderBox?;
      await widget.shareBytes(
        bytes: document.bytes,
        fileName: document.fileName,
        subject: strings.backupShareSubject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(strings.backupShareFailed);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('backupScreen'),
      appBar: AppBar(title: Text(strings.dataBackup)),
      body: SafeArea(
        child: FutureBuilder<BackupSnapshot>(
          future: _snapshot,
          builder: (context, state) {
            if (state.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.hasError || !state.hasData) {
              return _BackupLoadError(
                message: strings.backupGenerationFailed,
                retryLabel: strings.retry,
                onRetry: () => setState(() => _snapshot = _loadSnapshot()),
              );
            }
            final snapshot = state.data!;
            return ListView(
              key: const Key('backupContentList'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(strings.backupSensitiveDataNotice),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  strings.backupContents,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _CountTile(
                        icon: Icons.request_quote_outlined,
                        label: strings.backupEstimateCount(
                          snapshot.data.estimateWorkspace.estimates.length,
                        ),
                      ),
                      const Divider(height: 1),
                      _CountTile(
                        icon: Icons.price_change_outlined,
                        label: strings.backupUnitPriceCount(
                          snapshot
                              .data
                              .estimateWorkspace
                              .unitPriceMasters
                              .length,
                        ),
                      ),
                      const Divider(height: 1),
                      _CountTile(
                        icon: Icons.history_outlined,
                        label: strings.backupHistoryCount(
                          snapshot.data.calculatorHistory.length,
                        ),
                      ),
                      const Divider(height: 1),
                      _CountTile(
                        icon: Icons.analytics_outlined,
                        label: strings.backupProductivityCount(
                          snapshot.data.productivityRecords.length,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('exportBackupButton'),
                  onPressed: _sharing ? null : _export,
                  icon: _sharing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                  label: Text(strings.exportBackup),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label));
  }
}

class _BackupLoadError extends StatelessWidget {
  const _BackupLoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
