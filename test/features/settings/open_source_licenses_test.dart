import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/licenses/third_party_licenses.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerThirdPartyLicenses();

  test('registers Noto Sans JP and native Google SDK notices', () async {
    final packages = <String>{};
    final texts = <String>[];
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
      texts.add(entry.paragraphs.map((paragraph) => paragraph.text).join('\n'));
    }

    expect(packages, contains('Noto Sans JP'));
    expect(packages, contains('Google Mobile Ads SDK'));
    expect(packages, contains('Google User Messaging Platform SDK'));
    expect(texts.join('\n'), contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(
      texts.join('\n'),
      contains('https://developers.google.com/admob/terms'),
    );
  });

  for (final language in AppLanguage.values) {
    testWidgets('opens license page without overflow in ${language.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: language.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLanguage.values
              .map((value) => value.locale)
              .toList(),
          home: SettingsScreen(
            settings: AppSettings(language: language),
            onSettingsChanged: (_) {},
            onClearHistory: () async {},
            accessPlan: AppAccessPlan.free,
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('openSourceLicensesSetting')),
        300,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('openSourceLicensesSetting')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(LicensePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
