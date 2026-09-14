import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _registered = false;

void registerThirdPartyLicenses() {
  if (_registered) return;
  _registered = true;

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/NotoSansJP-OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(<String>['Noto Sans JP'], license);
  });

  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['Google Mobile Ads SDK', 'Google User Messaging Platform SDK'],
      '''
Copyright Google LLC.

This application uses the Google Mobile Ads SDK and Google User Messaging Platform SDK.

Google Mobile Ads SDK Terms of Service:
https://developers.google.com/admob/terms

Google Privacy Policy:
https://policies.google.com/privacy
''',
    );
  });
}
