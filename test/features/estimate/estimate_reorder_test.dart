import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/application/estimate_excel_export.dart';
import 'package:instant_estimate/features/estimate/application/estimate_pdf_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_item_editor_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('保存順でPDFとExcelを実生成する', () async {
    final controller = await _controller();
    final groups = controller.groups;
    await controller.reorderGroups([
      groups[1].items.map((item) => item.id).toList(),
      groups[0].items.reversed.map((item) => item.id).toList(),
    ]);

    final pdfRows = buildEstimatePdfBreakdownLayout(
      controller.items,
    ).expand((page) => page.rows).toList();
    expect(
      pdfRows.where((row) => row.item != null).map((row) => row.item!.name),
      ['C', 'B', 'A'],
    );
    final pdfBytes = await buildEstimatePdf(
      info: controller.info,
      items: controller.items,
    );
    final workbookBytes = buildEstimateWorkbook(
      info: controller.info,
      items: controller.items,
    );
    expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
    final workbook = Excel.decodeBytes(workbookBytes);
    final breakdown = workbook['内訳'];
    expect(
      breakdown.cell(CellIndex.indexByString('B5')).value?.toString(),
      contains('C'),
    );
    expect(
      breakdown.cell(CellIndex.indexByString('B9')).value?.toString(),
      contains('B'),
    );
    expect(
      breakdown.cell(CellIndex.indexByString('B10')).value?.toString(),
      contains('A'),
    );
  });

  testWidgets('明細メニューから同じグループ内を並び替えて完了時に保存する', (tester) async {
    final controller = await _controller();
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('estimateItemMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('項目入替'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateItemReorderList')), findsOneWidget);

    await tester.timedDrag(
      find.byKey(const Key('estimateItemDragHandle0')),
      const Offset(0, 260),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finishEstimateReorder')));
    await tester.pumpAndSettle();

    expect(controller.groups.first.items.map((item) => item.name), ['B', 'A']);
    expect(controller.groups.last.items.single.name, 'C');
  });

  testWidgets('明細並び替えは名称とツマミだけを折り返して表示する', (tester) async {
    const longName = '狭い画面でも明細を識別できるように複数行へ折り返す非常に長い名称';
    final controller = await _controller(firstName: longName);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('estimateItemMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('項目入替'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimateItemReorderList')), findsOneWidget);
    expect(find.byKey(const Key('estimateItemDragHandle0')), findsOneWidget);
    expect(find.text(longName), findsOneWidget);
    expect(find.text('仕様Aは並び替え中に表示しない'), findsNothing);
    expect(
      find.byKey(const Key('estimateItemReorderGroupHeader')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('グループを配下明細ごと並び替える', (tester) async {
    final controller = await _controller();
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reorderEstimateGroups')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateGroupReorderList')), findsOneWidget);
    await tester.timedDrag(
      find.byKey(const Key('estimateGroupDragHandle0')),
      const Offset(0, 700),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('finishEstimateReorder')));
    await tester.pumpAndSettle();

    expect(controller.groups.map((group) => group.constructionSymbol), [
      '②',
      '①',
    ]);
    expect(controller.items.map((item) => item.name), ['C', 'A', 'B']);
  });

  testWidgets('グループ並び替えは見出しとツマミだけを表示してキャンセルできる', (tester) async {
    final controller = await _controller();
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reorderEstimateGroups')));
    await tester.pumpAndSettle();

    expect(find.text('① 北側'), findsOneWidget);
    expect(find.byKey(const Key('estimateGroupDragHandle0')), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('仕様Aは並び替え中に表示しない'), findsNothing);

    await tester.tap(find.byKey(const Key('cancelEstimateReorder')));
    await tester.pumpAndSettle();
    expect(controller.groups.map((group) => group.constructionSymbol), [
      '①',
      '②',
    ]);
  });

  testWidgets('上部情報は初期省略で切替でき税ONの税込総額だけを表示する', (tester) async {
    final controller = await _controller();
    await controller.updateInfo(
      controller.info.copyWith(
        estimateName: '長い見積名を狭い画面でも表示する確認用見積',
        siteName: '長い施工場所名を含む現場',
        notes: '省略される備考',
      ),
    );
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimateCollapsedSummary')), findsOneWidget);
    expect(find.byKey(const Key('estimateInfoSummary')), findsNothing);
    expect(find.textContaining('税込総額'), findsOneWidget);
    expect(find.textContaining('税抜合計'), findsNothing);
    expect(find.textContaining('省略される備考'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('toggleEstimateHeader')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateInfoSummary')), findsOneWidget);
    expect(find.textContaining('税抜合計'), findsOneWidget);
    expect(find.textContaining('省略される備考'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
  });

  testWidgets('税OFFの省略表示は合計を表示しLightとDarkで崩れない', (tester) async {
    for (final brightness in Brightness.values) {
      final controller = await _controller();
      await controller.updateInfo(controller.info.copyWith(taxEnabled: false));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: brightness,
            ),
          ),
          home: EstimateItemsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      final total = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('estimateCollapsedTotal')),
          matching: find.byType(Text),
        ),
      );
      expect(total.data, startsWith('合計'));
      expect(total.data, isNot(contains('税込総額')));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('記号と施工場所だけがグループ見出し色を使う', (tester) async {
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          home: const EstimateItemEditorScreen(
            initialDraft: EstimateItemDraft(
              constructionSymbol: '①',
              constructionLocation: '北側',
            ),
            isEditing: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final symbolTheme = Theme.of(
        tester.element(
          find.byKey(const Key('estimateConstructionSymbolField')),
        ),
      );
      final locationTheme = Theme.of(
        tester.element(
          find.byKey(const Key('estimateConstructionLocationField')),
        ),
      );
      final nameTheme = Theme.of(
        tester.element(find.byKey(const Key('estimateNameField'))),
      );
      expect(
        symbolTheme.inputDecorationTheme.fillColor,
        scheme.primaryContainer,
      );
      expect(
        locationTheme.inputDecorationTheme.fillColor,
        scheme.primaryContainer,
      );
      expect(
        nameTheme.inputDecorationTheme.fillColor,
        isNot(scheme.primaryContainer),
      );
    }
  });
}

Future<EstimateController> _controller({String firstName = 'A'}) async {
  final controller = EstimateController();
  await controller.load();
  for (final draft in [
    EstimateItemDraft(
      constructionSymbol: '①',
      constructionLocation: '北側',
      name: firstName,
      specification: '仕様Aは並び替え中に表示しない',
      quantity: 1,
      unitPrice: 100,
    ),
    EstimateItemDraft(
      constructionSymbol: '①',
      constructionLocation: '北側',
      name: 'B',
      quantity: 2,
      unitPrice: 200,
    ),
    EstimateItemDraft(
      constructionSymbol: '②',
      constructionLocation: '南側',
      name: 'C',
      quantity: 3,
      unitPrice: 300,
    ),
  ]) {
    await controller.add(draft);
  }
  return controller;
}
