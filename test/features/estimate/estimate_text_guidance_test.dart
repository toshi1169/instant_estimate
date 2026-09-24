import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_info_editor_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_item_editor_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_pdf_script_notice.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_text_guidance.dart';
import 'package:instant_estimate/features/estimate/presentation/unit_price_master_editor_screen.dart';

void main() {
  group('estimate text guidance metrics', () {
    test('counts graphemes, explicit lines, and a trailing newline', () {
      final emoji = EstimateTextGuidanceMetrics.evaluate(
        '👨‍👩‍👧‍👦',
        AppLanguage.japanese,
      );
      expect(emoji.characters, 1);
      expect(emoji.lines, 1);
      expect(emoji.longestLineCharacters, 1);

      final trailing = EstimateTextGuidanceMetrics.evaluate(
        '文字\n',
        AppLanguage.japanese,
      );
      expect(trailing.characters, 3);
      expect(trailing.lines, 2);
      expect(trailing.longestLineCharacters, 2);
      expect(trailing.state, EstimateTextGuidanceState.caution);
    });

    test('Japanese uses displayed character and explicit-line limits', () {
      final within39 = EstimateTextGuidanceMetrics.evaluate(
        _repeat('a', 39),
        AppLanguage.japanese,
      );
      expect(within39.characters, 39);
      expect(within39.lines, 1);
      expect(within39.state, EstimateTextGuidanceState.caution);

      final within40TwoLines = EstimateTextGuidanceMetrics.evaluate(
        '${_repeat('a', 20)}\n${_repeat('b', 19)}',
        AppLanguage.japanese,
      );
      expect(within40TwoLines.characters, 40);
      expect(within40TwoLines.lines, 2);
      expect(within40TwoLines.state, EstimateTextGuidanceState.caution);
      expect(
        EstimateTextGuidanceMetrics.evaluate(
          _repeat('a', 41),
          AppLanguage.japanese,
        ).state,
        EstimateTextGuidanceState.exceeded,
      );
      expect(
        EstimateTextGuidanceMetrics.evaluate(
          'a\nb\nc',
          AppLanguage.japanese,
        ).state,
        EstimateTextGuidanceState.exceeded,
      );
    });

    test('Japanese field-specific 20 / 1 limits match the counter', () {
      EstimateTextGuidanceMetrics metrics(String value) =>
          EstimateTextGuidanceMetrics.evaluate(
            value,
            AppLanguage.japanese,
            japaneseCharacterLimit: 20,
            japaneseLineLimit: 1,
          );

      expect(metrics(_repeat('a', 20)).state, EstimateTextGuidanceState.normal);
      expect(
        metrics(_repeat('a', 21)).state,
        EstimateTextGuidanceState.exceeded,
      );
      expect(metrics('a\nb').state, EstimateTextGuidanceState.exceeded);
      expect(metrics('a\n').lines, 2);
      expect(metrics('a\n').state, EstimateTextGuidanceState.exceeded);
    });

    test('Traditional Chinese keeps the existing 40 / 2 thresholds', () {
      for (final language in [AppLanguage.traditionalChinese]) {
        expect(
          EstimateTextGuidanceMetrics.evaluate(
            _repeat('a', 20),
            language,
          ).state,
          EstimateTextGuidanceState.normal,
        );
        expect(
          EstimateTextGuidanceMetrics.evaluate(
            _repeat('a', 21),
            language,
          ).state,
          EstimateTextGuidanceState.caution,
        );
        expect(
          EstimateTextGuidanceMetrics.evaluate(
            _repeat('a', 29),
            language,
          ).state,
          EstimateTextGuidanceState.exceeded,
        );
        expect(
          EstimateTextGuidanceMetrics.evaluate(
            '${_repeat('a', 20)}\n${_repeat('b', 19)}',
            language,
          ).state,
          EstimateTextGuidanceState.caution,
        );
        expect(
          EstimateTextGuidanceMetrics.evaluate('a\nb\nc', language).state,
          EstimateTextGuidanceState.exceeded,
        );
      }
    });

    test('Japanese field overrides do not replace foreign-language rules', () {
      final english = EstimateTextGuidanceMetrics.evaluate(
        _repeat('a', 21),
        AppLanguage.english,
        japaneseCharacterLimit: 20,
        japaneseLineLimit: 1,
      );
      expect(english.characterLimit, 30);
      expect(english.lineLimit, 2);
      expect(english.state, EstimateTextGuidanceState.caution);
    });

    test('English, Vietnamese, Indonesian, and Filipino use 30 / 2', () {
      for (final language in [
        AppLanguage.english,
        AppLanguage.vietnamese,
        AppLanguage.indonesian,
        AppLanguage.filipino,
      ]) {
        final normal = EstimateTextGuidanceMetrics.evaluate(
          _repeat('a', 20),
          language,
        );
        expect(normal.characterLimit, 30);
        expect(normal.lineLimit, 2);
        expect(normal.state, EstimateTextGuidanceState.normal);
        expect(
          EstimateTextGuidanceMetrics.evaluate(
            _repeat('a', 21),
            language,
          ).state,
          EstimateTextGuidanceState.caution,
        );
        expect(
          EstimateTextGuidanceMetrics.evaluate(
            _repeat('a', 31),
            language,
          ).state,
          EstimateTextGuidanceState.exceeded,
        );
      }
    });

    test('Simplified Chinese and Myanmar use 20 / 1 without caution', () {
      for (final language in [
        AppLanguage.simplifiedChinese,
        AppLanguage.myanmar,
      ]) {
        final normal = EstimateTextGuidanceMetrics.evaluate(
          _repeat('a', 20),
          language,
        );
        expect(normal.characterLimit, 20);
        expect(normal.lineLimit, 1);
        expect(normal.state, EstimateTextGuidanceState.normal);
        expect(
          EstimateTextGuidanceMetrics.evaluate(
            _repeat('a', 21),
            language,
          ).state,
          EstimateTextGuidanceState.exceeded,
        );
        expect(
          EstimateTextGuidanceMetrics.evaluate('a\nb', language).state,
          EstimateTextGuidanceState.exceeded,
        );
      }
    });
  });

  testWidgets('notes guidance updates without restricting saved text', (
    tester,
  ) async {
    EstimateInfo? result;
    await tester.pumpWidget(
      _app(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<EstimateInfo>(
                MaterialPageRoute(
                  builder: (_) => EstimateInfoEditorScreen(
                    initialInfo: EstimateInfo.initial(DateTime(2026, 9, 25)),
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
    await _reveal(tester, find.byKey(const Key('estimateInfoNotesField')));

    expect(find.text('0 / 40文字'), findsWidgets);
    expect(find.text('1 / 2行'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('estimateInfoNotesField')),
      '${_repeat('長', 20)}\n${_repeat('文', 20)}\n末尾',
    );
    await tester.pump();
    expect(find.textContaining('帳票の推奨範囲を超えています'), findsOneWidget);

    await _reveal(tester, find.byKey(const Key('saveEstimateInfo')));
    await tester.tap(find.byKey(const Key('saveEstimateInfo')));
    await tester.pumpAndSettle();
    expect(result?.notes, '${_repeat('長', 20)}\n${_repeat('文', 20)}\n末尾');
  });

  testWidgets(
    'estimate info exposes the Japanese guidance for all six fields',
    (tester) async {
      await tester.pumpWidget(
        _app(
          home: EstimateInfoEditorScreen(
            initialInfo: EstimateInfo.initial(DateTime(2026, 9, 25)),
          ),
        ),
      );

      for (final key in const [
        'estimateInfoNameGuidance',
        'estimateInfoProvisoGuidance',
        'estimateInfoValidityPeriodGuidance',
        'estimateInfoConstructionPeriodGuidance',
        'estimateInfoPaymentTermsGuidance',
        'estimateInfoNotesGuidance',
      ]) {
        await _reveal(tester, find.byKey(Key(key)));
        expect(find.byKey(Key(key)), findsOneWidget);
      }

      await _reveal(
        tester,
        find.byKey(const Key('estimateInfoValidityPeriodField')),
      );
      expect(find.text('0 / 20文字'), findsWidgets);
      expect(find.text('1 / 1行'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('estimateInfoValidityPeriodField')),
        _repeat('有', 21),
      );
      await tester.pump();
      expect(find.textContaining('帳票の推奨範囲を超えています'), findsOneWidget);
    },
  );

  testWidgets('estimate editors move focus and dismiss it on an outside tap', (
    tester,
  ) async {
    Future<void> verify({
      required Widget screen,
      required Key firstKey,
      required Key secondKey,
      required String title,
    }) async {
      await tester.pumpWidget(_app(home: screen));
      final first = find.byKey(firstKey);
      final second = find.byKey(secondKey);
      await _reveal(tester, first);
      await tester.tap(first);
      await tester.enterText(first, 'first');
      await _reveal(tester, second);
      await tester.tap(second);
      await tester.pump();
      expect(_editable(tester, first).focusNode.hasFocus, isFalse);
      expect(_editable(tester, second).focusNode.hasFocus, isTrue);
      await tester.enterText(second, 'second');
      await tester.tap(find.text(title).first);
      await tester.pump();
      expect(_editable(tester, second).focusNode.hasFocus, isFalse);
      expect(_editable(tester, first).controller.text, 'first');
      expect(_editable(tester, second).controller.text, 'second');
    }

    await verify(
      screen: EstimateInfoEditorScreen(
        initialInfo: EstimateInfo.initial(DateTime(2026, 9, 25)),
      ),
      firstKey: const Key('estimateInfoNameField'),
      secondKey: const Key('estimateInfoProvisoField'),
      title: '見積基本情報',
    );
    await verify(
      screen: const EstimateItemEditorScreen(
        initialDraft: EstimateItemDraft(),
        isEditing: true,
      ),
      firstKey: const Key('estimateNameField'),
      secondKey: const Key('estimateSpecificationField'),
      title: '見積明細を編集',
    );
    await verify(
      screen: const UnitPriceMasterEditorScreen(isEditing: true),
      firstKey: const Key('unitPriceNameField'),
      secondKey: const Key('unitPriceSpecificationField'),
      title: '単価を編集',
    );
  });

  testWidgets('estimate item shows guidance for the four target fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        textScale: 1.6,
        home: const EstimateItemEditorScreen(
          initialDraft: EstimateItemDraft(),
          isEditing: true,
        ),
      ),
    );

    for (final key in const [
      'estimateConstructionLocationGuidance',
      'estimateNameGuidance',
      'estimateSpecificationGuidance',
      'estimateDescriptionGuidance',
    ]) {
      await _reveal(tester, find.byKey(Key(key)));
      expect(find.byKey(Key(key)), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('unit price master shows guidance for corresponding fields', (
    tester,
  ) async {
    await tester.pumpWidget(_app(home: const UnitPriceMasterEditorScreen()));
    for (final key in const [
      'unitPriceNameGuidance',
      'unitPriceSpecificationGuidance',
      'unitPriceDescriptionGuidance',
    ]) {
      await _reveal(tester, find.byKey(Key(key)));
      expect(find.byKey(Key(key)), findsOneWidget);
    }
  });

  testWidgets('all eight languages expose localized counters and warnings', (
    tester,
  ) async {
    for (final language in AppLanguage.values) {
      final controller = TextEditingController(text: _repeat('a', 41));
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          language: language,
          home: Scaffold(
            body: EstimateTextGuidance(
              controller: controller,
              counterKey: const Key('counter'),
            ),
          ),
        ),
      );
      final l10n = AppLocalizations(language);
      expect(find.text(l10n.estimateTextGuidanceExceeded), findsOneWidget);
      expect(find.byKey(const Key('counter')), findsOneWidget);
    }
  });

  testWidgets(
    'PDF script notice appears only for Simplified Chinese and Myanmar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final language in AppLanguage.values) {
        await tester.pumpWidget(
          _app(
            language: language,
            textScale: 1.6,
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EstimatePdfScriptNotice(
                  key: Key('standalonePdfScriptNotice'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final expectsNotice =
            language == AppLanguage.simplifiedChinese ||
            language == AppLanguage.myanmar;
        final notice = AppLocalizations(language).formalPdfScriptSupportNotice;
        if (notice != null) {
          expect(find.text(notice), findsOneWidget);
        } else {
          expect(expectsNotice, isFalse, reason: language.name);
          expect(find.byType(Icon), findsNothing, reason: language.name);
        }
        expect(tester.takeException(), isNull, reason: language.name);
      }

      await tester.pumpWidget(
        _app(
          language: AppLanguage.simplifiedChinese,
          home: const EstimateItemEditorScreen(
            initialDraft: EstimateItemDraft(),
            isEditing: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('estimateItemPdfScriptNotice')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('estimateNameGuidance')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _app({
  required Widget home,
  AppLanguage language = AppLanguage.japanese,
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
    supportedLocales: AppLanguage.values.map((value) => value.locale).toList(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

String _repeat(String value, int count) => List.filled(count, value).join();

EditableText _editable(WidgetTester tester, Finder field) =>
    tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
