import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/app/app.dart';
import 'package:instant_estimate/core/domain/angle_unit.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/backup/application/backup_file_import.dart';
import 'package:instant_estimate/features/backup/application/backup_restore_coordinator.dart';
import 'package:instant_estimate/features/backup/application/backup_snapshot_factory.dart';
import 'package:instant_estimate/features/backup/data/backup_restore_journal_store.dart';
import 'package:instant_estimate/features/backup/domain/backup_restore_journal.dart';
import 'package:instant_estimate/features/backup/domain/backup_snapshot.dart';
import 'package:instant_estimate/features/backup/presentation/backup_screen.dart';
import 'package:instant_estimate/features/calculator/data/calculation_history_store.dart';
import 'package:instant_estimate/features/density/domain/weight_calculator.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_document.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_workspace.dart';
import 'package:instant_estimate/features/estimate/domain/unit_price_master.dart';
import 'package:instant_estimate/features/onboarding/data/onboarding_preferences.dart';
import 'package:instant_estimate/features/onboarding/domain/occupation.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/application/productivity_controller.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_record.dart';
import 'package:instant_estimate/features/settings/data/app_settings_store.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';
import 'package:instant_estimate/features/subscription/data/app_access_state_store.dart';
import 'package:instant_estimate/features/subscription/domain/app_access_state.dart';

