import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/theme/app_colors.dart';
import 'package:instant_estimate/features/calculator/application/calculator_button_feedback.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  testWidgets('音とバイブONでは電卓操作キーごとに両方を1回呼ぶ', (tester) async {
    _setPhoneSize(tester);
    final feedback = _FakeCalculatorButtonFeedback();
    final controller = CalculatorController();
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: controller,
          settings: const AppSettings(
            calculatorTapSoundEnabled: true,
            calculatorHapticsEnabled: true,
          ),
          buttonFeedback: feedback,
        ),
      ),
    );

    for (final label in ['1', '+', 'a/b', '←', '%', '()', '=']) {
      await tester.tap(find.byKey(Key('calculatorKey$label')));
      await tester.pump();
    }

    expect(feedback.soundCount, 7);
    expect(feedback.hapticCount, 7);
  });

  testWidgets('音とバイブOFFではフィードバックを呼ばず電卓操作は続く', (tester) async {
    _setPhoneSize(tester);
    final feedback = _FakeCalculatorButtonFeedback();
    final controller = CalculatorController();
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: controller,
          settings: const AppSettings(
            calculatorTapSoundEnabled: false,
            calculatorHapticsEnabled: false,
          ),
          buttonFeedback: feedback,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('calculatorKey1')));
    await tester.tap(find.byKey(const Key('calculatorKey+')));
    await tester.tap(find.byKey(const Key('calculatorKey2')));
    await tester.pump();

    expect(feedback.soundCount, 0);
    expect(feedback.hapticCount, 0);
    expect(controller.expression, '1+2');
  });

  testWidgets('展開した追加関数ボタンも共通フィードバックを1回呼ぶ', (tester) async {
    _setPhoneSize(tester);
    final feedback = _FakeCalculatorButtonFeedback();
    final controller = CalculatorController();
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: controller,
          settings: const AppSettings(
            calculatorTapSoundEnabled: true,
            calculatorHapticsEnabled: true,
          ),
          buttonFeedback: feedback,
        ),
      ),
    );

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('functionButton0')));
    await tester.pumpAndSettle();

    expect(controller.expression, 'π');
    expect(feedback.soundCount, 1);
    expect(feedback.hapticCount, 1);
  });

  testWidgets('短時間の連打でもキーごとに共通フィードバックを要求し例外を出さない', (tester) async {
    _setPhoneSize(tester);
    final feedback = _FakeCalculatorButtonFeedback();
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          settings: const AppSettings(
            calculatorTapSoundEnabled: true,
            calculatorHapticsEnabled: true,
          ),
          buttonFeedback: feedback,
        ),
      ),
    );

    for (var index = 0; index < 20; index++) {
      await tester.tap(find.byKey(const Key('calculatorKey1')));
    }
    await tester.pump();

    expect(feedback.soundCount, 20);
    expect(feedback.hapticCount, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('分数切替可能時はa/bと＝が同じオレンジになり通常入力で戻る', (tester) async {
    _setPhoneSize(tester);
    final controller = CalculatorController();
    controller.pasteAtCaret('2−1÷2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    Color? background(String label) {
      final button = tester.widget<FilledButton>(
        find.byKey(Key('calculatorKey$label')),
      );
      return button.style?.backgroundColor?.resolve(<WidgetState>{});
    }

    expect(controller.canCycleFraction, isTrue);
    expect(background('a/b'), AppColors.fractionToggle);
    expect(background('='), AppColors.fractionToggle);

    await tester.tap(find.byKey(const Key('calculatorKey=')));
    await tester.pump();
    expect(controller.canCycleFraction, isTrue);
    expect(background('a/b'), AppColors.fractionToggle);
    expect(background('='), AppColors.fractionToggle);

    await tester.tap(find.byKey(const Key('calculatorKey1')));
    await tester.pump();
    expect(controller.canCycleFraction, isFalse);
    expect(background('a/b'), isNot(AppColors.fractionToggle));
    expect(background('='), isNot(AppColors.fractionToggle));

    controller
      ..clear()
      ..pasteAtCaret('1+1')
      ..press('=');
    await tester.pump();
    expect(controller.result, '2');
    expect(controller.canCycleFraction, isFalse);
    expect(background('a/b'), isNot(AppColors.fractionToggle));
    expect(background('='), isNot(AppColors.fractionToggle));
  });
}

void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _FakeCalculatorButtonFeedback implements CalculatorButtonFeedback {
  int soundCount = 0;
  int hapticCount = 0;

  @override
  Future<void> performLightHaptic() async {
    hapticCount += 1;
  }

  @override
  Future<void> playTapSound() async {
    soundCount += 1;
  }
}
