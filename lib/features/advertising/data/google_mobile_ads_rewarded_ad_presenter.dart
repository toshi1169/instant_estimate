import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/rewarded_ad_access_controller.dart';
import '../domain/rewarded_ad_policy.dart';

abstract final class RewardedAdIds {
  static const androidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const iosTest = 'ca-app-pub-3940256099942544/1712485313';
  static const iosProduction = 'ca-app-pub-5377462997619054/4787410869';

  static String? forPlatform(
    TargetPlatform platform, {
    bool useProductionIds = kReleaseMode,
  }) => switch (platform) {
    TargetPlatform.android => androidTest,
    TargetPlatform.iOS => useProductionIds ? iosProduction : iosTest,
    _ => null,
  };
}

class GoogleMobileAdsRewardedAdPresenter implements RewardedAdPresenter {
  const GoogleMobileAdsRewardedAdPresenter({
    this.loadTimeout = const Duration(seconds: 15),
  });

  final Duration loadTimeout;

  @override
  Future<RewardedAdResult> show(RewardedAdEntryPoint entryPoint) async {
    if (kIsWeb) return RewardedAdResult.unavailable;
    final adUnitId = RewardedAdIds.forPlatform(defaultTargetPlatform);
    if (adUnitId == null) return RewardedAdResult.unavailable;

    final result = Completer<RewardedAdResult>();
    RewardedAd? loadedAd;
    var rewardEarned = false;
    var timedOut = false;

    void complete(RewardedAdResult value) {
      if (!result.isCompleted) result.complete(value);
    }

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (timedOut || result.isCompleted) {
              ad.dispose();
              return;
            }
            loadedAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                complete(
                  rewardEarned
                      ? RewardedAdResult.completed
                      : RewardedAdResult.dismissed,
                );
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                complete(RewardedAdResult.failed);
              },
            );
            unawaited(
              ad
                  .show(
                    onUserEarnedReward: (ad, reward) {
                      rewardEarned = true;
                    },
                  )
                  .catchError((Object error) {
                    ad.dispose();
                    complete(RewardedAdResult.failed);
                  }),
            );
          },
          onAdFailedToLoad: (error) {
            complete(RewardedAdResult.unavailable);
          },
        ),
      );
    } catch (_) {
      loadedAd?.dispose();
      return RewardedAdResult.failed;
    }

    return result.future.timeout(
      loadTimeout,
      onTimeout: () {
        timedOut = true;
        loadedAd?.dispose();
        return RewardedAdResult.unavailable;
      },
    );
  }
}
