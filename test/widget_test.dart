import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/app/app.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/onboarding/data/onboarding_preferences.dart';

class FakeOnboardingPreferences implements OnboardingPreferences {
  FakeOnboardingPreferences({required this.hasSelected});

  bool hasSelected;
  String? savedOccupation;

  @override
  Future<bool> hasSelectedOccupation() async => hasSelected;

  @override
  Future<void> saveOccupation(String occupation) async {
    savedOccupation = occupation;
    hasSelected = true;
  }
}

void main() {
  testWidgets('初回起動では業種選択を表示する', (tester) async {
    final preferences = FakeOnboardingPreferences(hasSelected: false);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    expect(find.text('業種を選択'), findsOneWidget);
    expect(find.text('建築監督'), findsOneWidget);
  });

  testWidgets('選択済みの通常起動では電卓を表示する', (tester) async {
    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historyPanel')), findsOneWidget);
    expect(find.bySemanticsLabel('a/b'), findsOneWidget);
  });

  testWidgets('業種を保存すると電卓へ移動する', (tester) async {
    final preferences = FakeOnboardingPreferences(hasSelected: false);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('土木監督'));
    await tester.pump();
    await tester.tap(find.text('この業種で始める'));
    await tester.pumpAndSettle();

    expect(preferences.savedOccupation, '土木監督');
    expect(find.byKey(const Key('historyPanel')), findsOneWidget);
  });

  testWidgets('電卓ボタンから四則演算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    for (final key in ['1', '2', '+', '3', '=']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }

    expect(find.text('=  15'), findsOneWidget);
    expect(find.byKey(const Key('calculatorCaret')), findsNothing);
  });

  testWidgets('計算スペースの長押しで編集メニューを表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('calculationSpace')));
    await tester.pumpAndSettle();

    expect(find.text('コピー'), findsOneWidget);
    expect(find.text('カット'), findsOneWidget);
    expect(find.text('ペースト'), findsOneWidget);
    expect(find.text('消去'), findsOneWidget);
    expect(find.text('見積へ送る'), findsOneWidget);
  });

  testWidgets('a/bボタンから分数枠を入力して計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('a/b'));
    await tester.pump();
    expect(find.text('□'), findsNWidgets(2));

    for (final key in ['1', 'a/b', '2', 'a/b', '=']) {
      final finder = key == 'a/b'
          ? find.bySemanticsLabel('a/b')
          : find.text(key);
      await tester.tap(finder);
      await tester.pump();
    }

    expect(find.text('=  0.5'), findsOneWidget);
  });

  testWidgets('10桁分数は入力中と右側キャレットでエラーを出さない', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('a/b'));
    for (final key in '1234567890'.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, key));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('a/b'));
    for (final key in '0987654321'.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, key));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('a/b'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('calculatorCaret')), findsOneWidget);
    expect(find.byKey(const Key('expressionTrailingTapArea')), findsNothing);
  });

  testWidgets('複数の10桁分数を含む長い式は全体を縮小して表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    const keys = [
      'a/b',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      'a/b',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      'a/b',
      '×',
      'a/b',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      'a/b',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      'a/b',
    ];
    for (final key in keys) {
      final finder = key == 'a/b'
          ? find.bySemanticsLabel('a/b')
          : find.widgetWithText(FilledButton, key);
      await tester.tap(finder);
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('分数の11桁目では2秒間入力上限を通知する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('a/b'));
    for (var index = 0; index < 11; index++) {
      await tester.tap(find.widgetWithText(FilledButton, '1'));
      await tester.pump();
    }

    expect(find.text('これ以上入力できません'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('これ以上入力できません'), findsNothing);
  });

  testWidgets('帯分数の各欄と左右へキャレットを移動できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    for (final key in ['2', '0', 'a/b', '1', '2', 'a/b', '3', '4']) {
      controller.press(key);
    }
    final fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;

    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    for (final field in FractionField.values) {
      controller.activateFraction(fraction.marker, field, caretOffset: 1);
      await tester.pump();
      expect(find.byKey(const Key('fractionFieldCaret')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('fractionAfterTapArea')));
    await tester.pump();
    expect(controller.isEditingFraction, isFalse);
    expect(find.byKey(const Key('calculatorCaret')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fractionBeforeTapArea')));
    await tester.pump();
    expect(controller.caretPosition, 0);
  });

  testWidgets('長い式でも分数前後の数字と演算子へキャレットを移動できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('66×55×');
    for (final key in ['a/b', '1', 'a/b', '1', 'a/b']) {
      controller.press(key);
    }
    controller.pasteAtCaret('×222×3333');

    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    Future<void> tapCharacter(
      String containedText,
      int offsetWithinContainedText,
    ) async {
      final finder = find.textContaining(containedText);
      final text = tester.widget<Text>(finder).data!;
      final characterIndex =
          text.indexOf(containedText) + offsetWithinContainedText;
      final rect = tester.getRect(finder);
      final painter = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(fontSize: 42)),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = painter.getOffsetForCaret(
        TextPosition(offset: characterIndex),
        Rect.zero,
      );
      final right = painter.getOffsetForCaret(
        TextPosition(offset: characterIndex + 1),
        Rect.zero,
      );
      final localCenter = (left.dx + right.dx) / 2;
      await tester.tapAt(
        Offset(
          rect.left + localCenter * rect.width / painter.width,
          rect.center.dy,
        ),
      );
      await tester.pump();
    }

    await tapCharacter('66', 0);
    expect(controller.caretPosition, anyOf(0, 1));

    await tapCharacter('222', -2);
    expect(controller.caretPosition, anyOf(7, 8));
    await tapCharacter('222', 1);
    expect(controller.caretPosition, anyOf(9, 10));
    await tapCharacter('3333', 1);
    expect(controller.caretPosition, anyOf(13, 14));
  });
}
