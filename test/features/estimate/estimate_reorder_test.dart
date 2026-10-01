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

Future<EstimateController> _controller() async {
  final controller = EstimateController();
  await controller.load();
  for (final draft in const [
    EstimateItemDraft(
      constructionSymbol: '①',
      constructionLocation: '北側',
      name: 'A',
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
