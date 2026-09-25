import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/transport_vehicle.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/features/density/domain/weight_calculator.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';

void main() {
  test('完全新規ユーザーは仮分数ON・帯分数OFFで開始する', () {
    const settings = AppSettings();

    expect(settings.improperFractionResultEnabled, isTrue);
    expect(settings.mixedFractionResultEnabled, isFalse);
  });

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

  test('インドネシア語の設定を保存・復元できる', () {
    const settings = AppSettings(language: AppLanguage.indonesian);

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.language, AppLanguage.indonesian);
    expect(restored.language.locale.languageCode, 'id');
  });

  test('フィリピノ語の設定を保存・復元できる', () {
    const settings = AppSettings(language: AppLanguage.filipino);

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.language, AppLanguage.filipino);
    expect(restored.language.locale.languageCode, 'fil');
  });

  test('ミャンマー語の設定を保存・復元できる', () {
    const settings = AppSettings(language: AppLanguage.myanmar);

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.language, AppLanguage.myanmar);
    expect(restored.language.locale.languageCode, 'my');
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

  test('見積専用の数量設定を保存・復元できる', () {
    const settings = AppSettings(
      estimateDecimalPlaces: 4,
      estimateRoundingMode: EstimateQuantityRoundingMode.floor,
    );

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.estimateDecimalPlaces, 4);
    expect(restored.estimateRoundingMode, EstimateQuantityRoundingMode.floor);
  });

  test('旧JSONでは見積専用設定だけ既定値を補完する', () {
    final restored = AppSettings.fromJson(const {
      'decimalPlaces': 5,
      'roundingMode': 'ceiling',
    });

    expect(restored.decimalPlaces, 5);
    expect(restored.roundingMode, CalculatorRoundingMode.ceiling);
    expect(restored.estimateDecimalPlaces, 2);
    expect(restored.estimateRoundingMode, EstimateQuantityRoundingMode.halfUp);
    expect(restored.improperFractionResultEnabled, isTrue);
    expect(restored.mixedFractionResultEnabled, isTrue);
  });

  test('解の表示設定を保存・復元できる', () {
    const settings = AppSettings(
      improperFractionResultEnabled: false,
      mixedFractionResultEnabled: true,
    );

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.improperFractionResultEnabled, isFalse);
    expect(restored.mixedFractionResultEnabled, isTrue);
  });

  test('関数電卓設定と見積数量設定は独立して丸める', () {
    const settings = AppSettings(
      decimalPlaces: 1,
      roundingMode: CalculatorRoundingMode.floor,
      estimateDecimalPlaces: 3,
      estimateRoundingMode: EstimateQuantityRoundingMode.halfUp,
    );

    expect(settings.roundCalculationValue(12.34567), 12.3);
    expect(settings.roundEstimateQuantity(12.34567), 12.346);
  });

  test('自社情報を既存設定とともに保存・復元できる', () {
    const settings = AppSettings(
      language: AppLanguage.english,
      decimalPlaces: 4,
      companyProfile: CompanyProfile(
        companyName: '山田建設',
        representativeName: '山田太郎',
        postalCode: '100-0001',
        addressLine1: '東京都千代田区千代田1-1',
        addressLine2: '山田ビル2階',
        phoneNumber: '03-1234-5678',
        displayOrder: [
          CompanyProfileSection.postalCode,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.companyName,
          CompanyProfileSection.representativeName,
          CompanyProfileSection.addressLine2,
          CompanyProfileSection.phoneNumber,
        ],
        excelVisibleSections: [
          CompanyProfileSection.postalCode,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.companyName,
          CompanyProfileSection.representativeName,
        ],
      ),
    );

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.companyProfile.companyName, '山田建設');
    expect(restored.companyProfile.representativeName, '山田太郎');
    expect(restored.companyProfile.postalCode, '100-0001');
    expect(restored.companyProfile.addressLine1, '東京都千代田区千代田1-1');
    expect(restored.companyProfile.addressLine2, '山田ビル2階');
    expect(restored.companyProfile.phoneNumber, '03-1234-5678');
    expect(restored.companyProfile.effectiveDisplayOrder, [
      CompanyProfileSection.postalCode,
      CompanyProfileSection.addressLine1,
      CompanyProfileSection.companyName,
      CompanyProfileSection.representativeName,
      CompanyProfileSection.addressLine2,
      CompanyProfileSection.phoneNumber,
    ]);
    expect(restored.companyProfile.effectiveExcelVisibleSections, [
      CompanyProfileSection.postalCode,
      CompanyProfileSection.addressLine1,
      CompanyProfileSection.companyName,
      CompanyProfileSection.representativeName,
    ]);
    expect(restored.language, AppLanguage.english);
    expect(restored.decimalPlaces, 4);
  });

  test('旧設定JSONと空欄の自社情報を互換読み込みできる', () {
    final legacy = AppSettings.fromJson(const {'theme': 'dark'});
    const blank = AppSettings(companyProfile: CompanyProfile());
    final restoredBlank = AppSettings.fromJson(blank.toJson());

    expect(legacy.companyProfile.isEmpty, isTrue);
    expect(legacy.theme, AppThemeSelection.dark);
    expect(restoredBlank.companyProfile.isEmpty, isTrue);
    expect(
      restoredBlank.companyProfile.effectiveDisplayOrder,
      defaultCompanyProfileDisplayOrder,
    );
    expect(
      restoredBlank.companyProfile.effectiveExcelVisibleSections,
      defaultCompanyProfileExcelVisibleSections,
    );
  });

  test('電卓ボタンの音とバイブ設定を保存・復元する', () {
    const settings = AppSettings(
      calculatorTapSoundEnabled: true,
      calculatorHapticsEnabled: true,
    );

    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.calculatorTapSoundEnabled, isTrue);
    expect(restored.calculatorHapticsEnabled, isTrue);
  });

  test('旧設定JSONではボタン音ONとバイブOFFを補完する', () {
    final restored = AppSettings.fromJson(const {'theme': 'dark'});

    expect(restored.calculatorTapSoundEnabled, isTrue);
    expect(restored.calculatorHapticsEnabled, isFalse);
  });

  test('明示保存したボタン音OFFとバイブONを既定値より優先する', () {
    final restored = AppSettings.fromJson(const {
      'calculatorTapSoundEnabled': false,
      'calculatorHapticsEnabled': true,
    });

    expect(restored.calculatorTapSoundEnabled, isFalse);
    expect(restored.calculatorHapticsEnabled, isTrue);
  });
}
