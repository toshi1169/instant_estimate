import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/settings/data/app_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('jp.instant_estimate/app_settings');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('完全新規はON/OFFで保存し、再起動時は初回判定を繰り返さない', () async {
    String? stored;
    var occupationChecks = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'loadSettings') return stored;
          if (call.method == 'loadThemeMode') return 'light';
          if (call.method == 'saveSettings') {
            stored = (call.arguments as Map)['settings'] as String;
          }
          return null;
        });
    final store = PlatformAppSettingsStore(
      hasSelectedOccupation: () async {
        occupationChecks++;
        return false;
      },
    );

    final first = await store.load();
    final second = await store.load();

    expect(first.improperFractionResultEnabled, isTrue);
    expect(first.mixedFractionResultEnabled, isFalse);
    expect(second.mixedFractionResultEnabled, isFalse);
    expect(occupationChecks, 1);
  });

  test('設定JSONなしでも業種選択済みの既存ユーザーはON/ONで保存する', () async {
    String? stored;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'loadSettings') return stored;
          if (call.method == 'loadThemeMode') return 'dark';
          if (call.method == 'saveSettings') {
            stored = (call.arguments as Map)['settings'] as String;
          }
          return null;
        });
    final store = PlatformAppSettingsStore(
      hasSelectedOccupation: () async => true,
    );

    final settings = await store.load();

    expect(settings.improperFractionResultEnabled, isTrue);
    expect(settings.mixedFractionResultEnabled, isTrue);
    expect(jsonDecode(stored!)['mixedFractionResultEnabled'], isTrue);
  });

  test('明示保存済みのON/OFFとOFF/OFFをそのまま維持する', () async {
    for (final values in const [(true, false), (false, false)]) {
      final stored = jsonEncode({
        'improperFractionResultEnabled': values.$1,
        'mixedFractionResultEnabled': values.$2,
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'loadSettings') return stored;
            return null;
          });
      final store = PlatformAppSettingsStore(
        hasSelectedOccupation: () async =>
            throw StateError('saved settings must not be reclassified'),
      );

      final settings = await store.load();

      expect(settings.improperFractionResultEnabled, values.$1);
      expect(settings.mixedFractionResultEnabled, values.$2);
    }
  });
}
