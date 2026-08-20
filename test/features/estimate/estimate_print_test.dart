import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/application/estimate_print.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('完成済み正式PDF bytesを変更せずA4横の標準印刷処理へ渡す', () async {
    final sourceBytes = Uint8List.fromList(utf8.encode('%PDF-formal-estimate'));
    Uint8List? printedBytes;
    PdfPageFormat? requestedFormat;
    bool? requestedDynamicLayout;

    final printed = await printEstimatePdfBytes(
      bytes: sourceBytes,
      name: '正式見積書.pdf',
      layoutPdf:
          ({
            required onLayout,
            required name,
            required format,
            required dynamicLayout,
          }) async {
            expect(name, '正式見積書.pdf');
            requestedFormat = format;
            requestedDynamicLayout = dynamicLayout;
            printedBytes = await onLayout(format);
            return true;
          },
    );

    expect(printed, isTrue);
    expect(requestedFormat, PdfPageFormat.a4.landscape);
    expect(requestedDynamicLayout, isFalse);
    expect(identical(printedBytes, sourceBytes), isTrue);
  });

  test('OS印刷画面のキャンセルは正常終了として扱う', () async {
    final printed = await printEstimatePdfBytes(
      bytes: Uint8List.fromList(const [1, 2, 3]),
      name: '見積書.pdf',
      layoutPdf:
          ({
            required onLayout,
            required name,
            required format,
            required dynamicLayout,
          }) async => false,
    );

    expect(printed, isFalse);
  });

  testWidgets('印刷ボタンは現在の実データから正式PDFを生成して印刷へ渡す', (tester) async {
    final controller = await _controllerWithItem();
    final beforeInfo = controller.info.toJson();
    final beforeItems = controller.items.map((item) => item.toJson()).toList();
    Uint8List? printedBytes;
    String? printedName;

    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemsScreen(
          controller: controller,
          settings: const AppSettings(
            estimateDecimalPlaces: 3,
            companyProfile: CompanyProfile(companyName: '松本建設'),
          ),
          onRequestRewardedAdAccess: (_) async => true,
          printPdfBytes: ({required bytes, required name}) async {
            printedBytes = bytes;
            printedName = name;
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('printEstimatePdf')));
    await tester.pumpAndSettle();

    expect(printedBytes, isNotNull);
    expect(printedBytes!.length, greaterThan(1000));
    expect(ascii.decode(printedBytes!.take(4).toList()), '%PDF');
    expect(printedName, '${controller.info.displayName}.pdf');
    expect(controller.info.toJson(), beforeInfo);
    expect(controller.items.map((item) => item.toJson()).toList(), beforeItems);
    expect(find.text('印刷用PDFを作成できませんでした'), findsNothing);
  });

  testWidgets('印刷失敗を通知して見積データを変更しない', (tester) async {
    final controller = await _controllerWithItem();
    final beforeItems = controller.items.map((item) => item.toJson()).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemsScreen(
          controller: controller,
          onRequestRewardedAdAccess: (_) async => true,
          printPdfBytes: ({required bytes, required name}) async {
            throw StateError('printer unavailable');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('printEstimatePdf')));
    await tester.pumpAndSettle();

    expect(find.text('印刷用PDFを作成できませんでした'), findsOneWidget);
    expect(controller.items.map((item) => item.toJson()).toList(), beforeItems);
  });
}

Future<EstimateController> _controllerWithItem() async {
  final controller = EstimateController();
  await controller.load();
  await controller.updateInfo(
    controller.info.copyWith(estimateName: '松本邸 外構工事'),
  );
  await controller.add(
    const EstimateItemDraft(
      constructionSymbol: '①',
      constructionLocation: '南 道路側',
      trade: '正式帳票に出力しない工種',
      name: '化粧ブロック積み',
      specification: 'C120',
      quantity: 12.346,
      unit: 'm²',
      unitPrice: 4500,
      description: '材料施工共',
    ),
  );
  return controller;
}
