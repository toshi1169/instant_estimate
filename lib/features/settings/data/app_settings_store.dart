import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract interface class AppSettingsStore {
  Future<ThemeMode> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode themeMode);
}

class PlatformAppSettingsStore implements AppSettingsStore {
  static const _channel = MethodChannel('jp.instant_estimate/app_settings');

  @override
  Future<ThemeMode> loadThemeMode() async {
    final value = await _channel.invokeMethod<String>('loadThemeMode');
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) {
    return _channel.invokeMethod<void>('saveThemeMode', <String, Object>{
      'themeMode': themeMode.name,
    });
  }
}
