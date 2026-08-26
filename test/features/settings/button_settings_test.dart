import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('設定からボタン音とバイブを変更して再表示できる', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings();

    Future<void> pumpSettings() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          home: SettingsScreen(
            settings: settings,
            accessPlan: AppAccessPlan.free,
            onSettingsChanged: (value) => settings = value,
            onClearHistory: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpSettings();
    await tester.tap(find.byKey(const Key('buttonSettings')));
    await tester.pumpAndSettle();
    expect(find.text('ボタン設定'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('calculatorTapSoundSetting')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('calculatorHapticsSetting')),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('calculatorTapSoundSetting')));
    await tester.tap(find.byKey(const Key('calculatorHapticsSetting')));
    await tester.pumpAndSettle();
    expect(settings.calculatorTapSoundEnabled, isFalse);
    expect(settings.calculatorHapticsEnabled, isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await pumpSettings();
    await tester.tap(find.byKey(const Key('buttonSettings')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('calculatorTapSoundSetting')),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('calculatorHapticsSetting')),
          )
          .value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  test('ボタン設定の追加キーを8言語で明示する', () {
    for (final language in AppLanguage.values) {
      final strings = AppLocalizations(language);
      expect(strings.buttonSettings, isNotEmpty);
      expect(strings.calculatorTapSound, isNotEmpty);
      expect(strings.calculatorTapHaptics, isNotEmpty);
    }
  });
}
