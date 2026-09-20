import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:instant_estimate/features/subscription/data/google_play_entitlement_source.dart';
import 'package:instant_estimate/features/subscription/domain/purchase_store.dart';

void main() {
  test('Google Playが返した所有中の対象商品のみ権利として返す', () async {
    final source = GooglePlayEntitlementSource(
      queryPurchases: () async => [
        _purchase(PurchaseProductIds.adFree, PurchaseStatus.purchased),
        _purchase(PurchaseProductIds.fullMonthly, PurchaseStatus.restored),
        _purchase(PurchaseProductIds.fullMonthly, PurchaseStatus.pending),
        _purchase('unknown', PurchaseStatus.purchased),
      ],
    );

    final result = await source.load(synchronize: false);

    expect(result, {
      PurchaseProductIds.adFree,
      PurchaseProductIds.fullMonthly,
    });
  });

  test('購入トークンまたは購入データが不足する商品は付与しない', () async {
    final source = GooglePlayEntitlementSource(
      queryPurchases: () async => [
        _purchase(
          PurchaseProductIds.adFree,
          PurchaseStatus.purchased,
          localVerificationData: '',
        ),
        _purchase(
          PurchaseProductIds.fullMonthly,
          PurchaseStatus.purchased,
          serverVerificationData: '',
        ),
      ],
    );

    final result = await source.load(synchronize: false);

    expect(result, isEmpty);
  });

  test('追加検証で拒否された商品は付与しない', () async {
    final verifiedProducts = <String>[];
    final source = GooglePlayEntitlementSource(
      queryPurchases: () async => [
        _purchase(PurchaseProductIds.adFree, PurchaseStatus.purchased),
        _purchase(PurchaseProductIds.fullMonthly, PurchaseStatus.purchased),
      ],
      verifyPurchase: (purchase) async {
        verifiedProducts.add(purchase.productID);
        return purchase.productID == PurchaseProductIds.adFree;
      },
    );

    final result = await source.load(synchronize: true);

    expect(verifiedProducts, [
      PurchaseProductIds.adFree,
      PurchaseProductIds.fullMonthly,
    ]);
    expect(result, {PurchaseProductIds.adFree});
  });

  test('Google Play照会失敗を権利なしとして扱わず呼び出し側へ返す', () async {
    final source = GooglePlayEntitlementSource(
      queryPurchases: () => Future<List<PurchaseDetails>>.error(
        Exception('offline'),
      ),
    );

    expect(
      () => source.load(synchronize: false),
      throwsA(isA<Exception>()),
    );
  });
}

PurchaseDetails _purchase(
  String productId,
  PurchaseStatus status, {
  String localVerificationData = 'purchase-json',
  String serverVerificationData = 'purchase-token',
}) {
  return PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: localVerificationData,
      serverVerificationData: serverVerificationData,
      source: 'google_play',
    ),
    transactionDate: '0',
    status: status,
  );
}
