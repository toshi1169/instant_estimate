import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/advertising/application/rewarded_ad_access_controller.dart';
import 'package:instant_estimate/features/advertising/domain/rewarded_ad_policy.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_side_menu.dart';
import 'package:instant_estimate/features/subscription/domain/app_access_state.dart';

void main() {
  testWidgets('無料版の未開放グループだけ動画アイコンを表示する', (tester) async {
    final controller = RewardedAdAccessController(
      initialState: const AppAccessState(),
      now: () => DateTime(2026, 8, 10),
    );

    await _pumpMenu(tester, controller: controller);

    expect(find.byIcon(Icons.videocam_outlined), findsNWidgets(3));
    expect(
      find.byKey(const Key('sideMenuRewardedAd-convenientCalculations')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('sideMenuRewardedAd-estimateAndUnitPriceMaster')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('sideMenuUnitConversion')),
        matching: find.byIcon(Icons.videocam_outlined),
      ),
      findsNothing,
    );
  });

  testWidgets('同一グループは同期して消え、別グループは残る', (tester) async {
    final controller = RewardedAdAccessController(
      initialState: const AppAccessState(),
      presenter: const _ResultPresenter(RewardedAdResult.completed),
      now: () => DateTime(2026, 8, 10),
    );
    await controller.requestAccess(RewardedAdEntryPoint.instantEstimate);

    await _pumpMenu(tester, controller: controller);

    expect(
      find.byKey(const Key('sideMenuRewardedAd-estimateAndUnitPriceMaster')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('sideMenuRewardedAd-convenientCalculations')),
      findsOneWidget,
    );
  });

  testWidgets('広告失敗で利用可能になったグループは非表示になる', (tester) async {
    final controller = RewardedAdAccessController(
      initialState: const AppAccessState(),
      presenter: const _ResultPresenter(RewardedAdResult.unavailable),
      now: () => DateTime(2026, 8, 10),
    );
    await controller.requestAccess(RewardedAdEntryPoint.convenientCalculation);

    await _pumpMenu(tester, controller: controller);

    expect(
      find.byKey(const Key('sideMenuRewardedAd-convenientCalculations')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('sideMenuRewardedAd-estimateAndUnitPriceMaster')),
      findsNWidgets(2),
    );
  });

  testWidgets('端末ローカル日付が変わると動画アイコンを再表示する', (tester) async {
    var now = DateTime(2026, 8, 10);
    final controller = RewardedAdAccessController(
      initialState: const AppAccessState(),
      presenter: const _ResultPresenter(RewardedAdResult.completed),
      now: () => now,
    );
    await controller.requestAccess(RewardedAdEntryPoint.instantEstimate);
    now = DateTime(2026, 8, 11);

    await _pumpMenu(tester, controller: controller);

    expect(
      find.byKey(const Key('sideMenuRewardedAd-estimateAndUnitPriceMaster')),
      findsNWidgets(2),
    );
  });

  testWidgets('広告なし版と完全版は動画アイコンを表示しない', (tester) async {
    for (final plan in [AppAccessPlan.adFree, AppAccessPlan.full]) {
      final controller = RewardedAdAccessController(
        initialState: AppAccessState(plan: plan),
        now: () => DateTime(2026, 8, 10),
      );
      await _pumpMenu(tester, controller: controller, plan: plan);
      expect(find.byIcon(Icons.videocam_outlined), findsNothing);
    }
  });

  testWidgets('各画面幅で動画アイコンは山括弧の左に収まり行高を変えない', (tester) async {
    final controller = RewardedAdAccessController(
      initialState: const AppAccessState(),
      now: () => DateTime(2026, 8, 10),
    );

    for (final size in const [Size(375, 812), Size(402, 874), Size(320, 568)]) {
      await _pumpMenu(tester, controller: controller, size: size);
      expect(tester.takeException(), isNull);

      final tile = find.byKey(const Key('sideMenuInstantEstimate'));
      final video = find.descendant(
        of: tile,
        matching: find.byIcon(Icons.videocam_outlined),
      );
      final chevron = find.descendant(
        of: tile,
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(
        tester.getRect(video).right,
        lessThan(tester.getRect(chevron).left),
      );

      final rewardedHeight = tester.getSize(tile).height;
      final plainHeight = tester
          .getSize(find.byKey(const Key('sideMenuUnitConversion')))
          .height;
      expect(
        rewardedHeight,
        plainHeight,
        reason: '$size: rewarded=$rewardedHeight plain=$plainHeight',
      );
    }
  });
}

Future<void> _pumpMenu(
  WidgetTester tester, {
  required RewardedAdAccessController controller,
  AppAccessPlan plan = AppAccessPlan.free,
  Size size = const Size(375, 812),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: CalculatorSideMenu(
          showAds: plan.showsAds,
          accessPlan: plan,
          isRewardedAdRequired: controller.requiresAd,
          onSelected: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ResultPresenter implements RewardedAdPresenter {
  const _ResultPresenter(this.result);

  final RewardedAdResult result;

  @override
  Future<RewardedAdResult> show(RewardedAdEntryPoint entryPoint) async {
    return result;
  }
}
