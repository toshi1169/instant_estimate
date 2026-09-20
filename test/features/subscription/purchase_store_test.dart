import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/subscription/data/in_app_purchase_store.dart';
import 'package:instant_estimate/features/subscription/domain/purchase_store.dart';
import 'package:instant_estimate/features/subscription/presentation/access_plan_screen.dart';

void main() {
  test('購入画面の法的リンク文言を8言語で直接取得できる', () {
    const expected = <AppLanguage, (String, String)>{
      AppLanguage.japanese: ('プライバシーポリシー', '利用規約'),
      AppLanguage.english: ('Privacy Policy', 'Terms of Use'),
      AppLanguage.simplifiedChinese: ('隐私政策', '使用条款'),
      AppLanguage.traditionalChinese: ('隱私權政策', '使用條款'),
      AppLanguage.vietnamese: (
        'Chính sách quyền riêng tư',
        'Điều khoản sử dụng',
      ),
      AppLanguage.indonesian: ('Kebijakan Privasi', 'Ketentuan Penggunaan'),
      AppLanguage.filipino: (
        'Patakaran sa Privacy',
        'Mga Tuntunin ng Paggamit',
      ),
      AppLanguage.myanmar: (
        'ကိုယ်ရေးအချက်အလက် မူဝါဒ',
        'အသုံးပြုမှု စည်းမျဉ်းများ',
      ),
    };

    for (final entry in expected.entries) {
      final strings = AppLocalizations(entry.key);
      expect(strings.privacyPolicy, entry.value.$1);
      expect(strings.termsOfUse, entry.value.$2);
      expect(strings.externalLinkOpenFailed, isNotEmpty);
    }
  });

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

  group('現在有効な権利の再確認', () {
    test('有効なfullを完全版として返す', () async {
      final result = await _refreshWithProducts([
        PurchaseProductIds.fullMonthly,
      ]);

      expect(result.isVerified, isTrue);
      expect(result.effectivePlan, AppAccessPlan.full);
    });

    test('fullとadFreeの両方を所有する場合はfullを優先する', () async {
      final result = await _refreshWithProducts([
        PurchaseProductIds.adFree,
        PurchaseProductIds.fullMonthly,
      ]);

      expect(result.effectivePlan, AppAccessPlan.full);
    });

    test('期限切れfullが現在権利に含まれなければfreeへ戻す', () async {
      final result = await _refreshWithProducts(const []);

      expect(result.isVerified, isTrue);
      expect(result.effectivePlan, AppAccessPlan.free);
    });

    test('期限切れfullでもadFreeを所有していればadFreeへ戻す', () async {
      final result = await _refreshWithProducts([PurchaseProductIds.adFree]);

      expect(result.effectivePlan, AppAccessPlan.adFree);
    });

    test('取消済みfullが除外されadFreeもなければfreeへ戻す', () async {
      final result = await _refreshWithProducts(const []);

      expect(result.effectivePlan, AppAccessPlan.free);
    });

    test('復元結果が空でも確認成功としてfreeを返す', () async {
      final result = await _refreshWithProducts(const []);

      expect(result.status, PurchaseEntitlementRefreshStatus.verified);
      expect(result.activePlans, isEmpty);
    });

    test('Store問い合わせ失敗を有効権利なしと区別する', () async {
      final store = InAppPurchaseStore(
        purchaseStream: const Stream<List<PurchaseDetails>>.empty(),
        loadVerifiedEntitlements: ({required synchronize}) =>
            Future<Set<String>>.error(Exception('offline')),
      );
      addTearDown(store.dispose);

      final result = await store.refreshEntitlements();

      expect(result.status, PurchaseEntitlementRefreshStatus.failed);
      expect(result.isVerified, isFalse);
    });

    test('verificationDataが非空でもverified entitlementが無ければ付与しない', () async {
      final updates = StreamController<List<PurchaseDetails>>.broadcast();
      final completed = <PurchaseDetails>[];
      final store = InAppPurchaseStore(
        purchaseStream: updates.stream,
        loadVerifiedEntitlements: ({required synchronize}) async => const {},
        completePurchase: (purchase) async => completed.add(purchase),
      );
      addTearDown(() async {
        store.dispose();
        await updates.close();
      });

      await store.refreshEntitlements();
      final snapshotFuture = store.entitlementSnapshots.first;
      final purchase = _purchaseDetails(
        PurchaseProductIds.fullMonthly,
        PurchaseStatus.purchased,
        pendingCompletePurchase: true,
      );
      updates.add([purchase]);

      final snapshot = await snapshotFuture;
      await Future<void>.delayed(Duration.zero);

      expect(snapshot.effectivePlan, AppAccessPlan.free);
      expect(completed, isEmpty);
      expect(store.state.value.operation, PurchaseOperation.error);
    });

    test('購入直後はStoreKit verified entitlementだけを付与して完了する', () async {
      final updates = StreamController<List<PurchaseDetails>>.broadcast();
      final completed = <PurchaseDetails>[];
      final store = InAppPurchaseStore(
        purchaseStream: updates.stream,
        loadVerifiedEntitlements: ({required synchronize}) async => {
          PurchaseProductIds.fullMonthly,
        },
        completePurchase: (purchase) async => completed.add(purchase),
      );
      addTearDown(() async {
        store.dispose();
        await updates.close();
      });

      await store.refreshEntitlements();
      final snapshotFuture = store.entitlementSnapshots.first;
      final purchase = _purchaseDetails(
        PurchaseProductIds.fullMonthly,
        PurchaseStatus.purchased,
        pendingCompletePurchase: true,
      );
      updates.add([purchase]);

      final snapshot = await snapshotFuture;
      await Future<void>.delayed(Duration.zero);

      expect(snapshot.activePlans, {AppAccessPlan.full});
      expect(snapshot.effectivePlan, AppAccessPlan.full);
      expect(completed, [purchase]);
      expect(store.state.value.operation, PurchaseOperation.completed);
    });

    test('pending・cancelled・errorでは権利確認も付与も完了もしない', () async {
      final updates = StreamController<List<PurchaseDetails>>.broadcast();
      var loadCount = 0;
      final completed = <PurchaseDetails>[];
      final store = InAppPurchaseStore(
        purchaseStream: updates.stream,
        loadVerifiedEntitlements: ({required synchronize}) async {
          loadCount += 1;
          return {PurchaseProductIds.fullMonthly};
        },
        completePurchase: (purchase) async => completed.add(purchase),
      );
      addTearDown(() async {
        store.dispose();
        await updates.close();
      });

      await store.refreshEntitlements();
      loadCount = 0;
      updates.add([
        _purchaseDetails(
          PurchaseProductIds.fullMonthly,
          PurchaseStatus.pending,
          pendingCompletePurchase: true,
        ),
        _purchaseDetails(
          PurchaseProductIds.fullMonthly,
          PurchaseStatus.canceled,
          pendingCompletePurchase: true,
        ),
        _purchaseDetails(
          PurchaseProductIds.fullMonthly,
          PurchaseStatus.error,
          pendingCompletePurchase: true,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(loadCount, 0);
      expect(completed, isEmpty);
      expect(store.state.value.operation, PurchaseOperation.error);
    });

    test('復元はStore同期後のverified current entitlementsで確定する', () async {
      bool? synchronizeArgument;
      final store = InAppPurchaseStore(
        purchaseStream: const Stream<List<PurchaseDetails>>.empty(),
        loadVerifiedEntitlements: ({required synchronize}) async {
          synchronizeArgument = synchronize;
          return {PurchaseProductIds.adFree};
        },
      );
      addTearDown(store.dispose);

      final snapshotFuture = store.entitlementSnapshots.first;
      await store.restorePurchases();
      final snapshot = await snapshotFuture;

      expect(synchronizeArgument, isTrue);
      expect(snapshot.effectivePlan, AppAccessPlan.adFree);
      expect(store.state.value.operation, PurchaseOperation.ready);
    });

    test('Android復元はGoogle Play復元後に現在権利を再照会する', () async {
      final events = <String>[];
      final store = InAppPurchaseStore(
        targetPlatform: TargetPlatform.android,
        purchaseStream: const Stream<List<PurchaseDetails>>.empty(),
        restorePurchases: () async => events.add('restore'),
        loadVerifiedEntitlements: ({required synchronize}) async {
          events.add('load:$synchronize');
          return {PurchaseProductIds.fullMonthly};
        },
      );
      addTearDown(store.dispose);

      final snapshotFuture = store.entitlementSnapshots.first;
      await store.restorePurchases();
      final snapshot = await snapshotFuture;

      expect(events, ['restore', 'load:true']);
      expect(snapshot.effectivePlan, AppAccessPlan.full);
      expect(store.state.value.operation, PurchaseOperation.ready);
    });

    test('Android復元APIの失敗では権利を変更せずエラーにする', () async {
      var entitlementLoadCount = 0;
      final store = InAppPurchaseStore(
        targetPlatform: TargetPlatform.android,
        purchaseStream: const Stream<List<PurchaseDetails>>.empty(),
        restorePurchases: () => Future<void>.error(Exception('offline')),
        loadVerifiedEntitlements: ({required synchronize}) async {
          entitlementLoadCount += 1;
          return {PurchaseProductIds.fullMonthly};
        },
      );
      addTearDown(store.dispose);

      final snapshotFuture = store.entitlementSnapshots.first;
      await store.restorePurchases();
      final snapshot = await snapshotFuture;

      expect(snapshot.isVerified, isFalse);
      expect(entitlementLoadCount, 0);
      expect(store.state.value.operation, PurchaseOperation.error);
    });
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
        supportedLocales: const [
          Locale('ja'),
          Locale('en'),
          Locale('zh', 'CN'),
        ],
        locale: const Locale('ja'),
        home: AccessPlanScreen(
          plan: AppAccessPlan.adFree,
          purchaseStore: store,
        ),
      ),
    );

    expect(find.text('￥320'), findsOneWidget);
    expect(find.text('買い切り'), findsOneWidget);
    await tester.pump();
    expect(store.refreshProductsCount, 1);
    await tester.tap(find.byKey(const Key('purchasePlanButton')));
    await tester.pump();
    expect(store.purchasedPlan, AppAccessPlan.adFree);

    await tester.ensureVisible(find.byKey(const Key('restorePurchasesButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restorePurchasesButton')));
    await tester.pump();
    expect(store.restoreCount, 1);
  });

  testWidgets('StoreKitのドル・ユーロ価格を加工せず表示する', (tester) async {
    for (final value in const ['\$3.99', '€2.49']) {
      final store = _FakePurchaseStore(
        PurchaseStoreState(
          operation: PurchaseOperation.ready,
          products: [
            PurchaseProduct(
              id: PurchaseProductIds.fullMonthly,
              plan: AppAccessPlan.full,
              displayPrice: value,
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
          supportedLocales: const [Locale('ja')],
          home: AccessPlanScreen(
            plan: AppAccessPlan.full,
            purchaseStore: store,
          ),
        ),
      );

      expect(find.text(value), findsOneWidget);
      expect(find.text('月額'), findsOneWidget);
      expect(find.text('初回のみ7日間無料体験'), findsOneWidget);
    }
  });

  testWidgets('商品取得中と取得失敗では固定円価格を表示しない', (tester) async {
    for (final operation in const [
      PurchaseOperation.loading,
      PurchaseOperation.unavailable,
    ]) {
      final store = _FakePurchaseStore(
        PurchaseStoreState(operation: operation),
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
          supportedLocales: const [Locale('ja')],
          home: AccessPlanScreen(
            plan: AppAccessPlan.adFree,
            purchaseStore: store,
          ),
        ),
      );

      expect(find.text('¥300（買い切り）'), findsNothing);
      expect(find.text('¥500／月'), findsNothing);
      expect(
        find.text(operation == PurchaseOperation.loading ? '価格を取得中…' : '—'),
        findsOneWidget,
      );
      expect(find.text('買い切り'), findsOneWidget);
    }
  });

  testWidgets('商品画面を開き直すたび商品情報を再取得する', (tester) async {
    final store = _FakePurchaseStore(
      const PurchaseStoreState(operation: PurchaseOperation.unavailable),
    );
    addTearDown(store.dispose);

    Widget screen() => MaterialApp(
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja')],
      home: AccessPlanScreen(plan: AppAccessPlan.adFree, purchaseStore: store),
    );

    await tester.pumpWidget(screen());
    await tester.pump();
    expect(store.refreshProductsCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(screen());
    await tester.pump();
    expect(store.refreshProductsCount, 2);
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

    expect(find.text('￥500'), findsOneWidget);
    expect(find.text('月額'), findsOneWidget);
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

  testWidgets('商品情報が未取得でもストアへの再接続を試せる', (tester) async {
    final store = _FakePurchaseStore(
      const PurchaseStoreState(operation: PurchaseOperation.unavailable),
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

    expect(find.text('ストアへ接続'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('purchasePlanButton')),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('purchasePlanButton')));
    await tester.pump();
    expect(store.purchasedPlan, AppAccessPlan.adFree);
  });

  testWidgets('簡体字中国語で購入プランを表示できる', (tester) async {
    final store = _FakePurchaseStore(
      const PurchaseStoreState(
        operation: PurchaseOperation.ready,
        products: [
          PurchaseProduct(
            id: PurchaseProductIds.fullMonthly,
            plan: AppAccessPlan.full,
            displayPrice: '¥500',
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
        supportedLocales: const [
          Locale('ja'),
          Locale('en'),
          Locale('zh', 'CN'),
        ],
        locale: const Locale('zh', 'CN'),
        home: AccessPlanScreen(plan: AppAccessPlan.full, purchaseStore: store),
      ),
    );

    expect(find.text('完整版'), findsWidgets);
    expect(find.text('首次使用可免费试用7天'), findsOneWidget);
    expect(find.text('使用今后新增的完整版功能'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('purchasePlanButton')),
      200,
    );
    await tester.pumpAndSettle();

    expect(find.text('购买'), findsOneWidget);
    expect(find.text('恢复购买记录'), findsOneWidget);
  });

  testWidgets('完全版画面の法的リンクは正しいURLを開き購入・復元を開始しない', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _FakePurchaseStore(
      const PurchaseStoreState(operation: PurchaseOperation.ready),
    );
    addTearDown(store.dispose);
    final openedUris = <Uri>[];

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
          purchaseStore: store,
          externalUrlLauncher: (uri) async {
            openedUris.add(uri);
            return true;
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('termsOfUseLink')),
      200,
    );
    await tester.pumpAndSettle();
    expect(find.text('プライバシーポリシー'), findsOneWidget);
    expect(find.text('利用規約'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('privacyPolicyLink')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('termsOfUseLink')));
    await tester.pump();

    expect(openedUris, [Uri.parse(privacyPolicyUrl), Uri.parse(termsOfUseUrl)]);
    expect(store.purchasedPlan, isNull);
    expect(store.restoreCount, 0);
  });

  testWidgets('法的リンクの起動失敗ではクラッシュせず案内を表示する', (tester) async {
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
          externalUrlLauncher: (_) async => false,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('privacyPolicyLink')),
      200,
    );
    await tester.tap(find.byKey(const Key('privacyPolicyLink')));
    await tester.pump();

    expect(find.text('リンクを開けませんでした'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakePurchaseStore implements PurchaseStore {
  _FakePurchaseStore(PurchaseStoreState initialState)
    : _state = ValueNotifier(initialState);

  final ValueNotifier<PurchaseStoreState> _state;
  final StreamController<PurchaseEntitlementSnapshot> _snapshots =
      StreamController<PurchaseEntitlementSnapshot>.broadcast();

  AppAccessPlan? purchasedPlan;
  int restoreCount = 0;
  int refreshProductsCount = 0;

  @override
  ValueListenable<PurchaseStoreState> get state => _state;

  @override
  Stream<PurchaseEntitlementSnapshot> get entitlementSnapshots =>
      _snapshots.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshProducts() async {
    refreshProductsCount += 1;
  }

  @override
  Future<void> purchase(AppAccessPlan plan) async {
    purchasedPlan = plan;
  }

  @override
  Future<PurchaseEntitlementSnapshot> refreshEntitlements() async {
    return PurchaseEntitlementSnapshot.verified(const []);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCount += 1;
  }

  @override
  void dispose() {
    _state.dispose();
    _snapshots.close();
  }
}

Future<PurchaseEntitlementSnapshot> _refreshWithProducts(
  List<String> productIds,
) async {
  final store = InAppPurchaseStore(
    purchaseStream: const Stream<List<PurchaseDetails>>.empty(),
    loadVerifiedEntitlements: ({required synchronize}) async =>
        productIds.toSet(),
  );
  try {
    return await store.refreshEntitlements();
  } finally {
    store.dispose();
  }
}

PurchaseDetails _purchaseDetails(
  String productId,
  PurchaseStatus status, {
  bool pendingCompletePurchase = false,
}) {
  final purchase = PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'verified',
      serverVerificationData: 'verified',
      source: 'test',
    ),
    transactionDate: '0',
    status: status,
  );
  purchase.pendingCompletePurchase = pendingCompletePurchase;
  return purchase;
}
