import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/app_settings.dart';

abstract interface class AppSettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class PlatformAppSettingsStore implements AppSettingsStore {
  static const _channel = MethodChannel('jp.instant_estimate/app_settings');

  @override
  Future<AppSettings> load() async {
    final encoded = await _channel.invokeMethod<String>('loadSettings');
    if (encoded != null && encoded.isNotEmpty) {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return AppSettings.fromJson(decoded);
      }
    }

    // 旧版で保存したテーマだけがある場合も、その選択を引き継ぐ。
    final legacyTheme = await _channel.invokeMethod<String>('loadThemeMode');
    return AppSettings(
      theme: switch (legacyTheme) {
        'dark' => AppThemeSelection.dark,
        'system' => AppThemeSelection.system,
        _ => AppThemeSelection.light,
      },
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _channel.invokeMethod<void>('saveSettings', <String, Object>{
      'settings': jsonEncode(settings.toJson()),
    });
    // Keep only the compatibility value required by older app versions.
    await _channel.invokeMethod<void>('saveThemeMode', <String, Object>{
      'themeMode': settings.theme.name,
    });
  }
}
