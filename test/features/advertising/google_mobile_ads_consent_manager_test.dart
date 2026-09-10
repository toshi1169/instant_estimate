import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:instant_estimate/features/advertising/data/google_mobile_ads_consent_manager.dart';
import 'package:instant_estimate/features/advertising/data/google_mobile_ads_initializer.dart';

void main() {
  test('UMP完了前は広告SDKを初期化しない', () async {
    final events = <String>[];
    final umpCompleted = Completer<void>();
    final initializer = GoogleMobileAdsInitializer(
      setPublisherFirstPartyIdEnabled: (enabled) async {
        events.add('publisherFirstPartyId:$enabled');
      },
      initializeSdk: () async {
        events.add('initialize');
      },
    );
    final manager = GoogleMobileAdsConsentManager(
      mobileAdsInitializer: initializer,
      requestConsentInformationUpdate: () async {
        events.add('consentInfo');
      },
      loadAndShowConsentFormIfRequired: () {
        events.add('umpForm');
        return umpCompleted.future;
      },
      canRequestAds: () async => true,
      privacyOptionsStatus: () async =>
          PrivacyOptionsRequirementStatus.notRequired,
    );

    final gathering = manager.gatherConsent();
    await Future<void>.delayed(Duration.zero);

    expect(events, <String>[
      'publisherFirstPartyId:false',
      'consentInfo',
      'umpForm',
    ]);

    umpCompleted.complete();
    await gathering;

    expect(events.last, 'initialize');
    expect(manager.state.value.canRequestAds, isTrue);
  });

  test('UMP完了後に広告要求不可なら広告SDKを初期化しない', () async {
    var initialized = false;
    final manager = GoogleMobileAdsConsentManager(
      mobileAdsInitializer: GoogleMobileAdsInitializer(
        setPublisherFirstPartyIdEnabled: (_) async {},
        initializeSdk: () async => initialized = true,
      ),
      requestConsentInformationUpdate: () async {},
      loadAndShowConsentFormIfRequired: () async {},
      canRequestAds: () async => false,
      privacyOptionsStatus: () async =>
          PrivacyOptionsRequirementStatus.notRequired,
    );

    await manager.gatherConsent();

    expect(initialized, isFalse);
    expect(manager.state.value.canRequestAds, isFalse);
  });

  test('ATT拒否相当でもUMPが許可すればIDFAなし広告の初期化を継続する', () async {
    var initialized = false;
    final manager = GoogleMobileAdsConsentManager(
      mobileAdsInitializer: GoogleMobileAdsInitializer(
        setPublisherFirstPartyIdEnabled: (_) async {},
        initializeSdk: () async => initialized = true,
      ),
      requestConsentInformationUpdate: () async {},
      // UMPのIDFA/ATTフローは拒否時も正常完了する。
      loadAndShowConsentFormIfRequired: () async {},
      canRequestAds: () async => true,
      privacyOptionsStatus: () async =>
          PrivacyOptionsRequirementStatus.notRequired,
    );

    await manager.gatherConsent();

    expect(initialized, isTrue);
    expect(manager.state.value.canRequestAds, isTrue);
  });
}
