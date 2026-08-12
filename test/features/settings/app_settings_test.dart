import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/features/density/domain/weight_calculator.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  test('言語設定を保存・復元し、旧データは日本語として扱う', () {
    const settings = AppSettings(language: AppLanguage.english);

    final restored = AppSettings.fromJson(settings.toJson());
    final restoredLegacy = AppSettings.fromJson(const {});

    expect(restored.language, AppLanguage.english);
    expect(restoredLegacy.language, AppLanguage.japanese);
  });

  test('簡体字中国語の設定を保存・復元できる', () {
    const settings = AppSettings(language: AppLanguage.simplifiedChinese);

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.language, AppLanguage.simplifiedChinese);
    expect(restored.language.locale.languageCode, 'zh');
    expect(restored.language.locale.countryCode, 'CN');
  });

  test('繁体字中国語の設定を保存・復元できる', () {
    const settings = AppSettings(language: AppLanguage.traditionalChinese);

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.language, AppLanguage.traditionalChinese);
    expect(restored.language.locale.languageCode, 'zh');
    expect(restored.language.locale.countryCode, 'TW');
  });

  test('ベトナム語の設定を保存・復元できる', () {
    const settings = AppSettings(language: AppLanguage.vietnamese);

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.language, AppLanguage.vietnamese);
    expect(restored.language.locale.languageCode, 'vi');
  });

  test('ユーザー登録車両を設定データに保存・復元できる', () {
    const vehicle = TransportVehicle(
      id: 'custom_test',
      name: '現場用ダンプ',
      initialCapacityCubicMeters: 4.2,
      maximumPayloadTons: 5,
      approximateCapacityLabel: '4.2m³',
      isCustom: true,
    );
    const settings = AppSettings(customTransportVehicles: [vehicle]);

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.customTransportVehicles, hasLength(1));
    expect(restored.customTransportVehicles.single.name, '現場用ダンプ');
    expect(
      restored.customTransportVehicles.single.initialCapacityCubicMeters,
      4.2,
    );
    expect(restored.customTransportVehicles.single.maximumPayloadTons, 5);
    expect(restored.customTransportVehicles.single.isCustom, isTrue);
  });

  test('ユーザー登録材料を設定データに保存・復元できる', () {
    const settings = AppSettings(
      customDensityMaterials: [
        DensityMaterialPreset(name: '再生砕石', density: 1.65),
      ],
    );

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.customDensityMaterials, hasLength(1));
    expect(restored.customDensityMaterials.single.name, '再生砕石');
    expect(restored.customDensityMaterials.single.density, 1.65);
  });
}
