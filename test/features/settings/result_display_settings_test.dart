import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';
import 'package:instant_estimate/features/settings/presentation/result_display_settings_screen.dart';

void main() {
  test('解の表示概要は3項目の全8組み合わせを切替順どおり表示する', () {
    final strings = AppLocalizations(AppLanguage.japanese);
    const cases = <(bool, bool, bool, String)>[
      (false, false, false, '小数'),
      (true, false, false, '小数 / 仮分数'),
      (false, true, false, '小数 / 帯分数'),
      (true, true, false, '小数 / 仮分数 / 帯分数'),
      (false, false, true, '小数 / 余り'),
      (true, false, true, '小数 / 仮分数 / 余り'),
      (false, true, true, '小数 / 帯分数 / 余り'),
      (true, true, true, '小数 / 仮分数 / 帯分数 / 余り'),
    ];

    for (final entry in cases) {
      expect(
        strings.resultDisplaySummary(
          improperFraction: entry.$1,
          mixedFraction: entry.$2,
          remainder: entry.$3,
        ),
        entry.$4,
      );
    }
  });

  test('8言語で余りのみONの概要に各言語の余り名称を含む', () {
    for (final language in AppLanguage.values) {
      final strings = AppLocalizations(language);
      final summary = strings.resultDisplaySummary(
        improperFraction: false,
        mixedFraction: false,
        remainder: true,
      );

      expect(summary, '${strings.decimalResult} / ${strings.remainderResult}');
    }
  });

  testWidgets('解の表示入口から小数常時有効と3つのSwitchを設定できる', (tester) async {
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
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('remainderResultSetting')),
          )
          .value,
      isTrue,
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
            remainderEnabled: true,
            onImproperFractionChanged: _ignore,
            onMixedFractionChanged: _ignore,
            onRemainderChanged: _ignore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('decimalResultSetting')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('余りのみONの設定概要は320px幅と大きな文字倍率でもoverflowしない', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final language in AppLanguage.values) {
      final settings = AppSettings(
        language: language,
        improperFractionResultEnabled: false,
        mixedFractionResultEnabled: false,
        remainderResultEnabled: true,
      );
      await tester.pumpWidget(_app(settings, (_) {}));
      await tester.pumpAndSettle();

      final strings = AppLocalizations(language);
      expect(
        find.text(
          '${strings.decimalResult} / ${strings.remainderResult}',
          skipOffstage: false,
        ),
        findsOneWidget,
        reason: language.name,
      );
      expect(tester.takeException(), isNull, reason: language.name);
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
