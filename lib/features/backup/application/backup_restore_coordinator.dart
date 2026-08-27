import 'dart:convert';

import '../../calculator/data/calculation_history_store.dart';
import '../../estimate/data/estimate_item_store.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../../productivity/data/productivity_record_store.dart';
import '../../settings/data/app_settings_store.dart';
import '../../settings/domain/app_settings.dart';
import '../data/backup_restore_journal_store.dart';
import '../domain/backup_restore_journal.dart';
import '../domain/backup_snapshot.dart';
import 'backup_snapshot_factory.dart';

enum RestoreRecoveryResult { none, rolledBack, rollbackFailed }

class BackupRestoreRolledBackException implements Exception {
  const BackupRestoreRolledBackException(this.cause);
  final Object cause;
}

class BackupRestoreRollbackFailedException implements Exception {
  const BackupRestoreRollbackFailedException(this.restoreError, this.cause);
  final Object restoreError;
  final Object cause;
}

class BackupRestoreCoordinator {
  const BackupRestoreCoordinator({
    required this.snapshotFactory,
    required this.settingsStore,
    required this.historyStore,
    required this.estimateStore,
    required this.productivityStore,
    required this.onboardingPreferences,
    required this.journalStore,
    this.now = DateTime.now,
  });

  final BackupSnapshotFactory snapshotFactory;
  final AppSettingsStore settingsStore;
  final CalculationHistoryStore historyStore;
  final EstimateItemStore estimateStore;
  final ProductivityRecordStore productivityStore;
  final OnboardingPreferences onboardingPreferences;
  final BackupRestoreJournalStore journalStore;
  final DateTime Function() now;

  Future<AppSettings> restore(BackupSnapshot incoming) async {
    // Re-run the strict validator before any persistent write.
    final validated = BackupSnapshot.decode(incoming.encode(pretty: false));
    final previousSettings = await settingsStore.load();
    final previous = await snapshotFactory.create(previousSettings);
    var journal = BackupRestoreJournal(
      phase: BackupRestoreJournalPhase.prepared,
      createdAt: now().toUtc(),
      previous: previous,
      incoming: validated,
    );
    await journalStore.save(journal);
    journal = journal.copyWith(phase: BackupRestoreJournalPhase.applying);
    await journalStore.save(journal);

    try {
      await _apply(validated.data);
      await _verify(validated.data);
      await journalStore.save(
        journal.copyWith(phase: BackupRestoreJournalPhase.committed),
      );
    } catch (restoreError) {
      try {
        await _apply(previous.data);
        await _verify(previous.data);
        await journalStore.clear();
      } catch (rollbackError) {
        throw BackupRestoreRollbackFailedException(restoreError, rollbackError);
      }
      throw BackupRestoreRolledBackException(restoreError);
    }
    try {
      await journalStore.clear();
    } catch (_) {
      // A committed journal is harmless and will be cleared on next launch.
    }
    return validated.data.settings;
  }

  Future<RestoreRecoveryResult> recoverInterruptedRestore() async {
    final journal = await journalStore.load();
    if (journal == null) return RestoreRecoveryResult.none;
    if (journal.phase == BackupRestoreJournalPhase.prepared ||
        journal.phase == BackupRestoreJournalPhase.committed) {
      try {
        await journalStore.clear();
      } catch (_) {
        // No user data is in a partially-applied state in these phases.
      }
      return RestoreRecoveryResult.none;
    }
    try {
      await _apply(journal.previous.data);
      await _verify(journal.previous.data);
      await journalStore.clear();
      return RestoreRecoveryResult.rolledBack;
    } catch (_) {
      // Keep the journal so the next launch or support-assisted recovery can
      // retry from the same known previous snapshot.
      return RestoreRecoveryResult.rollbackFailed;
    }
  }

  Future<void> _apply(BackupData data) async {
    await settingsStore.save(data.settings);
    await onboardingPreferences.saveOccupation(data.occupation.storageKey);
    final preferences = onboardingPreferences;
    if (preferences is LanguageOnboardingPreferences) {
      await (preferences as LanguageOnboardingPreferences).saveLanguage(
        data.settings.language.name,
      );
    }
    await historyStore.save(data.calculatorHistory);
    await estimateStore.save(data.estimateWorkspace);
    await productivityStore.save(data.productivityRecords);
  }

  Future<void> _verify(BackupData expected) async {
    final settings = await settingsStore.load();
    final actual = await snapshotFactory.create(settings);
    if (jsonEncode(actual.data.toJson()) != jsonEncode(expected.toJson())) {
      throw StateError('Restored data did not match the validated snapshot.');
    }
  }
}
