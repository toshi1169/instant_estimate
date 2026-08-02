import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/app/app.dart';
import 'package:instant_estimate/core/domain/angle_unit.dart';
import 'package:instant_estimate/core/theme/app_theme.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/onboarding/data/onboarding_preferences.dart';
import 'package:instant_estimate/features/settings/data/app_settings_store.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_document.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';

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

class FakeAppSettingsStore implements AppSettingsStore {
  FakeAppSettingsStore({this.settings = const AppSettings()});

  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
  }
}

class FakeEstimateItemStore implements EstimateItemStore {
  EstimateDocument document = EstimateDocument(
    info: EstimateInfo.initial(DateTime(2026, 8, 2)),
    items: const [],
  );

  List<EstimateItem> get items => document.items;

  @override
  Future<EstimateDocument> load() async => document;

  @override
  Future<void> save(EstimateDocument document) async {
    this.document = EstimateDocument(
      info: document.info,
      items: List.of(document.items),
    );
  }
}

void main() {
  testWidgets('白・グレーテーマのイコールは白文字で表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    expect(
      AppTheme.gray.scaffoldBackgroundColor,
      const Color.fromRGBO(180, 180, 180, 1),
    );

    for (final theme in [AppTheme.light, AppTheme.gray]) {
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: const CalculatorScreen()),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('calculatorKey=')),
      );
      expect(button.style?.foregroundColor?.resolve({}), Colors.white);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('保存済みテーマを復元し設定画面から変更できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsStore = FakeAppSettingsStore(
      settings: const AppSettings(theme: AppThemeSelection.dark),
    );
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('テーマ'), findsOneWidget);
    expect(find.text('黒'), findsOneWidget);

    await tester.tap(find.byKey(const Key('themeSetting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('白'));
    await tester.pumpAndSettle();

    expect(settingsStore.settings.theme, AppThemeSelection.light);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    await tester.tap(find.byKey(const Key('angleUnitSetting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ラジアン（RAD）'));
    await tester.pumpAndSettle();
    expect(settingsStore.settings.angleUnit, AngleUnit.radians);
  });

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

  testWidgets('メニューボタンからサイドメニューを開き設定へ移動できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculatorSideMenu')), findsOneWidget);
    expect(find.text('ヘルプ'), findsOneWidget);
    expect(find.text('プライム（広告非表示）'), findsOneWidget);
    expect(find.text('アルティメット'), findsOneWidget);
    expect(find.text('建築・土木系計算'), findsOneWidget);
    expect(find.text('インスタント見積'), findsWidgets);
    expect(find.byKey(const Key('sideMenuAdArea')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sideMenuSettings')));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('テーマ'), findsOneWidget);
  });

  testWidgets('メニューボタンの長押しで3列9行の関数一覧を開ける', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('functionListDialog')), findsOneWidget);
    expect(find.byKey(const Key('functionListGrid')), findsOneWidget);
    expect(find.byKey(const Key('functionButton0')), findsOneWidget);
    expect(find.byKey(const Key('functionButton26')), findsOneWidget);
    expect(find.text('π'), findsOneWidget);
    expect(find.text('sinh⁻¹'), findsOneWidget);
    expect(find.text('x!'), findsOneWidget);
    expect(find.byKey(const Key('functionAngleUnitSetting')), findsOneWidget);
    expect(find.text('DEG（度）'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancelFunctionList')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('functionListDialog')), findsOneWidget);
  });

  testWidgets('関数一覧から角度単位を変更して保存できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsStore = FakeAppSettingsStore();
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('functionAngleUnitDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RAD（ラジアン）').last);
    await tester.pumpAndSettle();

    expect(settingsStore.settings.angleUnit, AngleUnit.radians);
    expect(find.text('RAD（ラジアン）'), findsOneWidget);
    expect(find.byKey(const Key('functionListDialog')), findsOneWidget);
  });

  testWidgets('関数一覧から平方根を選んで計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('√'));
    await tester.pumpAndSettle();

    for (final key in ['9', '=']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }

    expect(find.text('=  3'), findsOneWidget);
  });

  testWidgets('関数一覧の逆数を横棒付き分数として計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.pump();

    expect(find.text('=  0.25'), findsOneWidget);
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

  testWidgets('計算結果を横棒付きの仮分数と帯分数へ切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('2−1÷2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    controller.press('=');
    await tester.pump();
    expect(controller.resultDisplayMode, ResultDisplayMode.improperFraction);
    expect(find.byKey(const Key('resultText')), findsOneWidget);

    controller.press('a/b');
    await tester.pump();
    expect(controller.resultDisplayMode, ResultDisplayMode.mixedFraction);
    expect(find.byKey(const Key('resultText')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('履歴の縦3点からコピー・編集・削除を選べる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();

    expect(find.text('コピー'), findsOneWidget);
    expect(find.text('共有'), findsOneWidget);
    expect(find.text('編集'), findsOneWidget);
    expect(find.text('削除'), findsOneWidget);
    expect(find.text('スター'), findsOneWidget);
    expect(find.text('見積へ送る'), findsOneWidget);
  });

  testWidgets('無料版の履歴スターでは利用制限を案内する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スター'));
    await tester.pumpAndSettle();

    expect(find.text('スターはアルティメット版で利用できます'), findsOneWidget);
  });

  testWidgets('履歴から見積へ送る共通画面を開ける', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();

    expect(find.text('送信内容'), findsOneWidget);
    final preview = tester.widget<Text>(
      find.byKey(const Key('estimateTransferPreview')),
    );
    expect(preview.data, '1 + 2 = 3');
  });

  testWidgets('電卓の解を見積数量へ送り単価から金額を計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('12×2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimateItemEditor')), findsOneWidget);
    expect(find.text('名称未設定の見積'), findsOneWidget);
    final quantity = tester.widget<TextFormField>(
      find.byKey(const Key('estimateQuantityField')),
    );
    expect(quantity.controller?.text, '24');

    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '100',
    );
    await tester.pump();
    expect(find.text('¥ 2,400'), findsOneWidget);
  });

  testWidgets('見積明細を保存して一覧と合計を表示できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estimateStore = FakeEstimateItemStore();
    final controller = CalculatorController();
    controller.pasteAtCaret('12×2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: controller,
          estimateItemStore: estimateStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('estimateNameField')), '試験明細');
    await tester.enterText(find.byKey(const Key('estimateUnitField')), 'm²');
    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '100',
    );
    await tester.ensureVisible(find.byKey(const Key('addEstimateAndOpen')));
    await tester.tap(find.byKey(const Key('addEstimateAndOpen')));
    await tester.pumpAndSettle();

    expect(estimateStore.items, hasLength(1));
    expect(find.byKey(const Key('estimateItemsList')), findsOneWidget);
    expect(find.text('試験明細'), findsOneWidget);
    expect(find.text('24 m²'), findsOneWidget);
    expect(find.text('合計  ¥ 2,400'), findsOneWidget);
  });

  testWidgets('見積明細を編集・削除して合計と端末保存を更新できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final estimateController = EstimateController(store: store);
    await estimateController.load();
    await estimateController.add(
      const EstimateItemDraft(
        name: '根切り',
        quantity: 2,
        unit: 'm³',
        unitPrice: 4000,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: estimateController)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('estimateItemMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '5000',
    );
    await tester.ensureVisible(find.byKey(const Key('saveEstimateChanges')));
    await tester.tap(find.byKey(const Key('saveEstimateChanges')));
    await tester.pumpAndSettle();

    expect(find.text('合計  ¥ 10,000'), findsOneWidget);
    expect(store.items.single.unitPrice, 5000);

    await tester.tap(find.byKey(const Key('estimateItemMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('「根切り」を削除しますか？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '削除'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emptyEstimateItems')), findsOneWidget);
    expect(find.text('合計  ¥ 0'), findsOneWidget);
    expect(store.items, isEmpty);
  });

  testWidgets('見積基本情報を編集し明細を残したまま端末保存できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final estimateController = EstimateController(store: store);
    await estimateController.load();
    await estimateController.add(
      const EstimateItemDraft(name: '根切り', quantity: 2, unit: 'm³'),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: estimateController)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editEstimateInfo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateInfoEditor')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('estimateInfoNameField')),
      '○○邸 外構工事',
    );
    await tester.enterText(
      find.byKey(const Key('estimateInfoSiteField')),
      '○○邸',
    );
    await tester.enterText(
      find.byKey(const Key('estimateInfoClientField')),
      '○○様',
    );
    await tester.enterText(
      find.byKey(const Key('estimateInfoNumberField')),
      '2026-001',
    );
    await tester.ensureVisible(find.byKey(const Key('saveEstimateInfo')));
    await tester.tap(find.byKey(const Key('saveEstimateInfo')));
    await tester.pumpAndSettle();

    expect(find.text('○○邸 外構工事'), findsOneWidget);
    expect(find.textContaining('現場：○○邸'), findsOneWidget);
    expect(store.document.info.clientName, '○○様');
    expect(store.document.info.estimateNumber, '2026-001');
    expect(store.items.single.name, '根切り');
  });

  testWidgets('履歴スペース長押しで全体画面と分数3形式を確認できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('2-1÷2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.longPress(find.byKey(const Key('historyPanel')));
    await tester.pumpAndSettle();

    expect(find.text('計算履歴'), findsOneWidget);
    expect(find.byKey(const Key('historySearchField')), findsOneWidget);
    expect(find.text('小数'), findsOneWidget);
    expect(find.text('仮分数'), findsOneWidget);
    expect(find.text('帯分数'), findsOneWidget);
    expect(find.text('1.5'), findsOneWidget);
    expect(find.text('3/2'), findsOneWidget);
    expect(find.text('1 1/2'), findsOneWidget);
  });

  testWidgets('履歴全体画面で式と解を検索できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    controller.pasteAtCaret('4+5');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.longPress(find.byKey(const Key('historyPanel')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('historySearchField')),
      '1 + 2',
    );
    await tester.pump();

    expect(find.byKey(const Key('fullHistoryExpression0')), findsOneWidget);
    expect(find.text('4 + 5'), findsNothing);
  });

  testWidgets('履歴全体画面を昇順と降順へ切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    controller.pasteAtCaret('4+5');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.longPress(find.byKey(const Key('historyPanel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historyCount')), findsOneWidget);
    expect(find.text('2件'), findsOneWidget);
    expect(find.text('昇順'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('fullHistoryExpression0'))).data,
      '1 + 2',
    );

    await tester.tap(find.byKey(const Key('historySortMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('降順'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historySortLabel')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('fullHistoryExpression0'))).data,
      '4 + 5',
    );
  });
}
