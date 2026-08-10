import 'package:flutter/foundation.dart';

class AdvertisingConsentState {
  const AdvertisingConsentState({
    this.canRequestAds = false,
    this.privacyOptionsRequired = false,
    this.isGathering = false,
  });

  final bool canRequestAds;
  final bool privacyOptionsRequired;
  final bool isGathering;

  AdvertisingConsentState copyWith({
    bool? canRequestAds,
    bool? privacyOptionsRequired,
    bool? isGathering,
  }) {
    return AdvertisingConsentState(
      canRequestAds: canRequestAds ?? this.canRequestAds,
      privacyOptionsRequired:
          privacyOptionsRequired ?? this.privacyOptionsRequired,
      isGathering: isGathering ?? this.isGathering,
    );
  }
}

abstract interface class AdvertisingConsentManager {
  ValueListenable<AdvertisingConsentState> get state;

  Future<void> gatherConsent();

  Future<void> showPrivacyOptions();
}
