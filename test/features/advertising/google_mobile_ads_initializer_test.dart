import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/data/google_mobile_ads_initializer.dart';

void main() {
  test('Publisher first-party IDを無効化してから広告SDKを初期化する', () async {
    final events = <String>[];
    final settingCompleted = Completer<void>();
    final initializer = GoogleMobileAdsInitializer(
      setPublisherFirstPartyIdEnabled: (enabled) async {
        events.add('publisherFirstPartyId:$enabled');
        await settingCompleted.future;
      },
      initializeSdk: () async {
        events.add('initialize');
      },
    );

    final preparing = initializer.prepare();
    await Future<void>.delayed(Duration.zero);

    expect(events, <String>['publisherFirstPartyId:false']);

    settingCompleted.complete();
    await preparing;
    await initializer.initialize();

    expect(events, <String>['publisherFirstPartyId:false', 'initialize']);
  });

  test('Publisher first-party ID設定前の広告SDK初期化を拒否する', () async {
    final initializer = GoogleMobileAdsInitializer(
      setPublisherFirstPartyIdEnabled: (_) async {},
      initializeSdk: () async {},
    );

    await expectLater(initializer.initialize(), throwsStateError);
  });
}
