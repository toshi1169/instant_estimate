import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../domain/purchase_store.dart';

typedef GooglePlayPurchaseQuery = Future<List<PurchaseDetails>> Function();
typedef GooglePlayPurchaseVerifier =
    Future<bool> Function(PurchaseDetails purchase);

/// Loads the non-consumable and subscription entitlements currently owned by
/// the signed-in Google Play account.
///
/// The default verifier rejects incomplete Billing Client records. A
/// server-backed verifier can be injected later without changing the purchase
/// store or UI.
class GooglePlayEntitlementSource {
  GooglePlayEntitlementSource({
    InAppPurchase? inAppPurchase,
    GooglePlayPurchaseQuery? queryPurchases,
    GooglePlayPurchaseVerifier? verifyPurchase,
  }) : assert(inAppPurchase != null || queryPurchases != null),
       _queryPurchases =
           queryPurchases ?? (() => _queryPastPurchases(inAppPurchase!)),
       _verifyPurchase = verifyPurchase ?? _hasRequiredVerificationData;

  final GooglePlayPurchaseQuery _queryPurchases;
  final GooglePlayPurchaseVerifier _verifyPurchase;

  Future<Set<String>> load({required bool synchronize}) async {
    final purchases = await _queryPurchases();
    final activeProductIds = <String>{};

    for (final purchase in purchases) {
      final isOwned =
          purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;
      if (!isOwned ||
          PurchaseProductIds.planFor(purchase.productID) == null ||
          !await _verifyPurchase(purchase)) {
        continue;
      }
      activeProductIds.add(purchase.productID);
    }

    return Set.unmodifiable(activeProductIds);
  }

  static Future<List<PurchaseDetails>> _queryPastPurchases(
    InAppPurchase inAppPurchase,
  ) async {
    final platformAddition = inAppPurchase
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await platformAddition.queryPastPurchases();
    final error = response.error;
    if (error != null) throw error;
    return response.pastPurchases;
  }

  static Future<bool> _hasRequiredVerificationData(
    PurchaseDetails purchase,
  ) async {
    final verificationData = purchase.verificationData;
    return verificationData.source.isNotEmpty &&
        verificationData.localVerificationData.isNotEmpty &&
        verificationData.serverVerificationData.isNotEmpty;
  }
}
