import '../../calculator/data/calculation_history_store.dart';
import '../../estimate/data/estimate_item_store.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../../onboarding/domain/occupation.dart';
import '../../productivity/data/productivity_record_store.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/backup_snapshot.dart';

const _buildName = String.fromEnvironment(
  'FLUTTER_BUILD_NAME',
  defaultValue: '1.0.0',
);
const _buildNumber = String.fromEnvironment(
  'FLUTTER_BUILD_NUMBER',
  defaultValue: '1',
);

class BackupSnapshotFactory {
  const BackupSnapshotFactory({
    required this.historyStore,
    required this.estimateStore,
    required this.productivityStore,
    required this.onboardingPreferences,
    this.now = DateTime.now,
    this.appVersion = _buildName,
    this.buildNumber = _buildNumber,
  });

  final CalculationHistoryStore historyStore;
  final EstimateItemStore estimateStore;
  final ProductivityRecordStore productivityStore;
  final OnboardingPreferences onboardingPreferences;
  final DateTime Function() now;
  final String appVersion;
  final String buildNumber;

  Future<BackupSnapshot> create(AppSettings settings) async {
    final storedOccupation = await onboardingPreferences.loadOccupation();
    final occupation = Occupation.fromStoredValue(storedOccupation);
    if (occupation == null) {
      throw const BackupValidationException(
        r'$.data.occupation: saved occupation is missing or invalid',
      );
    }
    final history = await historyStore.load();
    final workspace = await estimateStore.load();
    final records = await productivityStore.load();
    final snapshot = BackupSnapshot(
      createdAt: now().toUtc(),
      appVersion: appVersion,
      buildNumber: buildNumber,
      data: BackupData(
        occupation: occupation,
        settings: settings,
        calculatorHistory: List.unmodifiable(history),
        estimateWorkspace: workspace,
        productivityRecords: List.unmodifiable(records),
      ),
    );

    // The same strict path used by the future restore flow validates exports.
    return BackupSnapshot.decode(snapshot.encode(pretty: false));
  }
}
