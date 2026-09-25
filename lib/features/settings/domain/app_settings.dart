import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/domain/angle_unit.dart';
import '../../../core/domain/transport_vehicle.dart';
import '../../../core/localization/app_language.dart';
import '../../density/domain/weight_calculator.dart';
import '../../estimate/domain/estimate_quantity.dart';
import 'company_profile.dart';

enum AppThemeSelection { system, light, gray, dark }

enum CalculatorRoundingMode { halfUp, ceiling, floor }

enum HistorySortOrder { ascending, descending }

class AppSettings {
  const AppSettings({
    this.language = AppLanguage.japanese,
    this.theme = AppThemeSelection.light,
    this.decimalPlaces = 2,
    this.roundingMode = CalculatorRoundingMode.halfUp,
    this.improperFractionResultEnabled = true,
    this.mixedFractionResultEnabled = true,
    this.estimateDecimalPlaces = 2,
    this.estimateRoundingMode = EstimateQuantityRoundingMode.halfUp,
    this.angleUnit = AngleUnit.degrees,
    this.historySortOrder = HistorySortOrder.ascending,
    this.confirmHistoryDeletion = true,
    this.calculatorTapSoundEnabled = true,
    this.calculatorHapticsEnabled = false,
    this.customTransportVehicles = const [],
    this.customDensityMaterials = const [],
    this.companyProfile = const CompanyProfile(),
  });

  final AppLanguage language;
  final AppThemeSelection theme;
  final int decimalPlaces;
  final CalculatorRoundingMode roundingMode;
  final bool improperFractionResultEnabled;
  final bool mixedFractionResultEnabled;
  final int estimateDecimalPlaces;
  final EstimateQuantityRoundingMode estimateRoundingMode;
  final AngleUnit angleUnit;
  final HistorySortOrder historySortOrder;
  final bool confirmHistoryDeletion;
  final bool calculatorTapSoundEnabled;
  final bool calculatorHapticsEnabled;
  final List<TransportVehicle> customTransportVehicles;
  final List<DensityMaterialPreset> customDensityMaterials;
  final CompanyProfile companyProfile;

  ThemeMode get themeMode => switch (theme) {
    AppThemeSelection.system => ThemeMode.system,
    AppThemeSelection.dark => ThemeMode.dark,
    AppThemeSelection.light || AppThemeSelection.gray => ThemeMode.light,
  };

  double roundCalculationValue(double value) {
    final places = decimalPlaces.clamp(1, 5);
    final factor = math.pow(10, places).toDouble();
    final scaled = value * factor;
    final rounded = switch (roundingMode) {
      CalculatorRoundingMode.halfUp => scaled.roundToDouble(),
      CalculatorRoundingMode.ceiling => scaled.ceilToDouble(),
      CalculatorRoundingMode.floor => scaled.floorToDouble(),
    };
    return rounded / factor;
  }

  /// 丸め前候補を、保存・表示・金額計算に共通で使う正式な見積数量へ確定する。
  double roundEstimateQuantity(double value) {
    return finalizeEstimateQuantity(
      value,
      decimalPlaces: estimateDecimalPlaces,
      roundingMode: estimateRoundingMode,
    );
  }

