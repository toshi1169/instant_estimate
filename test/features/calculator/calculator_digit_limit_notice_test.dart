import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  test('20桁通知は8言語で明示的に取得できる', () {
    const expected = <AppLanguage, String>{
      AppLanguage.japanese: '最大20桁まで入力できます',
      AppLanguage.english: 'You can enter up to 20 digits.',
      AppLanguage.simplifiedChinese: '最多可输入20位数字',
      AppLanguage.traditionalChinese: '最多可輸入20位數字',
      AppLanguage.vietnamese: 'Bạn có thể nhập tối đa 20 chữ số.',
      AppLanguage.indonesian: 'Anda dapat memasukkan maksimal 20 digit.',
      AppLanguage.filipino: 'Hanggang 20 digit ang maaaring ilagay.',
      AppLanguage.myanmar: 'ဂဏန်း ၂၀ လုံးအထိ ထည့်သွင်းနိုင်သည်။',
    };

    for (final entry in expected.entries) {
      expect(
        AppLocalizations(entry.key).calculatorDigitLimitNotice,
        entry.value,
      );
    }
  });

  testWidgets('20桁通知Widgetは現在のLocaleの文字列を表示する', (tester) async {
    final controller = CalculatorController();
    await _pumpCalculator(
      tester,
      controller: controller,
      locale: const Locale('en'),
    );
    await _tapDigits(tester, '11111111111111111111');
    await _tapKey(tester, '1');

    expect(find.text('You can enter up to 20 digits.'), findsOneWidget);
    expect(find.text('最大20桁まで入力できます'), findsNothing);
  });

  testWidgets('通知は2秒だけ表示し終了後10秒は連打しても再表示しない', (tester) async {
    final controller = CalculatorController();
    await _pumpCalculator(tester, controller: controller);
    await _tapDigits(tester, '11111111111111111111');

    await _tapKey(tester, '1');
    expect(find.byKey(const Key('digitLimitNotice')), findsOneWidget);
    expect(controller.expression, '11111111111111111111');

    await tester.pump(const Duration(milliseconds: 1500));
    for (var index = 0; index < 10; index++) {
      await _tapKey(tester, '1');
    }
    expect(find.byKey(const Key('digitLimitNotice')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('digitLimitNotice')), findsNothing);

    for (var index = 0; index < 10; index++) {
      await _tapKey(tester, '1');
    }
    expect(find.byKey(const Key('digitLimitNotice')), findsNothing);
    expect(controller.expression, '11111111111111111111');

    await tester.pump(const Duration(seconds: 10));
    await _tapKey(tester, '1');
    expect(find.byKey(const Key('digitLimitNotice')), findsOneWidget);
    expect(controller.expression, '11111111111111111111');
  });

  testWidgets('通知はポインターを遮らず背後の最下段キーを操作できる', (tester) async {
    final controller = CalculatorController();
    await _pumpCalculator(tester, controller: controller);
    await _tapDigits(tester, '11111111111111111111');
    await _tapKey(tester, '1');

    final ignorePointer = tester.widget<IgnorePointer>(
      find.byKey(const Key('digitLimitNoticeIgnorePointer')),
    );
    expect(ignorePointer.ignoring, isTrue);
    expect(find.byKey(const Key('digitLimitNotice')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('digitLimitNotice'))).height,
      lessThan(40),
    );

    await _tapKey(tester, '=');
    expect(controller.result, isNotEmpty);
    expect(find.byKey(const Key('digitLimitNotice')), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}テーマで通知背景は透過し文字を判読できる', (tester) async {
      final controller = CalculatorController();
      await _pumpCalculator(
        tester,
        controller: controller,
        brightness: brightness,
      );
      await _tapDigits(tester, '11111111111111111111');
      await _tapKey(tester, '1');

      final text = tester.widget<Text>(
        find.byKey(const Key('digitLimitNoticeText')),
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.byKey(const Key('digitLimitNoticeText')),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      final background = decoration.color!;
      final foreground = text.style!.color!;

      expect(background.a, lessThan(1));
      expect(_contrastRatio(background, foreground), greaterThan(4.5));
    });
  }

  testWidgets('通常数値・分子・分母は21桁目を拒否し通知クールダウンを共有する', (tester) async {
    final controller = CalculatorController();
    await _pumpCalculator(tester, controller: controller);

    await _tapDigits(tester, '12345678901234567890');
    await _tapKey(tester, '1');
    expect(controller.expression, '12345678901234567890');
    expect(find.byKey(const Key('digitLimitNotice')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    controller.clear();
    await tester.pump();
    await _tapKey(tester, 'a/b');
    await _tapDigits(tester, '11111111111111111111');
    await _tapKey(tester, '1');
    var fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(fraction.numerator, '11111111111111111111');
    expect(find.byKey(const Key('digitLimitNotice')), findsNothing);

    await _tapKey(tester, 'a/b');
    await _tapDigits(tester, '22222222222222222222');
    await _tapKey(tester, '2');
    fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;
    expect(fraction.denominator, '22222222222222222222');
    expect(find.byKey(const Key('digitLimitNotice')), findsNothing);
  });

  testWidgets('20桁通知のクールダウン中も他の警告は通常表示する', (tester) async {
    final controller = CalculatorController();
    await _pumpCalculator(tester, controller: controller);
    await _tapDigits(tester, '11111111111111111111');
    await _tapKey(tester, '1');
    await tester.pump(const Duration(seconds: 2));

    controller.clear();
    await tester.pump();
    await _tapKey(tester, '2');
    await _tapKey(tester, '=');
    await _tapKey(tester, 'a/b');
    await tester.pump();

    expect(find.text('分数に変換できません'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

Future<void> _pumpCalculator(
  WidgetTester tester, {
  required CalculatorController controller,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('ja'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLanguage.values.map((value) => value.locale),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(brightness: brightness),
      home: CalculatorScreen(
        controller: controller,
        settings: const AppSettings(
          calculatorTapSoundEnabled: false,
          calculatorHapticsEnabled: false,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _tapDigits(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await _tapKey(tester, digit);
  }
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(Key('calculatorKey$label')));
  await tester.pump();
}

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
