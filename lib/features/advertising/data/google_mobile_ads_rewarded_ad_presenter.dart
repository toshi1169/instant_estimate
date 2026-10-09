import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/rewarded_ad_access_controller.dart';
import '../domain/rewarded_ad_policy.dart';

abstract final class RewardedAdIds {
  static const androidTest = 'ca-app-pub-3940256099942544/5224354917';
  static const iosTest = 'ca-app-pub-3940256099942544/1712485313';
  static const androidProduction = 'ca-app-pub-5377462997619054/3736654278';
  static const iosProduction = 'ca-app-pub-5377462997619054/4787410869';

  static String? forPlatform(
    TargetPlatform platform, {
    bool useProductionIds = kReleaseMode,
  }) => switch (platform) {
    TargetPlatform.android =>
      useProductionIds ? androidProduction : androidTest,
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
    Timer? loadTimer;
    var rewardEarned = false;
    var disposed = false;

    void trace(String event) {
      if (kDebugMode) debugPrint('[RewardedAd] ${entryPoint.name}: $event');
    }

    void dispose(RewardedAd ad) {
      if (disposed) return;
      disposed = true;
      unawaited(
        ad.dispose().catchError((Object error) {
          trace('disposeFailed');
        }),
      );
    }

    void complete(RewardedAdResult value) {
      if (result.isCompleted) return;
      loadTimer?.cancel();
      trace('result=${value.name}');
      result.complete(value);
    }

    // Bound loading only. A video/end card may remain on screen much longer.
    loadTimer = Timer(loadTimeout, () {
      trace('loadTimeout');
      complete(RewardedAdResult.unavailable);
    });
    trace('load');
    try {
      unawaited(
        RewardedAd.load(
          adUnitId: adUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              if (result.isCompleted) {
                dispose(ad);
                return;
              }
              loadTimer?.cancel();
              trace('loaded');
              ad.fullScreenContentCallback = FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  trace('onAdDismissed reward=$rewardEarned');
                  complete(
                    rewardEarned
                        ? RewardedAdResult.completed
                        : RewardedAdResult.dismissed,
                  );
                  dispose(ad);
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  trace('showFailed code=${error.code}');
                  complete(RewardedAdResult.failed);
                  dispose(ad);
                },
              );
              try {
                unawaited(
                  ad
                      .show(
                        onUserEarnedReward: (ad, reward) {
                          if (result.isCompleted) return;
                          rewardEarned = true;
                          trace('onUserEarnedReward');
                        },
                      )
                      .catchError((Object error) {
                        complete(RewardedAdResult.failed);
                        dispose(ad);
                      }),
                );
              } catch (_) {
                complete(RewardedAdResult.failed);
                dispose(ad);
              }
            },
            onAdFailedToLoad: (error) {
              trace('loadFailed code=${error.code}');
              complete(RewardedAdResult.unavailable);
            },
          ),
        ).catchError((Object error) {
          complete(RewardedAdResult.failed);
        }),
      );
    } catch (_) {
      complete(RewardedAdResult.failed);
    }
    return result.future;
  }
}
