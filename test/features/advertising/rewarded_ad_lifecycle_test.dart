import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Access the SDK event dispatcher so the real presenter is exercised.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:instant_estimate/features/advertising/application/rewarded_ad_access_controller.dart';
import 'package:instant_estimate/features/advertising/data/google_mobile_ads_rewarded_ad_presenter.dart';
import 'package:instant_estimate/features/advertising/domain/rewarded_ad_policy.dart';

void main() {
  final calls = <String>[];
  setUp(() {
    calls.clear();

    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (call) async {
          calls.add(call.method);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, null);
  });

  testWidgets('視聴が15秒を超えても報酬と閉じる通知まで待つ', (tester) async {
    RewardedAdResult? result;
    const presenter = GoogleMobileAdsRewardedAdPresenter();
    presenter
        .show(RewardedAdEntryPoint.pdfExport)
        .then((value) => result = value);
    await tester.pump();
    final ad = instanceManager.adFor(0)! as RewardedAd;
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(result, isNull);
    expect(calls.where((call) => call == 'disposeAd'), isEmpty);
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'output'));
    await tester.pump();
    expect(result, isNull, reason: '報酬だけでは出力しない');
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    await tester.pump();
    expect(result, RewardedAdResult.completed);
    expect(calls.where((call) => call == 'disposeAd'), hasLength(1));
  });

  testWidgets('報酬なしの途中終了は許可しない', (tester) async {
    RewardedAdResult? result;
    const GoogleMobileAdsRewardedAdPresenter()
        .show(RewardedAdEntryPoint.printOutput)
        .then((value) => result = value);
    await tester.pump();
    final ad = instanceManager.adFor(0)! as RewardedAd;
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await tester.pump();
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    await tester.pump();
    expect(result, RewardedAdResult.dismissed);
  });

  testWidgets('読込タイムアウト後の遅い広告は表示しない', (tester) async {
    RewardedAdResult? result;
    const GoogleMobileAdsRewardedAdPresenter()
        .show(RewardedAdEntryPoint.excelExport)
        .then((value) => result = value);
    await tester.pump();
    final ad = instanceManager.adFor(0)! as RewardedAd;
    await tester.pump(const Duration(seconds: 16));
    expect(result, RewardedAdResult.unavailable);
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await tester.pump();
    expect(calls, isNot(contains('showAdWithoutView')));
    expect(calls.where((call) => call == 'disposeAd'), hasLength(1));
  });
  for (final failure in ['load', 'show']) {
    testWidgets('$failure失敗は報酬を付与せずタイマーを解除する', (tester) async {
      RewardedAdResult? result;
      const GoogleMobileAdsRewardedAdPresenter()
          .show(RewardedAdEntryPoint.pdfExport)
          .then((value) => result = value);
      await tester.pump();
      final ad = instanceManager.adFor(0)! as RewardedAd;
      if (failure == 'load') {
        ad.rewardedAdLoadCallback.onAdFailedToLoad(
          LoadAdError(1, 'test', 'test', null),
        );
      } else {
        ad.rewardedAdLoadCallback.onAdLoaded(ad);
        await tester.pump();
        ad.fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
          ad,
          AdError(1, 'test', 'test'),
        );
      }
      await tester.pump();
      expect(
        result,
        failure == 'load'
            ? RewardedAdResult.unavailable
            : RewardedAdResult.failed,
      );
      await tester.pump(const Duration(seconds: 20));
      expect(
        result,
        failure == 'load'
            ? RewardedAdResult.unavailable
            : RewardedAdResult.failed,
      );
    });
  }

  testWidgets('重複通知と終了後の報酬通知は二重完了させない', (tester) async {
    final results = <RewardedAdResult>[];
    const GoogleMobileAdsRewardedAdPresenter()
        .show(RewardedAdEntryPoint.pdfExport)
        .then(results.add);
    await tester.pump();
    final ad = instanceManager.adFor(0)! as RewardedAd;
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    await tester.pump();
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'output'));
    ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
    await tester.pump();
    expect(results, [RewardedAdResult.dismissed]);
    expect(calls.where((call) => call == 'disposeAd'), hasLength(1));
  });
}
