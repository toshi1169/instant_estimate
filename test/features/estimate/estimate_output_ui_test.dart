import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';

void main() {
  test('出力UIの文言を8ロケールで用意する', () {
    for (final language in AppLanguage.values) {
      final strings = AppLocalizations(language);
      expect(strings.estimateOutput, isNotEmpty, reason: language.name);
      expect(strings.estimateOutputMethods, isNotEmpty, reason: language.name);
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

      expect(find.byKey(const Key('estimateOutputButton')), findsOneWidget);
      expect(find.byKey(const Key('copyEstimateTable')), findsOneWidget);
      expect(find.byKey(const Key('editEstimateInfo')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: language.name);

      await tester.tap(find.byKey(const Key('estimateOutputButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('estimateOutputSheet')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: language.name);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      controller.dispose();
    }
  });
}
