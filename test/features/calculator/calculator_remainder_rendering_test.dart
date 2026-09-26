import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/calculator/application/calculator_button_feedback.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  const remainderOnlySettings = AppSettings(
    improperFractionResultEnabled: false,
    mixedFractionResultEnabled: false,
    remainderResultEnabled: true,
  );

  testWidgets('対象計算の余りを通常Textとして表示する', (tester) async {
    _setPhoneSize(tester);
    for (final testCase in const [
      ('7÷3', '2 余り 1'),
      ('6÷3', '2 余り 0'),
      ('2÷3', '0 余り 2'),
      ('0÷3', '0 余り 0'),
      ('7÷(1+2)', '2 余り 1'),
    ]) {
      final controller = CalculatorController();
      await _pumpCalculator(
        tester,
        controller: controller,
        settings: remainderOnlySettings,
      );
      controller
        ..pasteAtCaret(testCase.$1)
        ..press('=');
      await tester.pump();

      await tester.tap(find.byKey(const Key('calculatorKey=')));
      await tester.pump();

      expect(controller.resultDisplayMode, ResultDisplayMode.remainder);
      final result = tester.widget<Text>(find.byKey(const Key('resultText')));
      expect(_plainText(result), '=  ${testCase.$2}');
      expect(result.maxLines, 1);
      expect(result.textAlign, TextAlign.right);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('結果確定後のa/bでも余りを通常Textとして表示する', (tester) async {
    _setPhoneSize(tester);
    final controller = CalculatorController();
    await _pumpCalculator(
      tester,
      controller: controller,
      settings: remainderOnlySettings,
    );
    controller
      ..pasteAtCaret('7÷3')
      ..press('=');
    await tester.pump();

    await tester.tap(find.byKey(const Key('calculatorKeya/b')));
    await tester.pump();

    expect(controller.resultDisplayMode, ResultDisplayMode.remainder);
    expect(
      _plainText(tester.widget<Text>(find.byKey(const Key('resultText')))),
      '=  2 余り 1',
    );
  });

  testWidgets('小数はText、仮分数と帯分数は積み上げ表示を維持する', (tester) async {
    _setPhoneSize(tester);
    final controller = CalculatorController();
    await _pumpCalculator(
      tester,
      controller: controller,
      settings: const AppSettings(
        improperFractionResultEnabled: true,
        mixedFractionResultEnabled: true,
        remainderResultEnabled: false,
      ),
    );
    controller
      ..pasteAtCaret('7÷3')
      ..press('=');
    await tester.pump();

    expect(
      find.byKey(const Key('resultText')).evaluate().single.widget,
      isA<Text>(),
    );
    await tester.tap(find.byKey(const Key('calculatorKey=')));
    await tester.pump();
    expect(controller.resultDisplayMode, ResultDisplayMode.improperFraction);
    expect(
      find.byKey(const Key('resultText')).evaluate().single.widget,
      isA<Row>(),
    );
    await tester.tap(find.byKey(const Key('calculatorKeya/b')));
    await tester.pump();
    expect(controller.resultDisplayMode, ResultDisplayMode.mixedFraction);
    expect(
      find.byKey(const Key('resultText')).evaluate().single.widget,
      isA<Row>(),
    );
  });

  testWidgets('長い余り結果をiPhone 11 Pro相当幅でoverflowなく表示する', (tester) async {
    _setPhoneSize(tester);
    final controller = CalculatorController();
    await _pumpCalculator(
      tester,
      controller: controller,
      settings: remainderOnlySettings,
    );
    controller
      ..pasteAtCaret('99999999999999999999÷7')
      ..press('=')
      ..press('=');
    await tester.pump();

    expect(
      _plainText(tester.widget<Text>(find.byKey(const Key('resultText')))),
      '=  14285714285714285714 余り 1',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('8言語で商と余り値は100%、余り語だけ50%で表示する', (tester) async {
    _setPhoneSize(tester);
    for (final language in AppLanguage.values) {
      final controller = CalculatorController();
      await _pumpCalculator(
        tester,
        controller: controller,
        settings: remainderOnlySettings,
        locale: language.locale,
      );
      controller
        ..pasteAtCaret('7÷3')
        ..press('=')
        ..press('=');
      await tester.pump();

      final strings = AppLocalizations(language);
      final result = tester.widget<Text>(find.byKey(const Key('resultText')));
      final spans = (result.textSpan! as TextSpan).children!;
      expect(
        _plainText(result),
        '=  ${strings.remainderText('2', '1')}',
        reason: language.name,
      );
      expect(result.style?.fontSize, 42, reason: language.name);
      expect(
        (spans[0] as TextSpan).style?.fontSize,
        isNull,
        reason: language.name,
      );
      expect(
        (spans[1] as TextSpan).text,
        strings.remainderInlineWord,
        reason: language.name,
      );
      expect((spans[1] as TextSpan).style?.fontSize, 21, reason: language.name);
      expect(
        (spans[2] as TextSpan).style?.fontSize,
        isNull,
        reason: language.name,
      );
      expect(result.maxLines, 1, reason: language.name);
      expect(result.textAlign, TextAlign.right, reason: language.name);
      expect(tester.takeException(), isNull, reason: language.name);
    }
  });

  testWidgets('320px幅でも大きな商・余り値を右寄せ1行で縮小表示する', (tester) async {
    _setPhoneSize(tester, width: 320, height: 568);
    final controller = CalculatorController();
    await _pumpCalculator(
      tester,
      controller: controller,
      settings: remainderOnlySettings,
    );
    controller
      ..pasteAtCaret('99999999999999999999÷88888888888888888888')
      ..press('=')
      ..press('=');
    await tester.pump();

    final resultFinder = find.byKey(const Key('resultText'));
    final result = tester.widget<Text>(resultFinder);
    expect(_plainText(result), '=  1 余り 11111111111111111111');
    expect(result.maxLines, 1);
    expect(result.textAlign, TextAlign.right);
    final fittedBox = tester.widget<FittedBox>(
      find.ancestor(of: resultFinder, matching: find.byType(FittedBox)).first,
    );
    expect(fittedBox.fit, BoxFit.scaleDown);
    expect(fittedBox.alignment, Alignment.centerRight);
    expect(tester.takeException(), isNull);
  });
}

String _plainText(Text text) => text.data ?? text.textSpan!.toPlainText();

Future<void> _pumpCalculator(
  WidgetTester tester, {
  required CalculatorController controller,
  required AppSettings settings,
  Locale locale = const Locale('ja'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLanguage.values.map((language) => language.locale),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: CalculatorScreen(
        key: ValueKey(controller),
        controller: controller,
        settings: settings,
        buttonFeedback: const _NoopCalculatorButtonFeedback(),
      ),
    ),
  );
  await tester.pump();
}

void _setPhoneSize(
  WidgetTester tester, {
  double width = 375,
  double height = 812,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _NoopCalculatorButtonFeedback implements CalculatorButtonFeedback {
  const _NoopCalculatorButtonFeedback();

  @override
  Future<void> performLightHaptic() async {}

  @override
  Future<void> playTapSound() async {}
}
