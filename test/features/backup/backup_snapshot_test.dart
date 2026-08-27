import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/angle_unit.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/features/backup/application/backup_file_export.dart';
import 'package:instant_estimate/features/backup/application/backup_snapshot_factory.dart';
import 'package:instant_estimate/features/backup/domain/backup_snapshot.dart';
import 'package:instant_estimate/features/calculator/data/calculation_history_store.dart';
import 'package:instant_estimate/features/density/domain/weight_calculator.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_document.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_workspace.dart';
import 'package:instant_estimate/features/estimate/domain/unit_price_master.dart';
import 'package:instant_estimate/features/onboarding/data/onboarding_preferences.dart';
import 'package:instant_estimate/features/onboarding/domain/occupation.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/domain/productivity_record.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';

void main() {
  group('BackupSnapshot v1', () {
    test('空データをUTF-8 JSONへ変換して完全復元できる', () {
      final snapshot = _snapshot();
      final restored = BackupSnapshot.decode(snapshot.encode());

      expect(restored.toJson(), snapshot.toJson());
      expect(utf8.decode(snapshot.encodeUtf8()), snapshot.encode());
      expect(restored.createdAt.isUtc, isTrue);
      expect(restored.data.estimateWorkspace.estimates, isEmpty);
    });

    test('通常データとAppSettings・CompanyProfileを完全保持する', () {
      final snapshot = _snapshot(
        settings: _fullSettings,
        history: [_history(1)],
        workspace: _workspace(estimateCount: 2, itemCount: 3, masterCount: 2),
        records: [_record(1)],
      );
      final restored = BackupSnapshot.decode(snapshot.encode());

      expect(restored.data.settings.toJson(), _fullSettings.toJson());
      expect(
        restored.data.settings.companyProfile.toJson(),
        _fullSettings.companyProfile.toJson(),
      );
      expect(
        restored.data.estimateWorkspace.toJson(),
        snapshot.data.estimateWorkspace.toJson(),
      );
      expect(
        restored.data.calculatorHistory.map((e) => e.toJson()),
        snapshot.data.calculatorHistory.map((e) => e.toJson()),
      );
      expect(
        restored.data.productivityRecords.map((e) => e.toJson()),
        snapshot.data.productivityRecords.map((e) => e.toJson()),
      );
    });

    test('100見積と多数データを実用的なサイズで生成・検証できる', () {
      final stopwatch = Stopwatch()..start();
      final snapshot = _snapshot(
        history: [for (var i = 0; i < 500; i++) _history(i)],
        workspace: _workspace(
          estimateCount: 100,
          itemCount: 30,
          masterCount: 500,
        ),
        records: [for (var i = 0; i < 500; i++) _record(i)],
      );
      final encoded = snapshot.encode();
      final restored = BackupSnapshot.decode(encoded);
      stopwatch.stop();

      expect(restored.data.estimateWorkspace.estimates, hasLength(100));
      expect(
        restored.data.estimateWorkspace.estimates.expand(
          (estimate) => estimate.items,
        ),
        hasLength(3000),
      );
      expect(restored.data.estimateWorkspace.unitPriceMasters, hasLength(500));
      expect(restored.data.calculatorHistory, hasLength(500));
      expect(restored.data.productivityRecords, hasLength(500));
      expect(encoded.length, lessThan(10 * 1024 * 1024));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
    });

    test('format・未来version・壊れたJSON・必須値欠落を拒否する', () {
      final valid = _mutableJson(_snapshot());
      expect(
        () => BackupSnapshot.decode('{broken'),
        throwsA(isA<BackupValidationException>()),
      );

      final badFormat = _deepCopy(valid)..['format'] = 'other';
      expect(
        () => BackupSnapshot.fromJson(badFormat),
        throwsA(isA<BackupValidationException>()),
      );

      final future = _deepCopy(valid)..['backupVersion'] = 2;
      expect(
        () => BackupSnapshot.fromJson(future),
        throwsA(isA<UnsupportedBackupVersionException>()),
      );

      final missing = _deepCopy(valid)..remove('createdAt');
      expect(
        () => BackupSnapshot.fromJson(missing),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('不正日付・有限でない数値・未知フィールドを拒否する', () {
      final invalidDate = _mutableJson(_snapshot())..['createdAt'] = 'today';
      expect(
        () => BackupSnapshot.fromJson(invalidDate),
        throwsA(isA<BackupValidationException>()),
      );

      final invalidNumber = _mutableJson(
        _snapshot(workspace: _workspace(estimateCount: 1, itemCount: 1)),
      );
      final data = invalidNumber['data']! as Map<String, dynamic>;
      final workspace = data['estimateWorkspace']! as Map<String, dynamic>;
      final estimate =
          (workspace['estimates']! as List).first as Map<String, dynamic>;
      final item = (estimate['items']! as List).first as Map<String, dynamic>;
      item['quantity'] = double.nan;
      expect(
        () => BackupSnapshot.fromJson(invalidNumber),
        throwsA(isA<BackupValidationException>()),
      );

      final unknown = _mutableJson(_snapshot())..['unknown'] = true;
      expect(
        () => BackupSnapshot.fromJson(unknown),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('重複IDと無効activeEstimateIdを拒否する', () {
      final duplicate = _mutableJson(
        _snapshot(workspace: _workspace(estimateCount: 2, itemCount: 1)),
      );
      final data = duplicate['data']! as Map<String, dynamic>;
      final workspace = data['estimateWorkspace']! as Map<String, dynamic>;
      final estimates = workspace['estimates']! as List<dynamic>;
      final firstInfo =
          (estimates[0] as Map<String, dynamic>)['info']!
              as Map<String, dynamic>;
      final secondInfo =
          (estimates[1] as Map<String, dynamic>)['info']!
              as Map<String, dynamic>;
      secondInfo['id'] = firstInfo['id'];
      expect(
        () => BackupSnapshot.fromJson(duplicate),
        throwsA(isA<BackupValidationException>()),
      );

      final invalidActive = _mutableJson(
        _snapshot(workspace: _workspace(estimateCount: 1)),
      );
      final invalidData = invalidActive['data']! as Map<String, dynamic>;
      (invalidData['estimateWorkspace']!
              as Map<String, dynamic>)['activeEstimateId'] =
          'missing';
      expect(
        () => BackupSnapshot.fromJson(invalidActive),
        throwsA(isA<BackupValidationException>()),
      );
    });

    test('課金・Rewarded・端末固有状態をJSONへ出力しない', () {
      final encoded = _snapshot(settings: _fullSettings).encode();
      for (final forbidden in const [
        'appAccessState',
        'plan',
        'trialEndsAt',
        'lastVerifiedAt',
        'rewardedAccessDay',
        'rewardedAccessGroups',
        'receipt',
        'verificationData',
        'appLanguage',
        'themeMode',
      ]) {
        expect(encoded, isNot(contains('"$forbidden"')));
      }
    });

    test('ファイル名・拡張子・MIMEが正式仕様と一致する', () {
      final snapshot = _snapshot();
      final document = buildBackupExportDocument(snapshot);
      expect(document.fileName, 'GenbaCalc_Backup_20260827_183000.genbacalc');
      expect(genbaCalcBackupMimeType, 'application/json');
      expect(document.bytes, isNotEmpty);
    });
  });

  test('Factoryは正規化済みデータを読み取るだけで保存値を変更しない', () async {
    final historyStore = _HistoryStore([_history(1)]);
    final estimateStore = _EstimateStore(
      _workspace(estimateCount: 1, itemCount: 2, masterCount: 1),
    );
    final productivityStore = _ProductivityStore([_record(1)]);
    final onboarding = _OnboardingPreferences('外構');
    final before = <String, Object?>{
      'history': historyStore.entries.map((e) => e.toJson()).toList(),
      'workspace': estimateStore.workspace.toJson(),
      'records': productivityStore.records.map((e) => e.toJson()).toList(),
      'occupation': onboarding.value,
    };

    final snapshot = await BackupSnapshotFactory(
      historyStore: historyStore,
      estimateStore: estimateStore,
      productivityStore: productivityStore,
      onboardingPreferences: onboarding,
      now: () => DateTime(2026, 8, 27, 18, 30),
      appVersion: '1.0.0',
      buildNumber: '1',
    ).create(_fullSettings);

    expect(snapshot.data.occupation, Occupation.exterior);
    expect(historyStore.saveCalls, 0);
    expect(estimateStore.saveCalls, 0);
    expect(productivityStore.saveCalls, 0);
    expect(onboarding.saveCalls, 0);
    expect(<String, Object?>{
      'history': historyStore.entries.map((e) => e.toJson()).toList(),
      'workspace': estimateStore.workspace.toJson(),
      'records': productivityStore.records.map((e) => e.toJson()).toList(),
      'occupation': onboarding.value,
    }, before);
  });
}

final _fullSettings = AppSettings(
  language: AppLanguage.english,
  theme: AppThemeSelection.dark,
  decimalPlaces: 4,
  roundingMode: CalculatorRoundingMode.floor,
  estimateDecimalPlaces: 3,
  estimateRoundingMode: EstimateQuantityRoundingMode.ceiling,
  angleUnit: AngleUnit.radians,
  historySortOrder: HistorySortOrder.descending,
  confirmHistoryDeletion: false,
  calculatorTapSoundEnabled: false,
  calculatorHapticsEnabled: true,
  customTransportVehicles: const [
    TransportVehicle(
      id: 'custom-truck',
      name: 'Custom truck',
      initialCapacityCubicMeters: 4.5,
      maximumPayloadTons: 5,
      isCustom: true,
    ),
  ],
  customDensityMaterials: const [
    DensityMaterialPreset(name: 'Custom material', density: 2.1),
  ],
  companyProfile: const CompanyProfile(
    companyName: 'Matsumoto Boundary',
    representativeName: '松本太郎',
    postalCode: '〒123-4567',
    addressLine1: '東京都',
    addressLine2: '1-2-3',
    phoneNumber: '+81 90-1234-5678',
    displayOrder: [
      CompanyProfileSection.companyName,
      CompanyProfileSection.phoneNumber,
      CompanyProfileSection.representativeName,
      CompanyProfileSection.postalCode,
      CompanyProfileSection.addressLine1,
      CompanyProfileSection.addressLine2,
    ],
    excelVisibleSections: [
      CompanyProfileSection.companyName,
      CompanyProfileSection.representativeName,
      CompanyProfileSection.postalCode,
      CompanyProfileSection.addressLine1,
      CompanyProfileSection.addressLine2,
    ],
  ),
);

BackupSnapshot _snapshot({
  AppSettings settings = const AppSettings(),
  List<StoredCalculationHistoryEntry> history = const [],
  EstimateWorkspace workspace = const EstimateWorkspace(
    activeEstimateId: '',
    estimates: [],
  ),
  List<ProductivityRecord> records = const [],
}) {
  return BackupSnapshot(
    createdAt: DateTime(2026, 8, 27, 18, 30),
    appVersion: '1.0.0',
    buildNumber: '1',
    data: BackupData(
      occupation: Occupation.exterior,
      settings: settings,
      calculatorHistory: history,
      estimateWorkspace: workspace,
      productivityRecords: records,
    ),
  );
}

StoredCalculationHistoryEntry _history(int index) =>
    StoredCalculationHistoryEntry(
      expression: '$index+1',
      result: '${index + 1}',
      decimalResult: '${index + 1}.0',
      improperFractionResult: '${index + 1}/1',
      mixedFractionResult: '${index + 1}',
      createdAt: DateTime.utc(2026, 8, 1).add(Duration(minutes: index)),
    );

EstimateWorkspace _workspace({
  int estimateCount = 0,
  int itemCount = 0,
  int masterCount = 0,
}) {
  final estimates = [
    for (var estimateIndex = 0; estimateIndex < estimateCount; estimateIndex++)
      EstimateDocument(
        info: EstimateInfo(
          id: 'estimate-$estimateIndex',
          estimateName: 'Estimate $estimateIndex',
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
              id: 'item-$estimateIndex-$itemIndex',
              createdAt: DateTime.utc(
                2026,
                8,
                1,
              ).add(Duration(seconds: estimateIndex * itemCount + itemIndex)),
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
  return EstimateWorkspace(
    activeEstimateId: estimates.isEmpty ? '' : estimates.last.info.id,
    estimates: estimates,
    unitPriceMasters: [
      for (var index = 0; index < masterCount; index++)
        UnitPriceMaster(
          id: 'master-$index',
          createdAt: DateTime.utc(2026, 8, 1).add(Duration(seconds: index)),
          trade: 'Exterior',
          name: 'Master $index',
          specification: 'Specification',
          unit: 'm',
          unitPrice: 2000,
          description: 'Description',
        ),
    ],
  );
}

ProductivityRecord _record(int index) => ProductivityRecord(
  id: 'record-$index',
  createdAt: DateTime.utc(2026, 8, 1).add(Duration(minutes: index)),
  trade: 'Exterior',
  taskName: 'Task $index',
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
);

Map<String, dynamic> _mutableJson(BackupSnapshot snapshot) =>
    jsonDecode(snapshot.encode(pretty: false)) as Map<String, dynamic>;

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

class _HistoryStore implements CalculationHistoryStore {
  _HistoryStore(this.entries);
  final List<StoredCalculationHistoryEntry> entries;
  int saveCalls = 0;
  @override
  Future<List<StoredCalculationHistoryEntry>> load() async => List.of(entries);
  @override
  Future<void> save(List<StoredCalculationHistoryEntry> entries) async {
    saveCalls++;
  }
}

class _EstimateStore implements EstimateItemStore {
  _EstimateStore(this.workspace);
  final EstimateWorkspace workspace;
  int saveCalls = 0;
  @override
  Future<EstimateWorkspace> load() async => workspace;
  @override
  Future<void> save(EstimateWorkspace workspace) async {
    saveCalls++;
  }
}

class _ProductivityStore implements ProductivityRecordStore {
  _ProductivityStore(this.records);
  final List<ProductivityRecord> records;
  int saveCalls = 0;
  @override
  Future<List<ProductivityRecord>> load() async => List.of(records);
  @override
  Future<void> save(List<ProductivityRecord> records) async {
    saveCalls++;
  }
}

class _OnboardingPreferences implements OnboardingPreferences {
  _OnboardingPreferences(this.value);
  String value;
  int saveCalls = 0;
  @override
  Future<bool> hasSelectedOccupation() async => true;
  @override
  Future<String?> loadOccupation() async => value;
  @override
  Future<void> saveOccupation(String occupation) async {
    saveCalls++;
    value = occupation;
  }
}
