import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/backup/application/backup_snapshot_factory.dart';
import 'package:instant_estimate/features/backup/presentation/backup_screen.dart';
import 'package:instant_estimate/features/calculator/data/calculation_history_store.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_workspace.dart';
import 'package:instant_estimate/features/onboarding/data/onboarding_preferences.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_record.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('設定からバックアップ画面を開け、復元操作は表示しない', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        home: SettingsScreen(
          settings: const AppSettings(),
          onSettingsChanged: (_) {},
          onClearHistory: () async {},
          backupSnapshotFactory: _factory(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('dataBackupSetting')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('dataBackupSetting')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('backupScreen')), findsOneWidget);
    expect(find.byKey(const Key('exportBackupButton')), findsOneWidget);
    expect(find.textContaining('復元'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小画面で件数と注意文を表示し正式ファイルを共有する', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Uint8List? sharedBytes;
    String? sharedFileName;
    String? sharedSubject;

    await tester.pumpWidget(
      _app(
        home: BackupScreen(
          snapshotFactory: _factory(),
          settings: const AppSettings(),
          shareBytes:
              ({
                required Uint8List bytes,
                required String fileName,
                required String subject,
                Rect? sharePositionOrigin,
              }) async {
                sharedBytes = bytes;
                sharedFileName = fileName;
                sharedSubject = subject;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('見積：0件'), findsOneWidget);
    expect(find.text('単価マスタ：0件'), findsOneWidget);
    expect(find.text('計算履歴：0件'), findsOneWidget);
    expect(find.text('歩掛実績：0件'), findsOneWidget);
    expect(find.textContaining('会社情報'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('exportBackupButton')));
    await tester.tap(find.byKey(const Key('exportBackupButton')));
    await tester.pumpAndSettle();

    expect(sharedBytes, isNotNull);
    expect(sharedFileName, 'GenbaCalc_Backup_20260827_183000.genbacalc');
    expect(sharedSubject, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  test('バックアップ関連文言は8言語すべてに存在する', () {
    for (final language in AppLanguage.values) {
      final strings = AppLocalizations(language);
      expect(strings.dataBackup, isNotEmpty, reason: language.name);
      expect(strings.exportBackup, isNotEmpty, reason: language.name);
      expect(strings.backupContents, isNotEmpty, reason: language.name);
      expect(
        strings.backupSensitiveDataNotice,
        isNotEmpty,
        reason: language.name,
      );
      expect(
        strings.backupEstimateCount(2),
        contains('2'),
        reason: language.name,
      );
      expect(
        strings.backupUnitPriceCount(3),
        contains('3'),
        reason: language.name,
      );
      expect(
        strings.backupHistoryCount(4),
        contains('4'),
        reason: language.name,
      );
      expect(
        strings.backupProductivityCount(5),
        contains('5'),
        reason: language.name,
      );
      expect(strings.backupGenerationFailed, isNotEmpty, reason: language.name);
      expect(strings.backupShareFailed, isNotEmpty, reason: language.name);
      expect(strings.helpBackupTitle, isNotEmpty, reason: language.name);
      expect(strings.helpBackupBody, isNotEmpty, reason: language.name);
    }
  });
}

Widget _app({required Widget home}) {
  return MaterialApp(
    locale: const Locale('ja'),
    supportedLocales: const [Locale('ja')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

BackupSnapshotFactory _factory() => BackupSnapshotFactory(
  historyStore: _HistoryStore(),
  estimateStore: _EstimateStore(),
  productivityStore: _ProductivityStore(),
  onboardingPreferences: _OnboardingPreferences(),
  now: () => DateTime(2026, 8, 27, 18, 30),
  appVersion: '1.0.0',
  buildNumber: '1',
);

class _HistoryStore implements CalculationHistoryStore {
  @override
  Future<List<StoredCalculationHistoryEntry>> load() async => const [];
  @override
  Future<void> save(List<StoredCalculationHistoryEntry> entries) async {}
}

class _EstimateStore implements EstimateItemStore {
  @override
  Future<EstimateWorkspace> load() async =>
      const EstimateWorkspace(activeEstimateId: '', estimates: []);
  @override
  Future<void> save(EstimateWorkspace workspace) async {}
}

class _ProductivityStore implements ProductivityRecordStore {
  @override
  Future<List<ProductivityRecord>> load() async => const [];
  @override
  Future<void> save(List<ProductivityRecord> records) async {}
}

class _OnboardingPreferences implements OnboardingPreferences {
  @override
  Future<bool> hasSelectedOccupation() async => true;
  @override
  Future<String?> loadOccupation() async => 'exterior';
  @override
  Future<void> saveOccupation(String occupation) async {}
}
