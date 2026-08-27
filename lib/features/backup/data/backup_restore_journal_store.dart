import 'package:flutter/services.dart';

import '../domain/backup_restore_journal.dart';

abstract interface class BackupRestoreJournalStore {
  Future<BackupRestoreJournal?> load();
  Future<void> save(BackupRestoreJournal journal);
  Future<void> clear();
}

class PlatformBackupRestoreJournalStore implements BackupRestoreJournalStore {
  static const _channel = MethodChannel(
    'jp.instant_estimate/backup_restore_journal',
  );

  @override
  Future<BackupRestoreJournal?> load() async {
    final encoded = await _channel.invokeMethod<String>('loadRestoreJournal');
    if (encoded == null || encoded.isEmpty) return null;
    return BackupRestoreJournal.decode(encoded);
  }

  @override
  Future<void> save(BackupRestoreJournal journal) {
    return _channel.invokeMethod<void>('saveRestoreJournal', <String, Object>{
      'journal': journal.encode(),
    });
  }

  @override
  Future<void> clear() {
    return _channel.invokeMethod<void>('clearRestoreJournal');
  }
}
