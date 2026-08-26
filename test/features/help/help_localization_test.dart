import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/advertising/domain/rewarded_ad_policy.dart';
import 'package:instant_estimate/features/help/presentation/help_screen.dart';

void main() {
  testWidgets('簡体字中国語でヘルプ全体を表示できる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ja'), Locale('en'), Locale('zh', 'CN')],
        locale: Locale('zh', 'CN'),
        home: HelpScreen(),
      ),
    );

    expect(find.text('帮助'), findsOneWidget);
    expect(find.text('安全使用现场计算与估算'), findsOneWidget);
    expect(find.text('计算器基本操作'), findsOneWidget);
    expect(find.text('分数输入与显示'), findsOneWidget);
    expect(find.text('计算历史'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('helpSectionDisclaimer')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('视频广告与无广告方案'), findsOneWidget);
    expect(find.text('免责声明与使用注意'), findsOneWidget);
  });

  test('Help・動画広告・免責は8言語で個別の文言を持つ', () {
    final strings = [
      for (final language in AppLanguage.values) AppLocalizations(language),
    ];

    expect(
      strings.map((value) => value.helpCalculatorTitle).toSet(),
      hasLength(8),
    );
    expect(
      strings.map((value) => value.helpRewardedAdsTitle).toSet(),
      hasLength(8),
    );
    expect(strings.map((value) => value.disclaimerTitle).toSet(), hasLength(8));
    for (final value in strings) {
      expect(value.helpCalculatorBody, isNotEmpty);
      expect(value.helpFractionBody, isNotEmpty);
      expect(
        value.helpRewardedAdsBody(maximumDailyRewardedAds),
        contains('$maximumDailyRewardedAds'),
      );
      expect(value.disclaimerBody, isNotEmpty);
    }
  });

  test('動画広告説明は本番ポリシーの3グループと日次上限に一致する', () {
    const strings = AppLocalizations(AppLanguage.japanese);
    final body = strings.helpRewardedAdsBody(maximumDailyRewardedAds);

    expect(maximumDailyRewardedAds, 3);
    expect(
      RewardedAdEntryPoint.convenientCalculation.group,
      RewardedAdGroup.convenientCalculations,
    );
    expect(
      RewardedAdEntryPoint.instantEstimate.group,
      RewardedAdGroup.estimateAndUnitPriceMaster,
    );
    expect(
      RewardedAdEntryPoint.unitPriceMaster.group,
      RewardedAdGroup.estimateAndUnitPriceMaster,
    );
    expect(RewardedAdEntryPoint.pdfExport.group, RewardedAdGroup.output);
    expect(RewardedAdEntryPoint.excelExport.group, RewardedAdGroup.output);
    expect(RewardedAdEntryPoint.printOutput.group, RewardedAdGroup.output);
    expect(body, contains('最大3回／日'));
    expect(body, contains('Excel貼り付けコピー'));
    expect(body, contains('ローカル日付'));
    expect(body, contains('途中で閉じた場合は解除されません'));
    expect(body, contains('機能の利用を妨げません'));
  });

  testWidgets('小画面でもHelp最下部の免責を開いて全文確認できる', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ja')],
        locale: Locale('ja'),
        home: HelpScreen(),
      ),
    );

    final disclaimer = find.byKey(const Key('helpSectionDisclaimer'));
    await tester.scrollUntilVisible(
      disclaimer,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byKey(const Key('helpList')), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.text('免責・利用上の注意'));
    await tester.pumpAndSettle();

    expect(find.textContaining('施工、発注、契約、申請'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
