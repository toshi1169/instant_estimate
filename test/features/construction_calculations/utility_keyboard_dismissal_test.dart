import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/area/presentation/polygon_area_screen.dart';
import 'package:instant_estimate/features/area/presentation/quadrilateral_area_screen.dart';
import 'package:instant_estimate/features/density/presentation/weight_calculation_screen.dart';
import 'package:instant_estimate/features/earthwork/presentation/earthwork_calculation_screen.dart';
import 'package:instant_estimate/features/productivity/application/productivity_controller.dart';
import 'package:instant_estimate/features/productivity/data/productivity_record_store.dart';
import 'package:instant_estimate/features/productivity/presentation/productivity_calculation_screen.dart';
import 'package:instant_estimate/features/ratio/presentation/ratio_calculation_screen.dart';
import 'package:instant_estimate/features/unit_conversion/presentation/unit_conversion_screen.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    TargetPlatform platform = TargetPlatform.iOS,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: screen,
      ),
    );
  }

  EditableText editable(WidgetTester tester, Finder field) =>
      tester.widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );

  void expectAllTextFieldsDismissOutside() {
    expect(find.byType(TextField), findsWidgets);
    for (final element in find.byType(TextField).evaluate()) {
      expect((element.widget as TextField).onTapOutside, isNotNull);
    }
  }

  Future<void> expectFocusMoveAndDismiss({
    required WidgetTester tester,
    required Finder first,
    required Finder second,
    required Finder outside,
    required String firstValue,
    required String secondValue,
  }) async {
    await tester.tap(first);
    await tester.pump();
    expect(editable(tester, first).focusNode.hasFocus, isTrue);
    await tester.enterText(first, firstValue);

    await tester.tap(second);
    await tester.pump();
    expect(editable(tester, first).focusNode.hasFocus, isFalse);
    expect(editable(tester, second).focusNode.hasFocus, isTrue);
    await tester.enterText(second, secondValue);

    await tester.tap(outside);
    await tester.pump();
    expect(editable(tester, second).focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(editable(tester, first).controller.text, firstValue);
    expect(editable(tester, second).controller.text, secondValue);
  }

  tearDown(() async {
    FocusManager.instance.primaryFocus?.unfocus();
  });

  testWidgets('土量3タブの入力欄でフォーカス移動と欄外解除ができる', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(
      tester,
      EarthworkCalculationScreen(onSendToEstimate: (_) async {}),
    );

    final length = find.byKey(const Key('earthworkLength'));
    final width = find.byKey(const Key('earthworkWidth'));
    await expectFocusMoveAndDismiss(
      tester: tester,
      first: length,
      second: width,
      outside: find.text('土量計算'),
      firstValue: '10',
      secondValue: '2',
    );
    expectAllTextFieldsDismissOutside();

    await tester.tap(find.text('埋戻し'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('earthworkStructureVolume')), findsOneWidget);
    expectAllTextFieldsDismissOutside();

    await tester.tap(find.text('盛土'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('embankmentLength')), findsOneWidget);
    expectAllTextFieldsDismissOutside();
  });

  testWidgets('対比A〜Dでフォーカス移動し結果を保って欄外解除する', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester, const RatioCalculationScreen());

    await tester.enterText(find.byKey(const Key('ratioA')), '2');
    await tester.enterText(find.byKey(const Key('ratioB')), '5');
    await tester.enterText(find.byKey(const Key('ratioC')), '8');
    await tester.pump();
    expect(find.textContaining('D ＝ 20'), findsOneWidget);

    await expectFocusMoveAndDismiss(
      tester: tester,
      first: find.byKey(const Key('ratioA')),
      second: find.byKey(const Key('ratioB')),
      outside: find.textContaining('D ＝ 20'),
      firstValue: '2',
      secondValue: '5',
    );
    expect(find.textContaining('D ＝ 20'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    for (final element in find.byType(TextField).evaluate()) {
      expect((element.widget as TextField).onTapOutside, isNotNull);
    }
  });

  testWidgets('歩掛の各モードで共通入力欄が欄外解除に対応する', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(
      tester,
      ProductivityCalculationScreen(
        controller: ProductivityController(
          store: MemoryProductivityRecordStore(),
        ),
      ),
    );

    final quantity = find.widgetWithText(TextField, '施工数量');
    final productivity = find.widgetWithText(TextField, '1人1日の施工量（単位/人日）');
    await expectFocusMoveAndDismiss(
      tester: tester,
      first: quantity,
      second: productivity,
      outside: find.text('歩掛・生産性計算'),
      firstValue: '100',
      secondValue: '10',
    );

    for (final mode in const ['必要日数', '生産性・実績']) {
      await tester.tap(find.text(mode));
      await tester.pumpAndSettle();
      for (final element in find.byType(TextField).evaluate()) {
        expect((element.widget as TextField).onTapOutside, isNotNull);
      }
    }
  });

  testWidgets('単位変換の値と係数欄は設定を変えず欄外解除に対応する', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester, const UnitConversionScreen());

    final value = find.byKey(const Key('unitConversionValue'));
    await tester.tap(value);
    await tester.enterText(value, '1000');
    await tester.pump();
    expect(find.text('100.00 cm'), findsOneWidget);
    await tester.tap(find.text('単位変換'));
    await tester.pump();
    expect(editable(tester, value).focusNode.hasFocus, isFalse);
    expect(editable(tester, value).controller.text, '1000');
    expect(find.text('100.00 cm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unitConversionCategory')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('土量変換').last);
    await tester.pumpAndSettle();
    for (final key in const [
      'unitConversionValue',
      'loosenFactor',
      'compactionFactor',
    ]) {
      final field = find.byKey(Key(key));
      expect(tester.widget<TextField>(field).onTapOutside, isNotNull);
    }

    await tester.tap(find.byKey(const Key('swapConversionUnits')));
    await tester.pump();
    expect(find.byKey(const Key('unitConversionFrom')), findsOneWidget);
    expect(find.byKey(const Key('unitConversionTo')), findsOneWidget);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('単位変換のDoneでメイン入力欄だけフォーカス解除する（${platform.name}）', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpScreen(
        tester,
        const UnitConversionScreen(),
        platform: platform,
      );

      final value = find.byKey(const Key('unitConversionValue'));
      final field = tester.widget<TextField>(value);
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true, signed: true),
      );
      expect(field.textInputAction, TextInputAction.done);

      await tester.tap(value);
      await tester.enterText(value, '-12.3');
      await tester.pump();
      expect(editable(tester, value).focusNode.hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(editable(tester, value).focusNode.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(editable(tester, value).controller.text, '-12.3');
    });
  }

  testWidgets('単位変換は負の温度と3桁カンマを従来どおり計算する', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester, const UnitConversionScreen());

    await tester.tap(find.byKey(const Key('unitConversionCategory')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('温度').last);
    await tester.pumpAndSettle();
    final value = find.byKey(const Key('unitConversionValue'));
    await tester.enterText(value, '-40');
    await tester.pump();
    expect(find.text('-40.00 ℉'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unitConversionCategory')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('長さ').last);
    await tester.pumpAndSettle();
    await tester.enterText(value, '1,234.5');
    await tester.pump();
    expect(find.text('123.45 cm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swapConversionUnits')));
    await tester.pump();
    expect(find.text('12345.00 mm'), findsOneWidget);

    await tester.tap(find.text('クリア'));
    await tester.pump();
    expect(editable(tester, value).controller.text, isEmpty);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('四辺面積は値と計算結果を保って欄外解除する', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(
      tester,
      QuadrilateralAreaScreen(onSendToEstimate: (_) async {}),
    );
    for (final (index, value) in ['3', '4', '3', '4', '5'].indexed) {
      await tester.enterText(
        find.byKey(Key('quadrilateralLength$index')),
        value,
      );
    }
    await tester.tap(find.byKey(const Key('calculateQuadrilateralArea')));
    await tester.pump();
    expect(find.text('12 m²'), findsOneWidget);
    await tester.tap(find.byKey(const Key('quadrilateralLength0')));
    await tester.pump();
    await tester.tap(find.text('12 m²'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('12 m²'), findsOneWidget);
    expectAllTextFieldsDismissOutside();
  });

  testWidgets('多角形面積はスクロール後も値を保って欄外解除する', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(tester, PolygonAreaScreen(onSendToEstimate: (_) async {}));
    final first = find.byKey(const Key('polygonOuterSide0'));
    final second = find.byKey(const Key('polygonOuterSide1'));
    await expectFocusMoveAndDismiss(
      tester: tester,
      first: first,
      second: second,
      outside: find.text('5辺以上面積計算'),
      firstValue: '3',
      secondValue: '4',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(editable(tester, first).controller.text, '3');
    expectAllTextFieldsDismissOutside();
  });

  testWidgets('比重重量は計算結果を保って欄外解除する', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(
      tester,
      WeightCalculationScreen(onSendToEstimate: (_) async {}),
    );
    await tester.enterText(find.byKey(const Key('densityVolume')), '2');
    await tester.tap(find.byKey(const Key('calculateWeight')));
    await tester.pump();
    expect(find.text('4.8 t'), findsOneWidget);

    await expectFocusMoveAndDismiss(
      tester: tester,
      first: find.byKey(const Key('densityVolume')),
      second: find.byKey(const Key('densityValue')),
      outside: find.text('4.8 t'),
      firstValue: '2',
      secondValue: '2.4',
    );
    expect(find.text('4.8 t'), findsOneWidget);
    expectAllTextFieldsDismissOutside();
  });

  testWidgets('Android相当でも欄外タップでキーボードを閉じる', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(
      tester,
      const RatioCalculationScreen(),
      platform: TargetPlatform.android,
    );
    final field = find.byKey(const Key('ratioA'));
    await tester.tap(field);
    await tester.pump();
    expect(editable(tester, field).focusNode.hasFocus, isTrue);
    await tester.tap(find.text('対比計算'));
    await tester.pump();
    expect(editable(tester, field).focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
