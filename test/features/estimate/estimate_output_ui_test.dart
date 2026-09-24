import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';

void main() {
  test('出力UIの文言を8ロケールで用意する', () {
    for (final language in AppLanguage.values) {
      final strings = AppLocalizations(language);
      expect(strings.estimateOutput, isNotEmpty, reason: language.name);
      expect(strings.estimateOutputMethods, isNotEmpty, reason: language.name);
      expect(strings.printA4Landscape, isNotEmpty, reason: language.name);
      expect(strings.formalPdf, isNotEmpty, reason: language.name);
      expect(strings.formalExcelXlsx, isNotEmpty, reason: language.name);
      expect(strings.saveOrShareExcel, isNotEmpty, reason: language.name);
    }
  });

  testWidgets('小画面と長い見積名で8ロケールの上部操作がoverflowしない', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final language in AppLanguage.values) {
      final controller = EstimateController();
      await controller.load();
      await controller.updateInfo(
        controller.info.copyWith(
          estimateName: '非常に長い建設工事の見積書タイトル${language.name}',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: language.locale,
          supportedLocales: AppLanguage.values
              .map((candidate) => candidate.locale)
              .toList(),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: EstimateItemsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<AppBar>(find.byType(AppBar)).title, isNull);
      expect(find.byKey(const Key('estimateOutputButton')), findsOneWidget);
      expect(find.byKey(const Key('copyEstimateTable')), findsOneWidget);
      expect(find.byKey(const Key('editEstimateInfo')), findsOneWidget);
      expect(
        find.byKey(const Key('editCompanyProfileFromEstimateItems')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('estimateOutputSheet')), findsNothing);
      await tester.tap(find.byKey(const Key('estimateOutputButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('estimateOutputSheet')), findsOneWidget);
      expect(find.byKey(const Key('printEstimatePdf')), findsOneWidget);
      expect(find.byKey(const Key('shareEstimatePdf')), findsOneWidget);
      expect(find.byKey(const Key('exportEstimateExcel')), findsOneWidget);
      final expectsScriptNotice =
          language == AppLanguage.simplifiedChinese ||
          language == AppLanguage.myanmar;
      expect(
        find.byKey(const Key('estimateOutputPdfScriptNotice')),
        expectsScriptNotice ? findsOneWidget : findsNothing,
      );
      final scriptNotice = AppLocalizations(
        language,
      ).formalPdfScriptSupportNotice;
      if (scriptNotice != null) {
        expect(find.text(scriptNotice), findsOneWidget);
      }
      expect(tester.takeException(), isNull, reason: language.name);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('estimateOutputSheet')), findsNothing);
      final displayedName = tester.widget<Text>(
        find.byKey(const Key('estimateInfoSummaryName')),
      );
      expect(displayedName.overflow, TextOverflow.ellipsis);
      expect(controller.info.estimateName, '非常に長い建設工事の見積書タイトル${language.name}');
      expect(tester.takeException(), isNull, reason: language.name);
      controller.dispose();
    }
  });

  testWidgets('見積情報カード全体から基本情報を編集できる', (tester) async {
    final controller = EstimateController();
    await controller.load();
    await controller.updateInfo(
      controller.info.copyWith(estimateName: '松本邸見積', notes: '確認用'),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimateInfoSummaryName')), findsOneWidget);
    expect(find.text('松本邸見積'), findsOneWidget);
    expect(find.textContaining('見積名・現場名：'), findsNothing);
    await tester.tap(find.byKey(const Key('editEstimateInfoFromSummary')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimateInfoEditor')), findsOneWidget);
  });

  testWidgets('見積詳細から自社情報を保存して設定変更を通知する', (tester) async {
    final controller = EstimateController();
    await controller.load();
    AppSettings? updatedSettings;
    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemsScreen(
          controller: controller,
          settings: const AppSettings(
            companyProfile: CompanyProfile(companyName: '変更前'),
          ),
          onSettingsChanged: (settings) => updatedSettings = settings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('editCompanyProfileFromEstimateItems')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('companyProfileCompanyName')),
      '変更後',
    );
    await tester.tap(find.byKey(const Key('saveCompanyProfile')));
    await tester.pumpAndSettle();

    expect(updatedSettings?.companyProfile.companyName, '変更後');
  });
}
