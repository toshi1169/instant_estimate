import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/subscription/domain/purchase_store.dart';
import 'package:instant_estimate/features/subscription/presentation/access_plan_screen.dart';

void main() {
  test('商品IDとプランを相互に変換できる', () {
    expect(
      PurchaseProductIds.forPlan(AppAccessPlan.adFree),
      PurchaseProductIds.adFree,
    );
    expect(
      PurchaseProductIds.forPlan(AppAccessPlan.full),
      PurchaseProductIds.fullMonthly,
    );
    expect(PurchaseProductIds.forPlan(AppAccessPlan.free), isNull);
    expect(
      PurchaseProductIds.planFor(PurchaseProductIds.adFree),
      AppAccessPlan.adFree,
    );
    expect(PurchaseProductIds.planFor('unknown'), isNull);
  });

  testWidgets('ストア価格で購入し、購入履歴を復元できる', (tester) async {
    final store = _FakePurchaseStore(
      const PurchaseStoreState(
        operation: PurchaseOperation.ready,
        products: [
          PurchaseProduct(
            id: PurchaseProductIds.adFree,
            plan: AppAccessPlan.adFree,
            displayPrice: '￥320',
          ),
        ],
      ),
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
        locale: const Locale('ja'),
        home: AccessPlanScreen(
          plan: AppAccessPlan.adFree,
          purchaseStore: store,
        ),
      ),
    );

    expect(find.text('￥320'), findsOneWidget);
    await tester.tap(find.byKey(const Key('purchasePlanButton')));
    await tester.pump();
    expect(store.purchasedPlan, AppAccessPlan.adFree);

    await tester.tap(find.byKey(const Key('restorePurchasesButton')));
    await tester.pump();
    expect(store.restoreCount, 1);
  });

  testWidgets('現在のプランは再購入できない', (tester) async {
    final store = _FakePurchaseStore(
      const PurchaseStoreState(
        operation: PurchaseOperation.ready,
        products: [
          PurchaseProduct(
            id: PurchaseProductIds.fullMonthly,
            plan: AppAccessPlan.full,
            displayPrice: '￥500',
          ),
        ],
      ),
    );
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
        locale: const Locale('ja'),
        home: AccessPlanScreen(
          plan: AppAccessPlan.full,
          currentPlan: AppAccessPlan.full,
          purchaseStore: store,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('purchasePlanButton')),
      200,
    );
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('purchasePlanButton')),
    );
    expect(find.text('現在のプラン'), findsOneWidget);
    expect(button.onPressed, isNull);
  });
}

class _FakePurchaseStore implements PurchaseStore {
  _FakePurchaseStore(PurchaseStoreState initialState)
    : _state = ValueNotifier(initialState);

  final ValueNotifier<PurchaseStoreState> _state;
  final StreamController<AppAccessPlan> _entitlements =
      StreamController<AppAccessPlan>.broadcast();

  AppAccessPlan? purchasedPlan;
  int restoreCount = 0;

  @override
  ValueListenable<PurchaseStoreState> get state => _state;

  @override
  Stream<AppAccessPlan> get entitlementChanges => _entitlements.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> purchase(AppAccessPlan plan) async {
    purchasedPlan = plan;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCount += 1;
  }

  @override
  void dispose() {
    _state.dispose();
    _entitlements.close();
  }
}
