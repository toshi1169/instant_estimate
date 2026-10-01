import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/advertising/domain/rewarded_ad_policy.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/construction_calculations/presentation/construction_calculations_screen.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_item_editor_screen.dart';

void main() {
  Future<ConstructionCalculationsScreen> openConvenientCalculations(
    WidgetTester tester, {
    required Future<bool> Function(RewardedAdEntryPoint) requestAccess,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(onRequestRewardedAdAccess: requestAccess),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sideMenuConstructionCalculations')));
    await tester.pumpAndSettle();
    return tester.widget<ConstructionCalculationsScreen>(
      find.byType(ConstructionCalculationsScreen),
    );
  }

  testWidgets('便利計算の見積連携はインスタント見積と同じ広告判定を通る', (tester) async {
    final calls = <RewardedAdEntryPoint>[];
    final screen = await openConvenientCalculations(
      tester,
      requestAccess: (entryPoint) async {
        calls.add(entryPoint);
        return true;
      },
    );

    expect(calls, [RewardedAdEntryPoint.convenientCalculation]);

    final send = screen.onSendToEstimate(
      const EstimateItemDraft(name: '土量', quantity: 12.5, unit: 'm³'),
    );
    await tester.pumpAndSettle();

    expect(calls, [
      RewardedAdEntryPoint.convenientCalculation,
      RewardedAdEntryPoint.instantEstimate,
    ]);
    expect(find.byType(EstimateItemEditorScreen), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('estimateNameField')),
    );
    final quantityField = tester.widget<TextFormField>(
      find.byKey(const Key('estimateQuantityField')),
    );
    expect(nameField.controller?.text, '土量');
    expect(quantityField.controller?.text, '12.5');
    Navigator.of(tester.element(find.byType(EstimateItemEditorScreen))).pop();
    await tester.pumpAndSettle();
    await send;
  });

  testWidgets('広告未完了では見積連携せず入力内容を保持する', (tester) async {
    final draft = const EstimateItemDraft(
      name: '四辺面積',
      quantity: 42,
      unit: 'm²',
    );
    final screen = await openConvenientCalculations(
      tester,
      requestAccess: (entryPoint) async =>
          entryPoint == RewardedAdEntryPoint.convenientCalculation,
    );

    await screen.onSendToEstimate(draft);
    await tester.pumpAndSettle();

    expect(find.byType(EstimateItemEditorScreen), findsNothing);
    expect(draft.name, '四辺面積');
    expect(draft.quantity, 42);
    expect(draft.unit, 'm²');
  });

  testWidgets('広告待機中の連打は広告判定と見積連携を一度だけ実行する', (tester) async {
    final access = Completer<bool>();
    var estimateRequests = 0;
    final screen = await openConvenientCalculations(
      tester,
      requestAccess: (entryPoint) {
        if (entryPoint == RewardedAdEntryPoint.convenientCalculation) {
          return Future.value(true);
        }
        estimateRequests += 1;
        return access.future;
      },
    );
    const draft = EstimateItemDraft(name: '重量', quantity: 100, unit: 'kg');

    final first = screen.onSendToEstimate(draft);
    final second = screen.onSendToEstimate(draft);
    await tester.pump();
    expect(estimateRequests, 1);

    access.complete(false);
    await Future.wait([first, second]);
    await tester.pumpAndSettle();

    expect(estimateRequests, 1);
    expect(find.byType(EstimateItemEditorScreen), findsNothing);
  });
}
