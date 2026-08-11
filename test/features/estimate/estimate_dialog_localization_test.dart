import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/presentation/duplicate_estimate_item_dialog.dart';
import 'package:instant_estimate/features/estimate/presentation/merge_estimate_quantity_dialog.dart';

void main() {
  final existing = EstimateItem(
    id: 'existing-1',
    createdAt: DateTime(2026, 8, 11),
    trade: '土工',
    name: '土砂运输',
    specification: '',
    quantity: 6,
    unit: '回',
    unitPrice: 5000,
    description: '',
    calculationBasis: '',
    originalQuantity: 6,
  );

  testWidgets('简体字中国语显示重复明细对话框', (tester) async {
    await tester.pumpWidget(
      _chineseApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDuplicateEstimateItemDialog(context, existing),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('已存在相同的计算内容'), findsOneWidget);
    expect(find.text('“土砂运输”已添加到当前估算中。'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('更新现有明细'), findsOneWidget);
    expect(find.text('仍然添加'), findsOneWidget);
  });

  testWidgets('简体字中国语显示数量合并对话框', (tester) async {
    await tester.pumpWidget(
      _chineseApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showMergeEstimateQuantityDialog(
              context,
              existing: existing,
              incoming: const EstimateItemDraft(
                name: '土砂运输',
                quantity: 3,
                unit: '回',
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('数量加到现有明细'), findsOneWidget);
    expect(find.text('要将数量加到“土砂运输”吗？\n\n现有：6 回\n本次：3 回'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('加到现有明细'), findsOneWidget);
    expect(find.text('作为新明细添加'), findsOneWidget);
  });
}

Widget _chineseApp(Widget home) => MaterialApp(
  locale: const Locale('zh', 'CN'),
  supportedLocales: const [Locale('ja'), Locale('en'), Locale('zh', 'CN')],
  localizationsDelegates: const [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: home),
);