  AppSettings copyWith({
    AppLanguage? language,
    AppThemeSelection? theme,
    int? decimalPlaces,
    CalculatorRoundingMode? roundingMode,
    bool? improperFractionResultEnabled,
    bool? mixedFractionResultEnabled,
    int? estimateDecimalPlaces,
    EstimateQuantityRoundingMode? estimateRoundingMode,
    AngleUnit? angleUnit,
    HistorySortOrder? historySortOrder,
    bool? confirmHistoryDeletion,
    bool? calculatorTapSoundEnabled,
    bool? calculatorHapticsEnabled,
    List<TransportVehicle>? customTransportVehicles,
    List<DensityMaterialPreset>? customDensityMaterials,
    CompanyProfile? companyProfile,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      roundingMode: roundingMode ?? this.roundingMode,
      improperFractionResultEnabled:
          improperFractionResultEnabled ?? this.improperFractionResultEnabled,
      mixedFractionResultEnabled:
          mixedFractionResultEnabled ?? this.mixedFractionResultEnabled,
      estimateDecimalPlaces:
          estimateDecimalPlaces ?? this.estimateDecimalPlaces,
      estimateRoundingMode: estimateRoundingMode ?? this.estimateRoundingMode,
      angleUnit: angleUnit ?? this.angleUnit,
      historySortOrder: historySortOrder ?? this.historySortOrder,
      confirmHistoryDeletion:
          confirmHistoryDeletion ?? this.confirmHistoryDeletion,
      calculatorTapSoundEnabled:
          calculatorTapSoundEnabled ?? this.calculatorTapSoundEnabled,
      calculatorHapticsEnabled:
          calculatorHapticsEnabled ?? this.calculatorHapticsEnabled,
      customTransportVehicles:
          customTransportVehicles ?? this.customTransportVehicles,
      customDensityMaterials:
          customDensityMaterials ?? this.customDensityMaterials,
      companyProfile: companyProfile ?? this.companyProfile,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'language': language.name,
    'theme': theme.name,
    'decimalPlaces': decimalPlaces,
    'roundingMode': roundingMode.name,
    'improperFractionResultEnabled': improperFractionResultEnabled,
    'mixedFractionResultEnabled': mixedFractionResultEnabled,
    'estimateDecimalPlaces': estimateDecimalPlaces,
    'estimateRoundingMode': estimateRoundingMode.name,
    'angleUnit': angleUnit.name,
    'historySortOrder': historySortOrder.name,
    'confirmHistoryDeletion': confirmHistoryDeletion,
    'calculatorTapSoundEnabled': calculatorTapSoundEnabled,
    'calculatorHapticsEnabled': calculatorHapticsEnabled,
    'customTransportVehicles': customTransportVehicles
        .map((vehicle) => vehicle.toJson())
        .toList(growable: false),
    'customDensityMaterials': customDensityMaterials
        .map((material) => material.toJson())
        .toList(growable: false),
    'companyProfile': companyProfile.toJson(),
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    T enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
      return values.where((value) => value.name == raw).firstOrNull ?? fallback;
    }

    final places = json['decimalPlaces'];
    final estimatePlaces = json['estimateDecimalPlaces'];
    return AppSettings(
      language: appLanguageFromStorageName(json['language']),
      theme: enumValue(
        AppThemeSelection.values,
        json['theme'],
        AppThemeSelection.light,
      ),
      decimalPlaces: places is int ? places.clamp(1, 5) : 2,
      roundingMode: enumValue(
        CalculatorRoundingMode.values,
        json['roundingMode'],
        CalculatorRoundingMode.halfUp,
      ),
      improperFractionResultEnabled:
          json['improperFractionResultEnabled'] is bool
          ? json['improperFractionResultEnabled']! as bool
          : true,
      mixedFractionResultEnabled: json['mixedFractionResultEnabled'] is bool
          ? json['mixedFractionResultEnabled']! as bool
          : true,
      estimateDecimalPlaces: estimatePlaces is int
          ? estimatePlaces.clamp(1, 5)
          : 2,
      estimateRoundingMode: enumValue(
        EstimateQuantityRoundingMode.values,
        json['estimateRoundingMode'],
        EstimateQuantityRoundingMode.halfUp,
      ),
      angleUnit: enumValue(
        AngleUnit.values,
        json['angleUnit'],
        AngleUnit.degrees,
      ),
      historySortOrder: enumValue(
        HistorySortOrder.values,
        json['historySortOrder'],
        HistorySortOrder.ascending,
      ),
      confirmHistoryDeletion: json['confirmHistoryDeletion'] is bool
          ? json['confirmHistoryDeletion']! as bool
          : true,
      calculatorTapSoundEnabled: json['calculatorTapSoundEnabled'] is bool
          ? json['calculatorTapSoundEnabled']! as bool
          : true,
      calculatorHapticsEnabled: json['calculatorHapticsEnabled'] is bool
          ? json['calculatorHapticsEnabled']! as bool
          : false,
      customTransportVehicles: switch (json['customTransportVehicles']) {
        final List<Object?> values =>
          values
              .whereType<Map>()
              .map(
                (value) => TransportVehicle.fromJson(
                  value.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList(growable: false),
        _ => const [],
      },
      customDensityMaterials: switch (json['customDensityMaterials']) {
        final List<Object?> values =>
          values
              .whereType<Map>()
              .map(
                (value) => DensityMaterialPreset.fromJson(
                  value.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList(growable: false),
        _ => const [],
      },
      companyProfile: switch (json['companyProfile']) {
        final Map<Object?, Object?> value => CompanyProfile.fromJson(
          value.map((key, value) => MapEntry(key.toString(), value)),
        ),
        _ => const CompanyProfile(),
      },
    );
  }
}
