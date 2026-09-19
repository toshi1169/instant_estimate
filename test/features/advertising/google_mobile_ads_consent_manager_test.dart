import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:instant_estimate/features/advertising/data/app_tracking_transparency_manager.dart';
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
      platform: TargetPlatform.android,
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
      platform: TargetPlatform.android,
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
      platform: TargetPlatform.android,
    );

    await manager.gatherConsent();

    expect(initialized, isTrue);
    expect(manager.state.value.canRequestAds, isTrue);
  });

  test('iOSのATT未決定では要求結果を待ってから広告SDKを初期化する', () async {
    final events = <String>[];
    final attResult = Completer<TrackingAuthorizationStatus>();
    final trackingManager = _FakeTrackingAuthorizationManager(
      currentStatus: TrackingAuthorizationStatus.notDetermined,
      requestResult: attResult.future,
      events: events,
    );
    final manager = _iosManager(
      trackingManager: trackingManager,
      events: events,
    );

    final first = manager.gatherConsent();
    final second = manager.gatherConsent();
    await Future<void>.delayed(Duration.zero);

    expect(identical(first, second), isTrue);
    expect(trackingManager.requestCalls, 1);
    expect(events, containsAllInOrder(['umpForm', 'attStatus', 'attRequest']));
    expect(events, isNot(contains('initialize')));
    expect(manager.state.value.canRequestAds, isFalse);

    attResult.complete(TrackingAuthorizationStatus.authorized);
    await first;

    expect(events.last, 'initialize');
    expect(manager.state.value.canRequestAds, isTrue);
  });

  for (final status in const [
    TrackingAuthorizationStatus.authorized,
    TrackingAuthorizationStatus.denied,
    TrackingAuthorizationStatus.restricted,
  ]) {
    test('iOSのATTが${status.name}なら再要求せず広告処理へ進む', () async {
      final events = <String>[];
      final trackingManager = _FakeTrackingAuthorizationManager(
        currentStatus: status,
        events: events,
      );
      final manager = _iosManager(
        trackingManager: trackingManager,
        events: events,
      );

      await manager.gatherConsent();

      expect(trackingManager.requestCalls, 0);
      expect(
        events,
        containsAllInOrder(['umpForm', 'attStatus', 'initialize']),
      );
      expect(manager.state.value.canRequestAds, isTrue);
    });
  }

  test('UMPフォームなしでもiOSのATT未決定なら直接要求する', () async {
    final events = <String>[];
    final trackingManager = _FakeTrackingAuthorizationManager(
      currentStatus: TrackingAuthorizationStatus.notDetermined,
      requestResult: Future.value(TrackingAuthorizationStatus.denied),
      events: events,
    );
    final manager = _iosManager(
      trackingManager: trackingManager,
      events: events,
    );

    await manager.gatherConsent();

    expect(trackingManager.requestCalls, 1);
    expect(events, containsAllInOrder(['umpForm', 'attStatus', 'attRequest']));
    expect(events.last, 'initialize');
  });

  test('AndroidではATT状態を確認せず既存UMP広告経路を維持する', () async {
    final events = <String>[];
    final trackingManager = _FakeTrackingAuthorizationManager(
      currentStatus: TrackingAuthorizationStatus.notDetermined,
      events: events,
    );
    final manager = GoogleMobileAdsConsentManager(
      mobileAdsInitializer: GoogleMobileAdsInitializer(
        setPublisherFirstPartyIdEnabled: (_) async {},
        initializeSdk: () async => events.add('initialize'),
      ),
      requestConsentInformationUpdate: () async {},
      loadAndShowConsentFormIfRequired: () async => events.add('umpForm'),
      canRequestAds: () async => true,
      privacyOptionsStatus: () async =>
          PrivacyOptionsRequirementStatus.notRequired,
      trackingAuthorizationManager: trackingManager,
      platform: TargetPlatform.android,
    );

    await manager.gatherConsent();

    expect(trackingManager.statusCalls, 0);
    expect(trackingManager.requestCalls, 0);
    expect(events, ['umpForm', 'initialize']);
  });
}

GoogleMobileAdsConsentManager _iosManager({
  required _FakeTrackingAuthorizationManager trackingManager,
  required List<String> events,
}) {
  return GoogleMobileAdsConsentManager(
    mobileAdsInitializer: GoogleMobileAdsInitializer(
      setPublisherFirstPartyIdEnabled: (_) async {},
      initializeSdk: () async => events.add('initialize'),
    ),
    requestConsentInformationUpdate: () async {},
    loadAndShowConsentFormIfRequired: () async => events.add('umpForm'),
    canRequestAds: () async => true,
    privacyOptionsStatus: () async =>
        PrivacyOptionsRequirementStatus.notRequired,
    trackingAuthorizationManager: trackingManager,
    platform: TargetPlatform.iOS,
  );
}

class _FakeTrackingAuthorizationManager
    implements TrackingAuthorizationManager {
  _FakeTrackingAuthorizationManager({
    required this.currentStatus,
    this.requestResult,
    required this.events,
  });

  final TrackingAuthorizationStatus currentStatus;
  final Future<TrackingAuthorizationStatus>? requestResult;
  final List<String> events;
  int statusCalls = 0;
  int requestCalls = 0;

  @override
  Future<TrackingAuthorizationStatus> status() async {
    statusCalls += 1;
    events.add('attStatus');
    return currentStatus;
  }

  @override
  Future<TrackingAuthorizationStatus> requestAuthorization() {
    requestCalls += 1;
    events.add('attRequest');
    return requestResult ?? Future.value(currentStatus);
  }
}
