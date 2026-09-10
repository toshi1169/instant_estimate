import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/advertising_consent_manager.dart';
import 'google_mobile_ads_initializer.dart';

class GoogleMobileAdsConsentManager implements AdvertisingConsentManager {
  GoogleMobileAdsConsentManager({
    GoogleMobileAdsInitializer? mobileAdsInitializer,
    Future<void> Function()? requestConsentInformationUpdate,
    Future<void> Function()? loadAndShowConsentFormIfRequired,
    Future<bool> Function()? canRequestAds,
    Future<PrivacyOptionsRequirementStatus> Function()? privacyOptionsStatus,
  }) : _mobileAdsInitializer =
           mobileAdsInitializer ?? GoogleMobileAdsInitializer.plugin(),
       _requestConsentInformationUpdate =
           requestConsentInformationUpdate ??
           _pluginRequestConsentInformationUpdate,
       _loadAndShowConsentFormIfRequired =
           loadAndShowConsentFormIfRequired ??
           _pluginLoadAndShowConsentFormIfRequired,
       _canRequestAds =
           canRequestAds ?? ConsentInformation.instance.canRequestAds,
       _privacyOptionsStatus =
           privacyOptionsStatus ??
           ConsentInformation.instance.getPrivacyOptionsRequirementStatus;

  final ValueNotifier<AdvertisingConsentState> _state = ValueNotifier(
    const AdvertisingConsentState(),
  );
  final GoogleMobileAdsInitializer _mobileAdsInitializer;
  final Future<void> Function() _requestConsentInformationUpdate;
  final Future<void> Function() _loadAndShowConsentFormIfRequired;
  final Future<bool> Function() _canRequestAds;
  final Future<PrivacyOptionsRequirementStatus> Function()
  _privacyOptionsStatus;

  Future<void>? _gathering;
  bool _mobileAdsPrepared = false;
  bool _mobileAdsInitialized = false;

  @override
  ValueListenable<AdvertisingConsentState> get state => _state;

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Future<void> gatherConsent() {
    if (!_isSupportedPlatform) return Future.value();
    return _gathering ??= _gatherConsent();
  }

  Future<void> _gatherConsent() async {
    _state.value = _state.value.copyWith(isGathering: true);
    try {
      await _mobileAdsInitializer.prepare();
      _mobileAdsPrepared = true;
      await _requestConsentInformationUpdate();
      await _loadAndShowConsentFormIfRequired();
    } catch (_) {
      // 前回までに有効な同意が保存されていれば、その状態で広告を続行する。
    } finally {
      try {
        await _refreshState();
      } catch (_) {
        // 同意SDK自体が利用できない場合も、アプリ本体は継続して使えるようにする。
      }
      _state.value = _state.value.copyWith(isGathering: false);
    }
  }

  static Future<void> _pluginRequestConsentInformationUpdate() {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      completer.complete,
      completer.completeError,
    );
    return completer.future.timeout(const Duration(seconds: 15));
  }

  static Future<void> _pluginLoadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    });
    return completer.future.timeout(const Duration(seconds: 30));
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (!_isSupportedPlatform) return;
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    });
    await completer.future.timeout(const Duration(seconds: 30));
    await _refreshState();
  }

  Future<void> _refreshState() async {
    if (!_isSupportedPlatform) return;
    final canRequestAds = await _canRequestAds();
    final privacyStatus = await _privacyOptionsStatus();
    final canSafelyRequestAds = canRequestAds && _mobileAdsPrepared;
    _state.value = _state.value.copyWith(
      canRequestAds: canSafelyRequestAds,
      privacyOptionsRequired:
          privacyStatus == PrivacyOptionsRequirementStatus.required,
    );
    if (canSafelyRequestAds && !_mobileAdsInitialized) {
      _mobileAdsInitialized = true;
      await _mobileAdsInitializer.initialize();
    }
  }
}
