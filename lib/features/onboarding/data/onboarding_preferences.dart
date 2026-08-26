import 'package:flutter/services.dart';

abstract interface class OnboardingPreferences {
  Future<bool> hasSelectedOccupation();
  Future<String?> loadOccupation();
  Future<void> saveOccupation(String occupation);
}

abstract interface class LanguageOnboardingPreferences {
  Future<bool> hasSelectedLanguage();
  Future<void> saveLanguage(String language);
}

class PlatformOnboardingPreferences
    implements OnboardingPreferences, LanguageOnboardingPreferences {
  static const _channel = MethodChannel(
    'jp.instant_estimate/onboarding_preferences',
  );

  @override
  Future<bool> hasSelectedOccupation() async {
    return await _channel.invokeMethod<bool>('hasSelectedOccupation') ?? false;
  }

  @override
  Future<String?> loadOccupation() {
    return _channel.invokeMethod<String>('loadOccupation');
  }

  @override
  Future<void> saveOccupation(String occupation) {
    return _channel.invokeMethod<void>('saveOccupation', <String, Object>{
      'occupation': occupation,
    });
  }

  @override
  Future<bool> hasSelectedLanguage() async {
    return await _channel.invokeMethod<bool>('hasSelectedLanguage') ?? false;
  }

  @override
  Future<void> saveLanguage(String language) {
    return _channel.invokeMethod<void>('saveLanguage', <String, Object>{
      'language': language,
    });
  }
}
