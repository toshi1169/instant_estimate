import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';
import 'package:instant_estimate/features/settings/presentation/company_profile_editor_screen.dart';
import 'package:instant_estimate/features/settings/presentation/company_profile_text_guidance.dart';

void main() {
  group('company profile text guidance metrics', () {
    test('uses the six Japanese field limits', () {
      const expected = {
        CompanyProfileSection.companyName: 14,
        CompanyProfileSection.representativeName: 14,
        CompanyProfileSection.postalCode: 24,
        CompanyProfileSection.addressLine1: 14,
        CompanyProfileSection.addressLine2: 14,
        CompanyProfileSection.phoneNumber: 24,
      };

      for (final entry in expected.entries) {
        final atLimit = CompanyProfileTextGuidanceMetrics.evaluate(
          _repeat('文', entry.value),
          AppLanguage.japanese,
          entry.key,
        );
        final overLimit = CompanyProfileTextGuidanceMetrics.evaluate(
          _repeat('文', entry.value + 1),
          AppLanguage.japanese,
          entry.key,
        );
        expect(atLimit.characterLimit, entry.value, reason: entry.key.name);
        expect(atLimit.lineLimit, 1, reason: entry.key.name);
        expect(atLimit.exceeded, isFalse, reason: entry.key.name);
        expect(overLimit.exceeded, isTrue, reason: entry.key.name);
      }
    });

    test('uses language-specific name and address limits', () {
      const expected = {
        AppLanguage.japanese: 14,
        AppLanguage.english: 24,
        AppLanguage.simplifiedChinese: 14,
        AppLanguage.traditionalChinese: 14,
        AppLanguage.vietnamese: 24,
        AppLanguage.indonesian: 24,
        AppLanguage.filipino: 24,
        AppLanguage.myanmar: 20,
      };
      for (final entry in expected.entries) {
        for (final section in const [
          CompanyProfileSection.companyName,
          CompanyProfileSection.representativeName,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.addressLine2,
        ]) {
          expect(
            companyProfileCharacterLimit(entry.key, section),
            entry.value,
            reason: '${entry.key.name}/${section.name}',
          );
        }
        expect(
          companyProfileCharacterLimit(
            entry.key,
            CompanyProfileSection.postalCode,
          ),
          24,
        );
        expect(
          companyProfileCharacterLimit(
            entry.key,
            CompanyProfileSection.phoneNumber,
          ),
          24,
        );
      }
    });

    test(
      'counts graphemes and explicit lines including a trailing newline',
      () {
        final emoji = CompanyProfileTextGuidanceMetrics.evaluate(
          '👨‍👩‍👧‍👦',
          AppLanguage.japanese,
          CompanyProfileSection.companyName,
        );
        expect(emoji.characters, 1);
        expect(emoji.lines, 1);
        expect(emoji.longestLineCharacters, 1);
        expect(emoji.exceeded, isFalse);

        final combining = CompanyProfileTextGuidanceMetrics.evaluate(
          'e\u0301',
          AppLanguage.english,
          CompanyProfileSection.companyName,
        );
        expect(combining.characters, 1);

        final trailing = CompanyProfileTextGuidanceMetrics.evaluate(
          '会社名\n',
          AppLanguage.japanese,
          CompanyProfileSection.companyName,
        );
        expect(trailing.lines, 2);
        expect(trailing.exceeded, isTrue);
        expect(
          CompanyProfileTextGuidanceMetrics.evaluate(
            '会社名\n支店',
            AppLanguage.japanese,
            CompanyProfileSection.companyName,
          ).exceeded,
          isTrue,
        );
      },
    );

    test('accepts practical postal-code and telephone characters at limit', () {
      for (final value in ['〒123-4567 SW1A 1AA', '+81 (3) 1234-5678']) {
        final section = value.startsWith('〒')
            ? CompanyProfileSection.postalCode
            : CompanyProfileSection.phoneNumber;
        final metrics = CompanyProfileTextGuidanceMetrics.evaluate(
          value,
          AppLanguage.japanese,
          section,
        );
        expect(metrics.characters, lessThanOrEqualTo(24));
        expect(metrics.exceeded, isFalse);
      }
    });
  });

  testWidgets(
    'all six fields show their counters and long text remains savable',
    (tester) async {
      CompanyProfile? saved;
      await tester.pumpWidget(
        _app(
          language: AppLanguage.japanese,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<CompanyProfile>(
                  MaterialPageRoute(
                    builder: (_) => const CompanyProfileEditorScreen(
                      initialProfile: CompanyProfile(),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      const expected = {
        CompanyProfileSection.companyName: 14,
        CompanyProfileSection.representativeName: 14,
        CompanyProfileSection.postalCode: 24,
        CompanyProfileSection.addressLine1: 14,
        CompanyProfileSection.addressLine2: 14,
        CompanyProfileSection.phoneNumber: 24,
      };
      for (final entry in expected.entries) {
        final counter = find.byKey(
          Key('companyProfileTextCounter-${entry.key.name}'),
        );
        await _reveal(tester, counter);
        expect(counter, findsOneWidget);
        expect(find.text('0 / ${entry.value}文字'), findsWidgets);
        expect(find.text('1 / 1行'), findsWidgets);
      }

      const longValue = '非常に長い会社名でも入力と保存を制限せずそのまま維持する会社';
      final field = find.byKey(const Key('companyProfileCompanyName'));
      await _reveal(tester, field);
      await tester.enterText(field, longValue);
      await tester.pump();
      expect(
        find.byKey(const Key('companyProfileTextWarning-companyName')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('saveCompanyProfile')));
      await tester.pumpAndSettle();
      expect(saved?.companyName, longValue);
    },
  );

  testWidgets('existing long text is preserved and can be saved again', (
    tester,
  ) async {
    const longValue = '既存バックアップから読み込んだとても長い会社名を一文字も変更しない';
    CompanyProfile? saved;
    await tester.pumpWidget(
      _app(
        language: AppLanguage.japanese,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<CompanyProfile>(
                MaterialPageRoute(
                  builder: (_) => const CompanyProfileEditorScreen(
                    initialProfile: CompanyProfile(companyName: longValue),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('companyProfileTextWarning-companyName')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('saveCompanyProfile')));
    await tester.pumpAndSettle();
    expect(saved?.companyName, longValue);
  });

  testWidgets('eight languages fit at 320px and large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final language in AppLanguage.values) {
      final controller = TextEditingController(text: _repeat('a', 30));
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          language: language,
          textScale: 1.6,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CompanyProfileTextGuidance(
                controller: controller,
                section: CompanyProfileSection.companyName,
              ),
            ),
          ),
        ),
      );
      final l10n = AppLocalizations(language);
      expect(
        find.text(l10n.companyProfileTextGuidanceExceeded),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: language.name);
    }
  });
}

Widget _app({
  required AppLanguage language,
  required Widget home,
  double textScale = 1,
}) => MaterialApp(
  locale: language.locale,
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLanguage.values.map((value) => value.locale).toList(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

String _repeat(String value, int count) => List.filled(count, value).join();
