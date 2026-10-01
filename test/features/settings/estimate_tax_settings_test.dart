import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_documents_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_info_editor_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';
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
    await tester.pump();
    expect(
      settings.defaultEstimateTaxRateBasisPoints,
      825,
      reason: '有効値は編集完了を待たず即時保存する',
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

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ON・8.25%'), findsOneWidget);
  });

  testWidgets('見積単位の税率・ON/OFFを編集し既定値へ影響させない', (tester) async {
    final controller = EstimateController(now: DateTime(2026, 9, 28));
    await controller.load();
    var settings = const AppSettings(
      defaultEstimateTaxEnabled: true,
      defaultEstimateTaxRateBasisPoints: 800,
    );
    await tester.pumpWidget(
      _localizedApp(
        AppLanguage.japanese,
        EstimateItemsScreen(
          controller: controller,
          settings: settings,
          onSettingsChanged: (value) => settings = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('estimateMoreActions')));
    await tester.pumpAndSettle();
    final copy = find.byKey(const Key('copyEstimateTable'));
    final tax = find.byKey(const Key('editEstimateTaxSettings'));
    expect(tax, findsOneWidget);
    expect(tester.getTopLeft(tax).dy, greaterThan(tester.getTopLeft(copy).dy));
    expect(find.text('ON・10%'), findsOneWidget);
    await tester.tap(tax);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('estimateTaxRateSetting')),
      '12',
    );
    await tester.pump();
    expect(controller.info.taxRateBasisPoints, 1200);
    expect(settings.defaultEstimateTaxRateBasisPoints, 800);

    await tester.tap(find.byKey(const Key('estimateTaxEnabledSetting')));
    await tester.pumpAndSettle();
    expect(controller.info.taxEnabled, isFalse);
    expect(controller.info.taxRateBasisPoints, 1200);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateSubtotalAmount')), findsNothing);
    expect(find.byKey(const Key('estimateTaxAmount')), findsNothing);
    expect(find.byKey(const Key('estimateGrandTotalAmount')), findsOneWidget);
    expect(find.textContaining('合計'), findsOneWidget);

    await tester.tap(find.byKey(const Key('estimateMoreActions')));
    await tester.pumpAndSettle();
    expect(find.text('OFF・12%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('editEstimateTaxSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTaxEnabledSetting')));
    await tester.pumpAndSettle();
    expect(controller.info.taxEnabled, isTrue);
    expect(controller.info.taxRateBasisPoints, 1200);
    expect(settings.defaultEstimateTaxRateBasisPoints, 800);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggleEstimateHeader')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateSubtotalAmount')), findsOneWidget);
    expect(find.byKey(const Key('estimateTaxAmount')), findsOneWidget);
    expect(find.textContaining('消費税（12%）'), findsOneWidget);
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
      final strings = AppLocalizations(language);
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _localizedApp(
          language,
          EstimateTaxSettingsScreen(
            title: strings.newEstimateTaxSettings,
            taxEnabled: true,
            taxRateBasisPoints: 825,
            onTaxEnabledChanged: (_) {},
            onTaxRateBasisPointsChanged: (_) {},
            onContinue: () async {},
          ),
          textScale: 1.6,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.newEstimateTaxSettings), findsOneWidget);
      expect(find.text(strings.applyTax), findsOneWidget);
      expect(find.text(strings.taxRate), findsOneWidget);
      expect(find.text(strings.taxRateNotice), findsOneWidget);
      expect(find.text(strings.continueInitialTaxSetup), findsOneWidget);
      expect(find.byKey(const Key('completeInitialTaxSetup')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('初回税設定は不正入力では続行できず0〜100%を確定できる', (tester) async {
    var completed = 0;
    var rate = 1000;
    const strings = AppLocalizations(AppLanguage.japanese);
    await tester.pumpWidget(
      _localizedApp(
        AppLanguage.japanese,
        EstimateTaxSettingsScreen(
          title: strings.newEstimateTaxSettings,
          taxEnabled: true,
          taxRateBasisPoints: rate,
          onTaxEnabledChanged: (_) {},
          onTaxRateBasisPointsChanged: (value) => rate = value,
          onContinue: () async => completed++,
          keyPrefix: 'initialEstimate',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('initialEstimateTaxRateSetting'));
    final continueButton = find.byKey(const Key('completeInitialTaxSetup'));
    await tester.enterText(field, '');
    await tester.pump();
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);
    expect(completed, 0);

    for (final entry in const <String, int>{
      '0': 0,
      '8.25': 825,
      '10': 1000,
      '100': 10000,
    }.entries) {
      await tester.enterText(field, entry.key);
      await tester.pump();
      expect(rate, entry.value);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    }

    await tester.showKeyboard(field);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final language in AppLanguage.values) {
    testWidgets('${language.name}の見積税メニューと合計が320px・大文字でもoverflowしない', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = EstimateController(now: DateTime(2026, 9, 28));
      await controller.load();
      await controller.updateInfo(
        controller.info.copyWith(taxRateBasisPoints: 825),
      );
      await tester.pumpWidget(
        _localizedApp(
          language,
          EstimateItemsScreen(controller: controller),
          textScale: 1.6,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('estimateMoreActions')));
      await tester.pumpAndSettle();
      final strings = AppLocalizations(language);
      expect(find.text(strings.taxSettings), findsOneWidget);
      expect(
        find.text(strings.taxSettingsSummary(enabled: true, rate: '8.25%')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: language.name);
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
