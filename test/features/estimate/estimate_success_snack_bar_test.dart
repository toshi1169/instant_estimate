import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_success_snack_bar.dart';

void main() {
  testWidgets('操作不要の成功通知はActionなしで2秒表示し連続時は置き換える', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const Key('firstSuccess'),
                  onPressed: () => showEstimateSuccessSnackBar(
                    context,
                    content: const Text('最初の成功'),
                  ),
                  child: const Text('first'),
                ),
                TextButton(
                  key: const Key('secondSuccess'),
                  onPressed: () => showEstimateSuccessSnackBar(
                    context,
                    content: const Text('次の成功'),
                  ),
                  child: const Text('second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('firstSuccess')));
    await tester.pump();
    var snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, const Duration(seconds: 2));
    expect(snackBar.action, isNull);

    await tester.tap(find.byKey(const Key('secondSuccess')));
    await tester.pumpAndSettle();
    expect(find.text('最初の成功'), findsNothing);
    expect(find.text('次の成功'), findsOneWidget);
    snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, const Duration(seconds: 2));
    expect(snackBar.action, isNull);
  });

  testWidgets('明細なし警告は標準時間のまま変更しない', (tester) async {
    final controller = EstimateController();
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('copyEstimateTable')));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(find.text('コピーする明細がありません'), findsOneWidget);
    expect(snackBar.duration, const Duration(milliseconds: 4000));
    expect(snackBar.action, isNull);
  });
}
