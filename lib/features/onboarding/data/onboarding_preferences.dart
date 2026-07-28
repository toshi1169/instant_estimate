import 'package:flutter/services.dart';

abstract interface class OnboardingPreferences {
  Future<bool> hasSelectedOccupation();
  Future<void> saveOccupation(String occupation);
}

class PlatformOnboardingPreferences implements OnboardingPreferences {
  static const _channel = MethodChannel(
    'jp.instant_estimate/onboarding_preferences',
  );

  @override
  Future<bool> hasSelectedOccupation() async {
    return await _channel.invokeMethod<bool>('hasSelectedOccupation') ?? false;
  }

  @override
  Future<void> saveOccupation(String occupation) {
    return _channel.invokeMethod<void>('saveOccupation', <String, Object>{
      'occupation': occupation,
    });
  }
}
