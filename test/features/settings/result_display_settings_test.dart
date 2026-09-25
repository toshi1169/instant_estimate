import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';
import 'package:instant_estimate/features/settings/presentation/result_display_settings_screen.dart';

void main() {
  testWidgets('解の表示入口から小数常時有効と2つのSwitchを設定できる', (tester) async {
    var settings = const AppSettings();
    await tester.pumpWidget(_app(settings, (value) => settings = value));

    await tester.scrollUntilVisible(
      find.byKey(const Key('resultDisplaySetting')),
      200,
    );
    await tester.tap(find.byKey(const Key('resultDisplaySetting')));
    await tester.pumpAndSettle();

    expect(find.text('解の表示'), findsOneWidget);
    expect(find.text('小数'), findsOneWidget);
    expect(find.text('常に有効'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('improperFractionResultSetting')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('mixedFractionResultSetting')),
          )
          .value,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('improperFractionResultSetting')));
    await tester.pump();
    expect(settings.improperFractionResultEnabled, isFalse);
    expect(settings.mixedFractionResultEnabled, isFalse);
  });

  testWidgets('320px幅と大きな文字倍率でも8言語の設定画面がoverflowしない', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final language in AppLanguage.values) {
      await tester.pumpWidget(
        _localizedApp(
          language,
          const ResultDisplaySettingsScreen(
            improperFractionEnabled: true,
            mixedFractionEnabled: true,
            onImproperFractionChanged: _ignore,
            onMixedFractionChanged: _ignore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('decimalResultSetting')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _app(AppSettings settings, ValueChanged<AppSettings> onChanged) {
  return _localizedApp(
    settings.language,
    SettingsScreen(
      settings: settings,
      onSettingsChanged: onChanged,
      onClearHistory: () async {},
    ),
  );
}

Widget _localizedApp(AppLanguage language, Widget home) {
  return MaterialApp(
    locale: language.locale,
    supportedLocales: AppLanguage.values.map((value) => value.locale),
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

void _ignore(bool _) {}
