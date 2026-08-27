import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../settings/domain/app_settings.dart';
import '../application/backup_restore_coordinator.dart';
import '../domain/backup_snapshot.dart';

class BackupRestorePreviewScreen extends StatefulWidget {
  const BackupRestorePreviewScreen({
    required this.snapshot,
    required this.coordinator,
    required this.onRestored,
    super.key,
  });

  final BackupSnapshot snapshot;
  final BackupRestoreCoordinator coordinator;
  final Future<void> Function(AppSettings settings) onRestored;

  @override
  State<BackupRestorePreviewScreen> createState() =>
      _BackupRestorePreviewScreenState();
}

class _BackupRestorePreviewScreenState
    extends State<BackupRestorePreviewScreen> {
  bool _restoring = false;
  bool _blocked = false;

  Future<void> _confirmAndRestore() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.restoreConfirmationTitle),
        content: Text(strings.restoreConfirmationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: const Key('confirmRestoreButton'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.restoreNow),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _restoring = true);
    try {
      final settings = await widget.coordinator.restore(widget.snapshot);
      await widget.onRestored(settings);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on BackupRestoreRollbackFailedException {
      if (!mounted) return;
      setState(() {
        _restoring = false;
        _blocked = true;
      });
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(strings.restoreFailedTitle),
          content: Text(strings.restoreRollbackFailed),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.close),
            ),
          ],
        ),
      );
    } on BackupRestoreRolledBackException {
      if (!mounted) return;
      setState(() => _restoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.restoreFailedAndRolledBack)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _restoring = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.restoreSaveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final snapshot = widget.snapshot;
    final data = snapshot.data;
    final profile = data.settings.companyProfile;
    final hasProfile = profile.toJson().values.any(
      (value) => value is String && value.trim().isNotEmpty,
    );
    return PopScope(
      canPop: !_blocked,
      child: Scaffold(
        key: const Key('backupRestorePreviewScreen'),
        appBar: AppBar(
          automaticallyImplyLeading: !_blocked,
          title: Text(strings.restorePreviewTitle),
        ),
        body: SafeArea(
          child: _blocked
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.restoreRollbackFailed,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Semantics(
                      container: true,
                      liveRegion: true,
                      child: Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            strings.restoreReplacementWarning,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(strings.restoreDoesNotChangeAccess),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _PreviewTile(
                            label: strings.backupCreatedAt,
                            value: _formatDate(snapshot.createdAt.toLocal()),
                          ),
                          _PreviewTile(
                            label: strings.backupSourceVersion,
                            value:
                                '${snapshot.appVersion} (${snapshot.buildNumber})',
                          ),
                          _PreviewTile(
                            label: strings.backupEstimateCount(
                              data.estimateWorkspace.estimates.length,
                            ),
                          ),
                          _PreviewTile(
                            label: strings.backupUnitPriceCount(
                              data.estimateWorkspace.unitPriceMasters.length,
                            ),
                          ),
                          _PreviewTile(
                            label: strings.backupHistoryCount(
                              data.calculatorHistory.length,
                            ),
                          ),
                          _PreviewTile(
                            label: strings.backupProductivityCount(
                              data.productivityRecords.length,
                            ),
                          ),
                          _PreviewTile(
                            label: strings.mainOccupation,
                            value: strings.occupation(
                              data.occupation.legacyLabel,
                            ),
                          ),
                          _PreviewTile(
                            label: strings.companyProfile,
                            value: hasProfile
                                ? strings.registered
                                : strings.notRegistered,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      button: true,
                      label: strings.restoreNow,
                      child: FilledButton.icon(
                        key: const Key('startRestoreButton'),
                        onPressed: _restoring || _blocked
                            ? null
                            : _confirmAndRestore,
                        icon: _restoring
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.restore),
                        label: Text(
                          _restoring
                              ? strings.restoringBackup
                              : strings.restoreNow,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.label, this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: value == null ? null : Text(value!),
    );
  }
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}/${two(value.month)}/${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}