void main() {
  group('backup file import', () {
    test('size→bytes→UTF-8→JSON→format→version→Validatorで読み込む', () async {
      final snapshot = _snapshot('incoming', estimateCount: 2);
      final file = XFile.fromData(
        snapshot.encodeUtf8(),
        name: 'valid.genbacalc',
        mimeType: 'application/json',
      );
      final restored = await readBackupFile(file);
      expect(restored.data.toJson(), snapshot.data.toJson());
    });

    test('拡張子なしはformatで判定し、別拡張子は拒否する', () async {
      final bytes = _snapshot('incoming').encodeUtf8();
      expect(
        (await readBackupFile(
          XFile.fromData(bytes, name: 'backup'),
        )).data.toJson(),
        _snapshot('incoming').data.toJson(),
      );
      await expectLater(
        readBackupFile(XFile('/tmp/backup.json', bytes: bytes)),
        throwsA(
          isA<BackupImportException>().having(
            (error) => error.failure,
            'failure',
            BackupImportFailure.wrongFileType,
          ),
        ),
      );
    });

    test('Android pickerがoctet-streamを.binへ変えても内容検証へ進む', () async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);
      final snapshot = _snapshot('incoming');
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'genbacalc-android-bin-test-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final binaryFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}backup.bin',
      );
      await binaryFile.writeAsBytes(snapshot.encodeUtf8(), flush: true);

      final restored = await readBackupFile(
        XFile(binaryFile.path, mimeType: 'application/octet-stream'),
      );

      expect(restored.data.toJson(), snapshot.data.toJson());
    });

    test('Androidでも通常の別拡張子と偽装された.binは拒否する', () async {
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);
      final bytes = _snapshot('incoming').encodeUtf8();
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'genbacalc-android-rejection-test-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final jsonFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}backup.json',
      );
      final disguisedBinaryFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}backup.bin',
      );
      await jsonFile.writeAsBytes(bytes, flush: true);
      await disguisedBinaryFile.writeAsBytes(bytes, flush: true);

      for (final file in <XFile>[
        XFile(jsonFile.path, mimeType: 'application/json'),
        XFile(disguisedBinaryFile.path, mimeType: 'application/json'),
      ]) {
        await expectLater(
          readBackupFile(file),
          throwsA(
            isA<BackupImportException>().having(
              (error) => error.failure,
              'failure',
              BackupImportFailure.wrongFileType,
            ),
          ),
        );
      }
    });

    test('ローカルパスとiOS管理下へコピー済み相当のパスから読み込める', () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'genbacalc-import-test-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final snapshot = _snapshot('incoming');
      final localFile = File('${temporaryDirectory.path}/local.genbacalc');
      await localFile.writeAsBytes(snapshot.encodeUtf8(), flush: true);
      expect(
        (await readBackupFile(XFile(localFile.path))).data.toJson(),
        snapshot.data.toJson(),
      );

      final managedImportDirectory = Directory(
        '${temporaryDirectory.path}/file-selector-imports/import-id',
      );
      await managedImportDirectory.create(recursive: true);
      final importedFile = File(
        '${managedImportDirectory.path}/icloud.genbacalc',
      );
      await importedFile.writeAsBytes(snapshot.encodeUtf8(), flush: true);
      expect(
        (await readBackupFile(XFile(importedFile.path))).data.toJson(),
        snapshot.data.toJson(),
      );
    });

    test('0 byteと存在しないパスの読込失敗を分類する', () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'genbacalc-empty-test-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final emptyFile = File('${temporaryDirectory.path}/empty.genbacalc');
      await emptyFile.writeAsBytes(const <int>[]);
      await expectLater(
        readBackupFile(XFile(emptyFile.path)),
        throwsA(
          isA<BackupImportException>().having(
            (error) => error.failure,
            'failure',
            BackupImportFailure.malformedJson,
          ),
        ),
      );
      await expectLater(
        readBackupFile(XFile('${temporaryDirectory.path}/missing.genbacalc')),
        throwsA(
          isA<BackupImportException>().having(
            (error) => error.failure,
            'failure',
            BackupImportFailure.readFailed,
          ),
        ),
      );
    });

    test('20MB超過・UTF-8不正・JSON破損・別format・未来versionを分類する', () async {
      Future<void> expectFailure(XFile file, BackupImportFailure failure) =>
          expectLater(
            readBackupFile(file),
            throwsA(
              isA<BackupImportException>().having(
                (error) => error.failure,
                'failure',
                failure,
              ),
            ),
          );

      await expectFailure(
        XFile.fromData(
          Uint8List(maximumBackupFileBytes + 1),
          name: 'large.genbacalc',
        ),
        BackupImportFailure.tooLarge,
      );
      await expectFailure(
        XFile.fromData(Uint8List.fromList([0xC3, 0x28]), name: 'bad.genbacalc'),
        BackupImportFailure.invalidUtf8,
      );
      await expectFailure(
        XFile.fromData(utf8.encode('{'), name: 'bad.genbacalc'),
        BackupImportFailure.malformedJson,
      );
      final wrong =
          jsonDecode(_snapshot('incoming').encode()) as Map<String, dynamic>;
      wrong['format'] = 'another.app';
      await expectFailure(
        XFile.fromData(utf8.encode(jsonEncode(wrong)), name: 'bad.genbacalc'),
        BackupImportFailure.wrongFormat,
      );
      final future =
          jsonDecode(_snapshot('incoming').encode()) as Map<String, dynamic>;
      future['backupVersion'] = 2;
      await expectFailure(
        XFile.fromData(utf8.encode(jsonEncode(future)), name: 'bad.genbacalc'),
        BackupImportFailure.unsupportedVersion,
      );
    });
  });

  group('atomic restore', () {
    test('restore journalはpreviousとincomingを厳密に永続化できる', () {
      final journal = BackupRestoreJournal(
        phase: BackupRestoreJournalPhase.applying,
        createdAt: DateTime.utc(2026, 8, 27),
        previous: _snapshot('previous'),
        incoming: _snapshot('incoming'),
      );
      final decoded = BackupRestoreJournal.decode(journal.encode());
      expect(decoded.phase, BackupRestoreJournalPhase.applying);
      expect(decoded.previous.toJson(), journal.previous.toJson());
      expect(decoded.incoming.toJson(), journal.incoming.toJson());
    });

    test('正規バックアップを設定・業種・全Storeへ完全復元する', () async {
      final harness = _Harness(previous: _snapshot('previous'));
      final incoming = _snapshot('incoming', estimateCount: 6, itemCount: 3);
      final accessStore = _AccessStateStore(
        const AppAccessState(
          plan: AppAccessPlan.full,
          rewardedAccessDay: '2026-08-27',
          rewardedAccessGroups: ['estimate'],
        ),
      );
      final accessStateBefore = (await accessStore.load()).toJson();

      final settings = await harness.coordinator.restore(incoming);

      expect(settings.toJson(), incoming.data.settings.toJson());
      expect(harness.currentData(), incoming.data.toJson());
      expect(harness.journal.value, isNull);
      expect(harness.journal.savedPhases, const [
        BackupRestoreJournalPhase.prepared,
        BackupRestoreJournalPhase.applying,
        BackupRestoreJournalPhase.committed,
      ]);
      expect(
        harness.preferences.language,
        incoming.data.settings.language.name,
      );
      expect((await accessStore.load()).toJson(), accessStateBefore);
      expect(accessStore.saveCalls, 0);
      expect(harness.estimate.workspace.estimates, hasLength(6));
    });

    test('空バックアップも有効で全対象を空へ置換する', () async {
      final harness = _Harness(previous: _snapshot('previous'));
      final empty = _snapshot('empty', empty: true);
      await harness.coordinator.restore(empty);
      expect(harness.currentData(), empty.data.toJson());
    });

    test('大量バックアップを削除・並べ替えせず復元する', () async {
      final harness = _Harness(previous: _snapshot('previous'));
      final large = _snapshot(
        'large',
        estimateCount: 100,
        itemCount: 20,
        unitPriceMasterCount: 11,
        productivityRecordCount: 6,
      );
      await harness.coordinator.restore(large);
      expect(harness.estimate.workspace.estimates, hasLength(100));
      expect(harness.estimate.workspace.estimates.first.items, hasLength(20));
      expect(harness.estimate.workspace.unitPriceMasters, hasLength(11));
      expect(harness.productivity.records, hasLength(6));
      expect(
        harness.estimate.workspace.activeEstimateId,
        large.data.estimateWorkspace.activeEstimateId,
      );
      expect(harness.currentData(), large.data.toJson());

      final estimates = EstimateController(store: harness.estimate);
      final productivity = ProductivityController(store: harness.productivity);
      await estimates.load();
      await productivity.load();
      expect(estimates.canCreateEstimate, isFalse);
      expect(estimates.canAddUnitPriceMaster, isFalse);
      expect(productivity.canAdd, isFalse);

      while (estimates.estimates.length >= estimates.estimateLimit!) {
        await estimates.deleteEstimate(estimates.estimates.last.info.id);
      }
      expect(estimates.canCreateEstimate, isTrue);
      await estimates.deleteUnitPriceMaster(estimates.unitPriceMasters.last.id);
      expect(estimates.canAddUnitPriceMaster, isFalse);
      await estimates.deleteUnitPriceMaster(estimates.unitPriceMasters.last.id);
      expect(estimates.canAddUnitPriceMaster, isTrue);
      await productivity.delete(productivity.records.last.id);
      expect(productivity.canAdd, isFalse);
      await productivity.delete(productivity.records.last.id);
      expect(productivity.canAdd, isTrue);
    });

    test('各保存段階の単発障害でpreviousへ完全rollbackする', () async {
      for (var failAt = 1; failAt <= 6; failAt++) {
        final previous = _snapshot('previous');
        final harness = _Harness(
          previous: previous,
          injector: _FaultInjector({failAt}),
        );
        await expectLater(
          harness.coordinator.restore(_snapshot('incoming')),
          throwsA(isA<BackupRestoreRolledBackException>()),
          reason: 'save stage $failAt',
        );
        expect(
          harness.currentData(),
          previous.data.toJson(),
          reason: 'save stage $failAt',
        );
        expect(harness.journal.value, isNull);
      }
    });

    test('rollbackも失敗した場合はapplying journalを保持する', () async {
      final harness = _Harness(
        previous: _snapshot('previous'),
        injector: _FaultInjector({3, 4}),
      );
      await expectLater(
        harness.coordinator.restore(_snapshot('incoming')),
        throwsA(isA<BackupRestoreRollbackFailedException>()),
      );
      expect(harness.journal.value?.phase, BackupRestoreJournalPhase.applying);
    });

    test('起動時にapplying journalを検出してpreviousへ戻す', () async {
      final previous = _snapshot('previous');
      final incoming = _snapshot('incoming');
      final harness = _Harness(previous: incoming);
      harness.journal.value = BackupRestoreJournal(
        phase: BackupRestoreJournalPhase.applying,
        createdAt: DateTime.utc(2026, 8, 27),
        previous: previous,
        incoming: incoming,
      );

      expect(
        await harness.coordinator.recoverInterruptedRestore(),
        RestoreRecoveryResult.rolledBack,
      );
      expect(harness.currentData(), previous.data.toJson());
      expect(harness.journal.value, isNull);
    });

    test('rollback失敗時はjournalを消さず以降の自動書換えを止める', () async {
      final previous = _snapshot('previous');
      final incoming = _snapshot('incoming');
      final harness = _Harness(
        previous: incoming,
        injector: _FaultInjector({1}),
      );
      harness.journal.value = BackupRestoreJournal(
        phase: BackupRestoreJournalPhase.applying,
        createdAt: DateTime.utc(2026, 8, 27),
        previous: previous,
        incoming: incoming,
      );
      expect(
        await harness.coordinator.recoverInterruptedRestore(),
        RestoreRecoveryResult.rollbackFailed,
      );
      expect(harness.journal.value, isNotNull);
    });

    testWidgets('アプリ起動時にapplying journalを自動rollbackして通知する', (tester) async {
      final previous = _snapshot('previous');
      final incoming = _snapshot('incoming');
      final harness = _Harness(previous: incoming);
      harness.journal.value = BackupRestoreJournal(
        phase: BackupRestoreJournalPhase.applying,
        createdAt: DateTime.utc(2026, 8, 27),
        previous: previous,
        incoming: incoming,
      );

      await tester.pumpWidget(
        InstantEstimateApp(
          onboardingPreferences: harness.preferences,
          calculationHistoryStore: harness.history,
          appSettingsStore: harness.settings,
          estimateItemStore: harness.estimate,
          productivityRecordStore: harness.productivity,
          backupRestoreCoordinator: harness.coordinator,
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.currentData(), previous.data.toJson());
      expect(harness.journal.value, isNull);
      expect(
        find.text(
          AppLocalizations(
            previous.data.settings.language,
          ).restoreInterruptedRolledBack,
        ),
        findsOneWidget,
      );
    });

    testWidgets('起動時rollback失敗ではjournalを保持して操作画面を開かない', (tester) async {
      final previous = _snapshot('previous');
      final incoming = _snapshot('incoming');
      final harness = _Harness(
        previous: incoming,
        injector: _FaultInjector({1}),
      );
      harness.journal.value = BackupRestoreJournal(
        phase: BackupRestoreJournalPhase.applying,
        createdAt: DateTime.utc(2026, 8, 27),
        previous: previous,
        incoming: incoming,
      );

      await tester.pumpWidget(
        InstantEstimateApp(
          onboardingPreferences: harness.preferences,
          calculationHistoryStore: harness.history,
          appSettingsStore: harness.settings,
          estimateItemStore: harness.estimate,
          productivityRecordStore: harness.productivity,
          backupRestoreCoordinator: harness.coordinator,
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.journal.value?.phase, BackupRestoreJournalPhase.applying);
      expect(
        find.text(
          AppLocalizations(
            incoming.data.settings.language,
          ).restoreRollbackFailed,
        ),
        findsOneWidget,
      );
      expect(find.byType(BackupScreen), findsNothing);
    });
  });

  group('restore UI', () {
    testWidgets('file pickerキャンセルでは保存データを変更しない', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = _Harness(previous: _snapshot('previous'));
      await tester.pumpWidget(
        MaterialApp(
          home: BackupScreen(
            snapshotFactory: harness.factory,
            settings: harness.settings.value,
            restoreCoordinator: harness.coordinator,
            onRestored: (_) async {},
            pickFile: () async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('restoreBackupButton')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('restoreBackupButton')));
      await tester.pumpAndSettle();
      expect(harness.injector.calls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('picker失敗では保存データを変更せず読込エラーを表示する', (tester) async {
      final harness = _Harness(previous: _snapshot('previous'));
      await tester.pumpWidget(
        MaterialApp(
          home: BackupScreen(
            snapshotFactory: harness.factory,
            settings: harness.settings.value,
            restoreCoordinator: harness.coordinator,
            onRestored: (_) async {},
            pickFile: () async => throw const BackupImportException(
              BackupImportFailure.pickerFailed,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('restoreBackupButton')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('restoreBackupButton')));
      await tester.pumpAndSettle();
      expect(harness.injector.calls, 0);
      expect(
        find.text(AppLocalizations(AppLanguage.japanese).backupReadFailed),
        findsOneWidget,
      );
    });

    testWidgets('確認キャンセルでは復元せず、小画面でもOverflowしない', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = _Harness(previous: _snapshot('previous'));
      final incoming = _snapshot('incoming');
      await tester.pumpWidget(
        MaterialApp(
          home: BackupScreen(
            snapshotFactory: harness.factory,
            settings: harness.settings.value,
            restoreCoordinator: harness.coordinator,
            onRestored: (_) async {},
            pickFile: () async =>
                XFile.fromData(incoming.encodeUtf8(), name: 'backup.genbacalc'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('restoreBackupButton')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('restoreBackupButton')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('backupRestorePreviewScreen')),
        findsOneWidget,
      );
      final strings = AppLocalizations(AppLanguage.japanese);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(
        find.text(
          strings.backupEstimateCount(
            incoming.data.estimateWorkspace.estimates.length,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(strings.registered), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('startRestoreButton')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('startRestoreButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirmRestoreButton')), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(harness.injector.calls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('復元完了後の件数再読込はFutureをsetStateから返さない', (tester) async {
      final harness = _Harness(previous: _snapshot('previous'));
      final incoming = _snapshot('incoming', estimateCount: 2);
      await tester.pumpWidget(
        MaterialApp(
          home: BackupScreen(
            snapshotFactory: harness.factory,
            settings: harness.settings.value,
            restoreCoordinator: harness.coordinator,
            onRestored: (_) async {},
            pickFile: () async =>
                XFile.fromData(incoming.encodeUtf8(), name: 'backup.genbacalc'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('restoreBackupButton')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('restoreBackupButton')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('startRestoreButton')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('startRestoreButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmRestoreButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('backupScreen')), findsOneWidget);
      expect(harness.currentData(), incoming.data.toJson());
      expect(tester.takeException(), isNull);
      expect(
        find.text(AppLocalizations(AppLanguage.japanese).restoreSucceeded),
        findsOneWidget,
      );
    });

    test('復元文言は8言語すべて直接取得できる', () {
      for (final language in AppLanguage.values) {
        final strings = AppLocalizations(language);
        expect(strings.restoreFromBackup, isNotEmpty);
        expect(strings.restoreReplacementWarning, isNotEmpty);
        expect(strings.restoreConfirmationBody, isNotEmpty);
        expect(strings.restoreRollbackFailed, isNotEmpty);
        expect(strings.helpRestoreBody, isNotEmpty);
      }
    });
  });
}

class _Harness {
  _Harness({required BackupSnapshot previous, _FaultInjector? injector})
    : injector = injector ?? _FaultInjector({}),
      settings = _SettingsStore(previous.data.settings),
      history = _HistoryStore(previous.data.calculatorHistory),
      estimate = _EstimateStore(previous.data.estimateWorkspace),
      productivity = _ProductivityStore(previous.data.productivityRecords),
      preferences = _Preferences(
        previous.data.occupation.storageKey,
        previous.data.settings.language.name,
      ) {
    settings.injector = this.injector;
    history.injector = this.injector;
    estimate.injector = this.injector;
    productivity.injector = this.injector;
    preferences.injector = this.injector;
    factory = BackupSnapshotFactory(
      historyStore: history,
      estimateStore: estimate,
      productivityStore: productivity,
      onboardingPreferences: preferences,
      now: () => DateTime.utc(2026, 8, 27, 12),
      appVersion: '1.0.0',
      buildNumber: '1',
    );
    coordinator = BackupRestoreCoordinator(
      snapshotFactory: factory,
      settingsStore: settings,
      historyStore: history,
      estimateStore: estimate,
      productivityStore: productivity,
      onboardingPreferences: preferences,
      journalStore: journal,
      now: () => DateTime.utc(2026, 8, 27, 12),
    );
  }

  final _FaultInjector injector;
  final _SettingsStore settings;
  final _HistoryStore history;
  final _EstimateStore estimate;
  final _ProductivityStore productivity;
  final _Preferences preferences;
  final _JournalStore journal = _JournalStore();
  late final BackupSnapshotFactory factory;
  late final BackupRestoreCoordinator coordinator;

  Map<String, Object?> currentData() => BackupData(
    occupation: Occupation.fromStoredValue(preferences.occupation)!,
    settings: settings.value,
    calculatorHistory: history.entries,
    estimateWorkspace: estimate.workspace,
    productivityRecords: productivity.records,
  ).toJson();
}

class _FaultInjector {
  _FaultInjector(this.failCalls);
  final Set<int> failCalls;
  int calls = 0;
  void hit() {
    calls++;
    if (failCalls.contains(calls)) throw StateError('failure $calls');
  }
}

class _SettingsStore implements AppSettingsStore {
  _SettingsStore(this.value);
  AppSettings value;
  late _FaultInjector injector;
  @override
  Future<AppSettings> load() async => value;
  @override
  Future<void> save(AppSettings settings) async {
    injector.hit();
    value = settings;
  }
}

class _HistoryStore implements CalculationHistoryStore {
  _HistoryStore(List<StoredCalculationHistoryEntry> value)
    : entries = List.of(value);
  List<StoredCalculationHistoryEntry> entries;
  late _FaultInjector injector;
  @override
  Future<List<StoredCalculationHistoryEntry>> load() async => List.of(entries);
  @override
  Future<void> save(List<StoredCalculationHistoryEntry> value) async {
    injector.hit();
    entries = List.of(value);
  }
}

class _EstimateStore implements EstimateItemStore {
  _EstimateStore(this.workspace);
  EstimateWorkspace workspace;
  late _FaultInjector injector;
  @override
  Future<EstimateWorkspace> load() async => workspace;
  @override
  Future<void> save(EstimateWorkspace value) async {
    injector.hit();
    workspace = value;
  }
}

class _ProductivityStore implements ProductivityRecordStore {
  _ProductivityStore(List<ProductivityRecord> value) : records = List.of(value);
  List<ProductivityRecord> records;
  late _FaultInjector injector;
  @override
  Future<List<ProductivityRecord>> load() async => List.of(records);
  @override
  Future<void> save(List<ProductivityRecord> value) async {
    injector.hit();
    records = List.of(value);
  }
}

class _Preferences
    implements OnboardingPreferences, LanguageOnboardingPreferences {
  _Preferences(this.occupation, this.language);
  String occupation;
  String language;
  late _FaultInjector injector;
  @override
  Future<bool> hasSelectedLanguage() async => true;
  @override
  Future<bool> hasSelectedOccupation() async => true;
  @override
  Future<String?> loadOccupation() async => occupation;
  @override
  Future<void> saveOccupation(String value) async {
    injector.hit();
    occupation = value;
  }

  @override
  Future<void> saveLanguage(String value) async {
    injector.hit();
    language = value;
  }
}

class _JournalStore implements BackupRestoreJournalStore {
  BackupRestoreJournal? value;
  final List<BackupRestoreJournalPhase> savedPhases = [];
  @override
  Future<BackupRestoreJournal?> load() async => value;
  @override
  Future<void> save(BackupRestoreJournal journal) async {
    savedPhases.add(journal.phase);
    value = journal;
  }

  @override
  Future<void> clear() async => value = null;
}

class _AccessStateStore implements AppAccessStateStore {
  _AccessStateStore(this.value);
  AppAccessState value;
  int saveCalls = 0;
  @override
  Future<AppAccessState> load() async => value;
  @override
  Future<void> save(AppAccessState state) async {
    saveCalls++;
    value = state;
  }
}

BackupSnapshot _snapshot(
  String prefix, {
  int estimateCount = 2,
  int itemCount = 2,
  int unitPriceMasterCount = 1,
  int productivityRecordCount = 1,
  bool empty = false,
}) {
  final estimates = empty
      ? <EstimateDocument>[]
      : [
          for (
            var estimateIndex = 0;
            estimateIndex < estimateCount;
            estimateIndex++
          )
            EstimateDocument(
              info: EstimateInfo(
                id: '$prefix-estimate-$estimateIndex',
                estimateName: '$prefix Estimate $estimateIndex',
                siteName: '',
                clientName: '',
                createdDate: DateTime.utc(2026, 8, 1),
                estimateNumber: '',
                notes: 'Notes',
                proviso: 'Proviso',
                validityPeriod: '30 days',
                constructionPeriod: '10 days',
                paymentTerms: 'Cash',
              ),
              items: [
                for (var itemIndex = 0; itemIndex < itemCount; itemIndex++)
                  EstimateItem(
                    id: '$prefix-item-$estimateIndex-$itemIndex',
                    createdAt: DateTime.utc(2026, 8, 1).add(
                      Duration(seconds: estimateIndex * itemCount + itemIndex),
                    ),
                    constructionSymbol: '①',
                    trade: 'Exterior',
                    constructionLocation: 'South',
                    name: 'Item $itemIndex',
                    specification: 'Specification',
                    quantity: 12.5,
                    unit: 'm',
                    unitPrice: 1000,
                    description: 'Description',
                    calculationBasis: 'Basis',
                    originalQuantity: 12.5,
                  ),
              ],
            ),
        ];
  final settings = AppSettings(
    language: prefix == 'previous' ? AppLanguage.japanese : AppLanguage.english,
    theme: prefix == 'previous'
        ? AppThemeSelection.light
        : AppThemeSelection.dark,
    decimalPlaces: 4,
    roundingMode: CalculatorRoundingMode.floor,
    estimateDecimalPlaces: 3,
    estimateRoundingMode: EstimateQuantityRoundingMode.ceiling,
    angleUnit: AngleUnit.radians,
    historySortOrder: HistorySortOrder.descending,
    calculatorTapSoundEnabled: false,
    calculatorHapticsEnabled: true,
    customTransportVehicles: const [
      TransportVehicle(
        id: 'truck',
        name: 'Truck',
        initialCapacityCubicMeters: 4,
        isCustom: true,
      ),
    ],
    customDensityMaterials: const [
      DensityMaterialPreset(name: 'Material', density: 2),
    ],
    companyProfile: CompanyProfile(companyName: '$prefix Company'),
  );
  return BackupSnapshot(
    createdAt: DateTime.utc(2026, 8, 27, 10),
    appVersion: '1.0.0',
    buildNumber: '1',
    data: BackupData(
      occupation: prefix == 'previous'
          ? Occupation.foundation
          : Occupation.exterior,
      settings: settings,
      calculatorHistory: empty
          ? const []
          : [
              StoredCalculationHistoryEntry(
                expression: '1+1',
                result: '2',
                decimalResult: '2',
                createdAt: DateTime.utc(2026, 8, 1),
              ),
            ],
      estimateWorkspace: EstimateWorkspace(
        activeEstimateId: estimates.isEmpty ? '' : estimates.last.info.id,
        estimates: estimates,
        unitPriceMasters: empty
            ? const []
            : [
                for (var index = 0; index < unitPriceMasterCount; index++)
                  UnitPriceMaster(
                    id: '$prefix-master-$index',
                    createdAt: DateTime.utc(2026, 8, 1),
                    trade: 'Exterior',
                    name: 'Master $index',
                    specification: 'Specification',
                    unit: 'm',
                    unitPrice: 2000,
                    description: 'Description',
                  ),
              ],
      ),
      productivityRecords: empty
          ? const []
          : [
              for (var index = 0; index < productivityRecordCount; index++)
                ProductivityRecord(
                  id: '$prefix-record-$index',
                  createdAt: DateTime.utc(2026, 8, 1),
                  trade: 'Exterior',
                  taskName: 'Task',
                  siteName: 'Site',
                  workDate: DateTime.utc(2026, 8, 1),
                  quantity: 10,
                  unit: 'm',
                  workers: 2,
                  workDays: 1,
                  actualWorkHours: 8,
                  actualLabor: 2,
                  standardLaborRate: 0.25,
                  standardProductivity: 4,
                  actualLaborRate: 0.2,
                  productivityPerLabor: 5,
                  totalPersonHours: 16,
                  hourlyProductivity: 0.625,
                  productivityDifferencePercent: 25,
                  conditions: 'Clear',
                ),
            ],
    ),
  );
}
