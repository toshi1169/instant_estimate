import 'package:google_mobile_ads/google_mobile_ads.dart';

typedef PublisherFirstPartyIdSetter = Future<void> Function(bool enabled);
typedef MobileAdsSdkInitializer = Future<void> Function();

class GoogleMobileAdsInitializer {
  GoogleMobileAdsInitializer({
    required this.setPublisherFirstPartyIdEnabled,
    required this.initializeSdk,
  });

  factory GoogleMobileAdsInitializer.plugin() {
    return GoogleMobileAdsInitializer(
      setPublisherFirstPartyIdEnabled: MobileAds.instance.setSameAppKeyEnabled,
      initializeSdk: () async {
        await MobileAds.instance.initialize();
      },
    );
  }

  final PublisherFirstPartyIdSetter setPublisherFirstPartyIdEnabled;
  final MobileAdsSdkInitializer initializeSdk;
  bool _isPrepared = false;

  Future<void> prepare() async {
    await setPublisherFirstPartyIdEnabled(false);
    _isPrepared = true;
  }

  Future<void> initialize() async {
    if (!_isPrepared) {
      throw StateError(
        'Google Mobile Ads must be prepared before initialization.',
      );
    }
    await initializeSdk();
  }
}
