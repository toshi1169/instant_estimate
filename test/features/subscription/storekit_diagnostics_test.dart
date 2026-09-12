import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/subscription/data/storekit_diagnostics.dart';
import 'package:instant_estimate/features/subscription/domain/purchase_store.dart';
import 'package:instant_estimate/features/subscription/presentation/storekit_diagnostics_screen.dart';

void main() {
  test('StoreKitの商品価格を加工せずID別に診断へ保持する', () async {
    final source = StoreKitDiagnosticsSource(
      loadProducts: (ids) async {
        expect(ids, PurchaseProductIds.all);
        return ProductDetailsResponse(
          productDetails: [
            ProductDetails(
              id: PurchaseProductIds.adFree,
              title: 'AdFree',
              description: '',
              price: r'$3.99',
              rawPrice: 3.99,
              currencyCode: 'USD',
              currencySymbol: r'$',
            ),
            ProductDetails(
              id: PurchaseProductIds.fullMonthly,
              title: 'Full',
              description: '',
              price: '¥500',
              rawPrice: 500,
              currencyCode: 'JPY',
              currencySymbol: '¥',
            ),
          ],
          notFoundIDs: const [],
        );
      },
      loadNativeDiagnostics: () async => <String, Object?>{
        'storefrontCountryCode': 'JPN',
        'entitlements': <Object?>[
          <Object?, Object?>{
            'productId': PurchaseProductIds.fullMonthly,
            'verification': 'verified',
            'productType': 'Auto-Renewable Subscription',
            'hasExpirationDate': true,
            'isExpired': false,
            'isRevoked': false,
          },
        ],
      },
    );

    final report = await source.load(AppAccessPlan.full);

    expect(report.storefrontCountryCode, 'JPN');
    expect(report.products[0].displayPrice, r'$3.99');
    expect(report.products[0].rawPrice, 3.99);
    expect(report.products[0].currencyCode, 'USD');
    expect(report.products[1].id, PurchaseProductIds.fullMonthly);
    expect(report.products[1].displayPrice, '¥500');
    expect(report.appleHasAdFree, isFalse);
    expect(report.appleHasFull, isTrue);
    expect(report.adoptedPlan, AppAccessPlan.full);
  });

  test('unverified entitlementはApple verified権利として扱わない', () async {
    final source = StoreKitDiagnosticsSource(
      loadProducts: (_) async => ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: const [],
      ),
      loadNativeDiagnostics: () async => <String, Object?>{
        'entitlements': <Object?>[
          <Object?, Object?>{
            'productId': PurchaseProductIds.adFree,
            'verification': 'unverified',
            'productType': 'Non-Consumable',
          },
        ],
      },
    );

    final report = await source.load(AppAccessPlan.adFree);

    expect(report.appleHasAdFree, isFalse);
    expect(report.adoptedPlan, AppAccessPlan.adFree);
  });

  testWidgets('診断画面はStorefront・Apple権利・アプリ採用Planを表示する', (tester) async {
    final source = StoreKitDiagnosticsSource(
      loadProducts: (_) async => ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: const [],
      ),
      loadNativeDiagnostics: () async => <String, Object?>{
        'storefrontCountryCode': 'JPN',
        'entitlements': const <Object?>[],
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StoreKitDiagnosticsScreen(
          adoptedPlan: AppAccessPlan.full,
          source: source,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Storefront country: JPN'), findsOneWidget);
    expect(find.text('Apple verified Full: No'), findsOneWidget);
    expect(find.text('App adopted plan: full'), findsOneWidget);
  });
}
