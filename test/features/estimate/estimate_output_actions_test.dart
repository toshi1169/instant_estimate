import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/advertising/application/rewarded_ad_access_controller.dart';
import 'package:instant_estimate/features/advertising/domain/rewarded_ad_policy.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';
import 'package:instant_estimate/features/subscription/domain/app_access_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('出力の3択を表示しキャンセルでは何も生成しない', (tester) async {
    final controller = await _controllerWithItem();
    final beforeInfo = controller.info.toJson();
    final beforeItems = controller.items.map((item) => item.toJson()).toList();
    var accessRequests = 0;
    var outputs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemsScreen(
          controller: controller,
          onRequestRewardedAdAccess: (_) async {
            accessRequests++;
            return true;
          },
          printPdfBytes: ({required bytes, required name}) async {
            outputs++;
            return true;
          },
          sharePdfBytes:
              ({
                required bytes,
                required fileName,
                required subject,
                sharePositionOrigin,
              }) async {
                outputs++;
              },
          shareWorkbookFile:
              ({required file, required subject, sharePositionOrigin}) async {
                outputs++;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('estimateOutputButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('printEstimatePdf')), findsOneWidget);
    expect(find.byKey(const Key('shareEstimatePdf')), findsOneWidget);
    expect(find.byKey(const Key('exportEstimateExcel')), findsOneWidget);
    expect(find.byKey(const Key('copyEstimateTable')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateOutputSheet')), findsNothing);
    expect(accessRequests, 0);
    expect(outputs, 0);
    expect(controller.info.toJson(), beforeInfo);
    expect(controller.items.map((item) => item.toJson()).toList(), beforeItems);
  });

  testWidgets('印刷は広告判定後に正式PDFのbytesを渡し見積を変更しない', (tester) async {
    final controller = await _controllerWithItem();
    final beforeInfo = controller.info.toJson();
    final beforeItems = controller.items.map((item) => item.toJson()).toList();
    final calls = <String>[];
    Uint8List? printedBytes;
    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemsScreen(
          controller: controller,
          onRequestRewardedAdAccess: (entryPoint) async {
            expect(entryPoint, RewardedAdEntryPoint.printOutput);
            calls.add('access');
            return true;
          },
          printPdfBytes: ({required bytes, required name}) async {
            calls.add('print');
            printedBytes = bytes;
            expect(name, '松本邸 外構工事_正式見積書.pdf');
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _select(tester, 'printEstimatePdf');
    expect(calls, ['access', 'print']);
    expect(ascii.decode(printedBytes!.take(4).toList()), '%PDF');
    expect(controller.info.toJson(), beforeInfo);
    expect(controller.items.map((item) => item.toJson()).toList(), beforeItems);
  });

  testWidgets('正式XLSXを既存生成器で作成しファイル共有へ渡す', (tester) async {
    final controller = await _controllerWithItem();
    final beforeInfo = controller.info.toJson();
    final beforeItems = controller.items.map((item) => item.toJson()).toList();
    final calls = <String>[];
    File? sharedFile;
    String? sharedSubject;
    final workbookFile = File('松本邸 外構工事.xlsx');
    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemsScreen(
          controller: controller,
          onRequestRewardedAdAccess: (entryPoint) async {
            expect(entryPoint, RewardedAdEntryPoint.excelExport);
            calls.add('access');
            return true;
          },
          createWorkbookFile:
              ({
                required info,
                required items,
                required companyProfile,
                required estimateDecimalPlaces,
              }) async {
                expect(info.toJson(), beforeInfo);
                expect(
                  items.map((item) => item.toJson()).toList(),
                  beforeItems,
                );
                return workbookFile;
              },
          shareWorkbookFile:
              ({required file, required subject, sharePositionOrigin}) async {
                calls.add('share');
                sharedFile = file;
                sharedSubject = subject;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _select(tester, 'exportEstimateExcel');
    expect(calls, ['access', 'share']);
    expect(sharedFile, isNotNull);
    expect(sharedFile!.uri.pathSegments.last, '松本邸 外構工事.xlsx');
    expect(sharedSubject, '松本邸 外構工事');
    expect(sharedFile, same(workbookFile));
    expect(controller.info.toJson(), beforeInfo);
    expect(controller.items.map((item) => item.toJson()).toList(), beforeItems);
  });

  for (final action in [
    'printEstimatePdf',
    'shareEstimatePdf',
    'exportEstimateExcel',
  ]) {
    testWidgets('$action: 広告アクセスが許可されなければ出力しない', (tester) async {
      final controller = await _controllerWithItem();
      final requested = <RewardedAdEntryPoint>[];
      var outputs = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: EstimateItemsScreen(
            controller: controller,
            onRequestRewardedAdAccess: (entryPoint) async {
              requested.add(entryPoint);
              return false;
            },
            printPdfBytes: ({required bytes, required name}) async {
              outputs++;
              return true;
            },
            sharePdfBytes:
                ({
                  required bytes,
                  required fileName,
                  required subject,
                  sharePositionOrigin,
                }) async {
                  outputs++;
                },
            shareWorkbookFile:
                ({required file, required subject, sharePositionOrigin}) async {
                  outputs++;
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _select(tester, action);
      expect(requested, [
        switch (action) {
          'printEstimatePdf' => RewardedAdEntryPoint.printOutput,
          'shareEstimatePdf' => RewardedAdEntryPoint.pdfExport,
          _ => RewardedAdEntryPoint.excelExport,
        },
      ]);
      expect(outputs, 0);
    });
  }

  for (final plan in AppAccessPlan.values) {
    testWidgets('${plan.name}: 出力で既存プラン別の広告判定を使う', (tester) async {
      final controller = await _controllerWithItem();
      final presenter = _RecordingPresenter();
      final access = RewardedAdAccessController(
        initialState: AppAccessState(plan: plan),
        presenter: presenter,
        now: () => DateTime(2026, 9, 22),
      );
      var prints = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: EstimateItemsScreen(
            controller: controller,
            onRequestRewardedAdAccess: access.requestAccess,
            printPdfBytes: ({required bytes, required name}) async {
              prints++;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _select(tester, 'printEstimatePdf');
      expect(prints, 1);
      expect(
        presenter.calls,
        plan == AppAccessPlan.free
            ? [RewardedAdEntryPoint.printOutput]
            : <RewardedAdEntryPoint>[],
      );
    });
  }

  for (final result in [
    RewardedAdResult.dismissed,
    RewardedAdResult.unavailable,
    RewardedAdResult.failed,
  ]) {
    testWidgets('Freeの出力は広告${result.name}で実行しない', (tester) async {
      final controller = await _controllerWithItem();
      final presenter = _RecordingPresenter(result);
      final access = RewardedAdAccessController(
        initialState: const AppAccessState(),
        presenter: presenter,
        now: () => DateTime(2026, 9, 22),
      );
      var prints = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: EstimateItemsScreen(
            controller: controller,
            onRequestRewardedAdAccess: access.requestAccess,
            printPdfBytes: ({required bytes, required name}) async {
              prints++;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _select(tester, 'printEstimatePdf');
      expect(presenter.calls, [RewardedAdEntryPoint.printOutput]);
      expect(prints, 0);
    });
  }
}

Future<void> _select(WidgetTester tester, String actionKey) async {
  await tester.tap(find.byKey(const Key('estimateOutputButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(actionKey)));
  await tester.pumpAndSettle();
}

Future<EstimateController> _controllerWithItem() async {
  final controller = EstimateController();
  await controller.load();
  await controller.updateInfo(
    controller.info.copyWith(estimateName: '松本邸 外構工事'),
  );
  await controller.add(
    const EstimateItemDraft(
      name: '化粧ブロック積み',
      specification: 'C120',
      quantity: 12,
      unit: 'm²',
      unitPrice: 4500,
    ),
  );
  return controller;
}

class _RecordingPresenter implements RewardedAdPresenter {
  _RecordingPresenter([this.result = RewardedAdResult.completed]);

  final RewardedAdResult result;
  final calls = <RewardedAdEntryPoint>[];

  @override
  Future<RewardedAdResult> show(RewardedAdEntryPoint entryPoint) async {
    calls.add(entryPoint);
    return result;
  }
}
