import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_success_snack_bar.dart';

void main() {
  Widget snackBarTestApp() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              TextButton(
                key: const Key('showUndo'),
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 5),
                        persist: false,
                        content: const Text('Undo notification'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {},
                        ),
                      ),
                    );
                },
                child: const Text('show undo'),
              ),
              TextButton(
                key: const Key('showSecondUndo'),
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 5),
                        persist: false,
                        content: const Text('Second undo notification'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {},
                        ),
                      ),
                    );
                },
                child: const Text('show second undo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Undo通知は表示完了後5秒未満では残り5秒後に消える', (tester) async {
    await tester.pumpWidget(snackBarTestApp());

    await tester.tap(find.byKey(const Key('showUndo')));
    await tester.pump();
    await tester.pumpAndSettle();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.duration, const Duration(seconds: 5));
    expect(snackBar.persist, isFalse);
    expect(find.text('Undo notification'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4999));
    expect(find.text('Undo notification'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Undo notification'), findsNothing);
  });

  testWidgets('置換前のUndo通知のタイマーは新しい通知を閉じない', (tester) async {
    await tester.pumpWidget(snackBarTestApp());

    await tester.tap(find.byKey(const Key('showUndo')));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.byKey(const Key('showSecondUndo')));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Undo notification'), findsNothing);
    expect(find.text('Second undo notification'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Second undo notification'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3499));
    expect(find.text('Second undo notification'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Second undo notification'), findsNothing);
  });

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

    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text('次の成功'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('次の成功'), findsNothing);
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
