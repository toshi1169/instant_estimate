import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_info_editor_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_item_editor_screen.dart';
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

    test('Japanese and Traditional Chinese use the 40 / 2 thresholds', () {
      for (final language in [
        AppLanguage.japanese,
        AppLanguage.traditionalChinese,
      ]) {
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

    expect(find.text('0 / 40文字'), findsOneWidget);
    expect(find.text('1 / 2行'), findsOneWidget);
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
