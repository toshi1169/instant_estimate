import 'package:flutter/material.dart';

enum AppThemeSelection { system, light, gray, dark }

enum CalculatorRoundingMode { halfUp, ceiling, floor }

enum HistorySortOrder { ascending, descending }

class AppSettings {
  const AppSettings({
    this.theme = AppThemeSelection.light,
    this.decimalPlaces = 2,
    this.roundingMode = CalculatorRoundingMode.halfUp,
    this.historySortOrder = HistorySortOrder.ascending,
    this.confirmHistoryDeletion = true,
  });

  final AppThemeSelection theme;
  final int decimalPlaces;
  final CalculatorRoundingMode roundingMode;
  final HistorySortOrder historySortOrder;
  final bool confirmHistoryDeletion;

  ThemeMode get themeMode => switch (theme) {
    AppThemeSelection.system => ThemeMode.system,
    AppThemeSelection.dark => ThemeMode.dark,
    AppThemeSelection.light || AppThemeSelection.gray => ThemeMode.light,
  };

  AppSettings copyWith({
    AppThemeSelection? theme,
    int? decimalPlaces,
    CalculatorRoundingMode? roundingMode,
    HistorySortOrder? historySortOrder,
    bool? confirmHistoryDeletion,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      roundingMode: roundingMode ?? this.roundingMode,
      historySortOrder: historySortOrder ?? this.historySortOrder,
      confirmHistoryDeletion:
          confirmHistoryDeletion ?? this.confirmHistoryDeletion,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'theme': theme.name,
    'decimalPlaces': decimalPlaces,
    'roundingMode': roundingMode.name,
    'historySortOrder': historySortOrder.name,
    'confirmHistoryDeletion': confirmHistoryDeletion,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    T enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
      return values.where((value) => value.name == raw).firstOrNull ?? fallback;
    }

    final places = json['decimalPlaces'];
    return AppSettings(
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
      historySortOrder: enumValue(
        HistorySortOrder.values,
        json['historySortOrder'],
        HistorySortOrder.ascending,
      ),
      confirmHistoryDeletion: json['confirmHistoryDeletion'] is bool
          ? json['confirmHistoryDeletion']! as bool
          : true,
    );
  }
}
