import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_documents_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_info_editor_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/estimate_tax_settings_screen.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  test('税率basis pointを0〜100%・小数第2位まで表示・解析する', () {
    const cases = <int, String>{
      0: '0%',
      500: '5%',
      800: '8%',
      825: '8.25%',
      1000: '10%',
      1200: '12%',
      10000: '100%',
    };
    for (final entry in cases.entries) {
      expect(formatTaxRateBasisPoints(entry.key), entry.value);
      expect(
        parseTaxRateBasisPoints(entry.value.replaceAll('%', '')),
        entry.key,
      );
    }
    expect(parseTaxRateBasisPoints('8,25'), 825);
    expect(parseTaxRateBasisPoints('-1'), isNull);
    expect(parseTaxRateBasisPoints('8.256'), isNull);
    expect(parseTaxRateBasisPoints('100.01'), isNull);
    expect(parseTaxRateBasisPoints('abc'), isNull);
  });

  test('税率入力formatterは不正文字・小数第3位・100%超を拒否する', () {
    const formatter = TaxRateInputFormatter();
    const old = TextEditingValue(text: '8.25');

    expect(
      formatter.formatEditUpdate(old, const TextEditingValue(text: 'abc')),
      old,
    );
    expect(
      formatter.formatEditUpdate(old, const TextEditingValue(text: '8.256')),
      old,
    );
    expect(
      formatter.formatEditUpdate(old, const TextEditingValue(text: '101')),
      old,
    );
    expect(
      formatter.formatEditUpdate(old, const TextEditingValue(text: '12.5')),
      const TextEditingValue(text: '12.5'),
    );
  });

  testWidgets('設定の先頭から税ON/OFFと税率を変更しOFFでも税率を保持する', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings(
      defaultEstimateTaxEnabled: true,
      defaultEstimateTaxRateBasisPoints: 1000,
    );
    await tester.pumpWidget(
      _localizedApp(
        AppLanguage.japanese,
        SettingsScreen(
          settings: settings,
          onSettingsChanged: (value) => settings = value,
          onClearHistory: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final taxTile = find.byKey(const Key('estimateTaxSettings'));
    await tester.scrollUntilVisible(taxTile, 250);
    expect(
      tester.getTopLeft(taxTile).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('estimateDecimalPlacesSetting')))
            .dy,
      ),
    );
    expect(find.text('ON・10%'), findsOneWidget);
    await tester.tap(taxTile);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('defaultEstimateTaxRateSetting')),
      '8.25',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(settings.defaultEstimateTaxRateBasisPoints, 825);

    await tester.tap(find.byKey(const Key('defaultEstimateTaxEnabledSetting')));
    await tester.pump();
    expect(settings.defaultEstimateTaxEnabled, isFalse);
    expect(settings.defaultEstimateTaxRateBasisPoints, 825);
    final field = tester.widget<TextField>(
      find.byKey(const Key('defaultEstimateTaxRateSetting')),
    );
    expect(field.enabled, isFalse);

    await tester.tap(find.byKey(const Key('defaultEstimateTaxEnabledSetting')));
    await tester.pump();
    expect(settings.defaultEstimateTaxEnabled, isTrue);
    expect(settings.defaultEstimateTaxRateBasisPoints, 825);
  });

  testWidgets('新規見積だけへ既定税設定をスナップショットする', (tester) async {
    final controller = EstimateController(now: DateTime(2026, 9, 28));
    await controller.load();
    expect(controller.estimates.single.info.taxRateBasisPoints, 1000);

    await tester.pumpWidget(
      _localizedApp(
        AppLanguage.japanese,
        EstimateDocumentsScreen(
          controller: controller,
          settings: const AppSettings(
            defaultEstimateTaxEnabled: true,
            defaultEstimateTaxRateBasisPoints: 800,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('createEstimateDocument')));
    await tester.pumpAndSettle();

    final editor = tester.widget<EstimateInfoEditorScreen>(
      find.byType(EstimateInfoEditorScreen),
    );
    expect(editor.initialInfo.taxEnabled, isTrue);
    expect(editor.initialInfo.taxRateBasisPoints, 800);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveEstimateInfo')));
    await tester.pumpAndSettle();

    expect(controller.estimates, hasLength(2));
    expect(controller.estimates.first.info.taxRateBasisPoints, 1000);
    expect(controller.estimates.last.info.taxRateBasisPoints, 800);
  });

  for (final language in AppLanguage.values) {
    testWidgets('${language.name}で税設定が320px・大文字でもoverflowしない', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _localizedApp(
          language,
          EstimateTaxSettingsScreen(
            taxEnabled: true,
            taxRateBasisPoints: 825,
            onTaxEnabledChanged: (_) {},
            onTaxRateBasisPointsChanged: (_) {},
          ),
          textScale: 1.6,
        ),
      );
      await tester.pumpAndSettle();

      final strings = AppLocalizations(language);
      expect(find.text(strings.newEstimateTaxSettings), findsOneWidget);
      expect(find.text(strings.applyTax), findsOneWidget);
      expect(find.text(strings.taxRate), findsOneWidget);
      expect(find.text(strings.taxRateNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _localizedApp(
  AppLanguage language,
  Widget home, {
  double textScale = 1,
}) => MaterialApp(
  locale: language.locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLanguage.values.map((value) => value.locale).toList(),
  home: home,
);
