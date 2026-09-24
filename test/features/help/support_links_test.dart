import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/help/presentation/help_screen.dart';
import 'package:instant_estimate/features/help/presentation/support_links_section.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  Widget app({
    required Widget home,
    AppLanguage language = AppLanguage.japanese,
    TargetPlatform platform = TargetPlatform.iOS,
    double textScale = 1,
  }) {
    return MaterialApp(
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
      theme: ThemeData(platform: platform),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    );
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings shows support links and opens the exact HTTPS URLs', (
    tester,
  ) async {
    final opened = <Uri>[];
    var settingsChanges = 0;
    await tester.pumpWidget(
      app(
        home: SettingsScreen(
          settings: const AppSettings(),
          onSettingsChanged: (_) => settingsChanges++,
          onClearHistory: () async {},
          supportLinkLauncher: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );

    await reveal(tester, find.byKey(const Key('settingsSupportSection')));
    expect(find.text('サポート'), findsOneWidget);
    expect(find.text('ご意見・不具合の報告'), findsOneWidget);
    await tester.tap(find.byKey(const Key('supportContactLink')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('supportPrivacyPolicyLink')));
    await tester.pump();

    expect(opened, [Uri.parse(supportUrl), Uri.parse(supportPrivacyPolicyUrl)]);
    expect(opened.every((uri) => uri.scheme == 'https'), isTrue);
    expect(settingsChanges, 0);

    await reveal(tester, find.byKey(const Key('openSourceLicensesSetting')));
    expect(find.byKey(const Key('disclaimerSetting')), findsOneWidget);
    expect(find.byKey(const Key('openSourceLicensesSetting')), findsOneWidget);
  });

  testWidgets('help shows the same support links', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      app(
        home: HelpScreen(
          supportLinkLauncher: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );

    await reveal(tester, find.byKey(const Key('helpSupportSection')));
    expect(find.byKey(const Key('helpSectionDisclaimer')), findsOneWidget);
    expect(find.text('ご意見・不具合の報告'), findsOneWidget);
    expect(find.text('プライバシーポリシー'), findsOneWidget);
    await tester.tap(find.byKey(const Key('supportContactLink')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('supportPrivacyPolicyLink')));
    await tester.pump();

    expect(opened, [Uri.parse(supportUrl), Uri.parse(supportPrivacyPolicyUrl)]);
  });

  testWidgets('shows the localized error when launching returns false', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(home: HelpScreen(supportLinkLauncher: (_) async => false)),
    );
    await reveal(tester, find.byKey(const Key('helpSupportSection')));

    await tester.tap(find.byKey(const Key('supportContactLink')));
    await tester.pump();

    expect(find.text('リンクを開けませんでした'), findsOneWidget);
  });

  testWidgets('shows the localized error when launching throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        home: HelpScreen(
          supportLinkLauncher: (_) => throw StateError('launch failure'),
        ),
      ),
    );
    await reveal(tester, find.byKey(const Key('helpSupportSection')));

    await tester.tap(find.byKey(const Key('supportPrivacyPolicyLink')));
    await tester.pump();

    expect(find.text('リンクを開けませんでした'), findsOneWidget);
  });

  for (final language in AppLanguage.values) {
    testWidgets(
      'support links fit a narrow, large-text ${language.name} layout',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          app(
            language: language,
            textScale: 1.6,
            home: HelpScreen(supportLinkLauncher: (_) async => true),
          ),
        );
        await reveal(tester, find.byKey(const Key('helpSupportSection')));

        final strings = AppLocalizations(language);
        final section = find.byKey(const Key('helpSupportSection'));
        expect(
          find.descendant(
            of: section,
            matching: find.text(strings.supportTitle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: section,
            matching: find.text(strings.reportFeedbackAndIssues),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: section,
            matching: find.text(strings.supportDescription),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: section,
            matching: find.text(strings.privacyPolicy),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('support links work on ${platform.name}', (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        app(
          platform: platform,
          home: SupportLinksSection(
            linkLauncher: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('supportContactLink')));
      await tester.pump();
      expect(opened, [Uri.parse(supportUrl)]);
      expect(tester.takeException(), isNull);
    });
  }
}
