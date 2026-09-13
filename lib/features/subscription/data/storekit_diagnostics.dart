import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/app_access_plan.dart';
import '../domain/purchase_store.dart';

typedef StoreKitDiagnosticProductLoader =
    Future<ProductDetailsResponse> Function(Set<String> productIds);
typedef StoreKitNativeDiagnosticLoader =
    Future<Map<String, Object?>> Function();

class StoreKitDiagnosticProduct {
  const StoreKitDiagnosticProduct({
    required this.id,
    required this.displayPrice,
    required this.rawPrice,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final String id;
  final String displayPrice;
  final double rawPrice;
  final String currencyCode;
  final String currencySymbol;
}

class StoreKitDiagnosticEntitlement {
  const StoreKitDiagnosticEntitlement({
    required this.productId,
    required this.verification,
    required this.productType,
    required this.hasExpirationDate,
    required this.isExpired,
    required this.isRevoked,
  });

  final String productId;
  final String verification;
  final String productType;
  final bool hasExpirationDate;
  final bool isExpired;
  final bool isRevoked;

  bool get isVerified => verification == 'verified';
}

class StoreKitDiagnosticReport {
  const StoreKitDiagnosticReport({
    required this.storefrontCountryCode,
    required this.products,
    required this.nativeProducts,
    required this.notFoundProductIds,
    required this.entitlements,
    required this.adoptedPlan,
    this.productError,
    this.nativeProductError,
    this.nativeError,
  });

  final String? storefrontCountryCode;
  final List<StoreKitDiagnosticProduct> products;
  final List<StoreKitDiagnosticProduct> nativeProducts;
  final List<String> notFoundProductIds;
  final List<StoreKitDiagnosticEntitlement> entitlements;
  final AppAccessPlan adoptedPlan;
  final String? productError;
  final String? nativeProductError;
  final String? nativeError;

  bool get appleHasAdFree => entitlements.any(
    (entry) => entry.productId == PurchaseProductIds.adFree && entry.isVerified,
  );
  bool get appleHasFull => entitlements.any(
    (entry) =>
        entry.productId == PurchaseProductIds.fullMonthly && entry.isVerified,
  );
}

class StoreKitDiagnosticsSource {
  StoreKitDiagnosticsSource({
    StoreKitDiagnosticProductLoader? loadProducts,
    StoreKitNativeDiagnosticLoader? loadNativeDiagnostics,
  }) : _loadProducts =
           loadProducts ?? InAppPurchase.instance.queryProductDetails,
       _loadNativeDiagnostics =
           loadNativeDiagnostics ?? _loadNativeDiagnosticsFromChannel;

  static const _channel = MethodChannel(
    'com.matsumotoboundary.constructioncalc/storekit_entitlements',
  );

  final StoreKitDiagnosticProductLoader _loadProducts;
  final StoreKitNativeDiagnosticLoader _loadNativeDiagnostics;

  Future<StoreKitDiagnosticReport> load(AppAccessPlan adoptedPlan) async {
    var products = const <StoreKitDiagnosticProduct>[];
    var notFoundProductIds = const <String>[];
    String? productError;
    try {
      final response = await _loadProducts(PurchaseProductIds.all);
      products = response.productDetails
          .where((product) => PurchaseProductIds.all.contains(product.id))
          .map(
            (product) => StoreKitDiagnosticProduct(
              id: product.id,
              displayPrice: product.price,
              rawPrice: product.rawPrice,
              currencyCode: product.currencyCode,
              currencySymbol: product.currencySymbol,
            ),
          )
          .toList(growable: false);
      notFoundProductIds = response.notFoundIDs
          .where(PurchaseProductIds.all.contains)
          .toList(growable: false);
      productError = response.error?.message;
    } catch (error) {
      productError = error.runtimeType.toString();
    }

    String? storefrontCountryCode;
    var nativeProducts = const <StoreKitDiagnosticProduct>[];
    var entitlements = const <StoreKitDiagnosticEntitlement>[];
    String? nativeProductError;
    String? nativeError;
    try {
      final native = await _loadNativeDiagnostics();
      storefrontCountryCode = native['storefrontCountryCode'] as String?;
      nativeProducts = (native['nativeProducts'] as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (entry) => StoreKitDiagnosticProduct(
              id: entry['productId'] as String? ?? '',
              displayPrice: entry['displayPrice'] as String? ?? '',
              rawPrice: (entry['rawPrice'] as num?)?.toDouble() ?? 0,
              currencyCode: entry['currencyCode'] as String? ?? '',
              currencySymbol: entry['currencySymbol'] as String? ?? '',
            ),
          )
          .where((product) => PurchaseProductIds.all.contains(product.id))
          .toList(growable: false);
      final nativeProductErrorValue = native['nativeProductError'] as String?;
      if (nativeProductErrorValue?.isNotEmpty ?? false) {
        nativeProductError = nativeProductErrorValue;
      }
      entitlements = (native['entitlements'] as List<Object?>? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .map(
            (entry) => StoreKitDiagnosticEntitlement(
              productId: entry['productId'] as String? ?? '',
              verification: entry['verification'] as String? ?? 'unknown',
              productType: entry['productType'] as String? ?? 'unknown',
              hasExpirationDate: entry['hasExpirationDate'] as bool? ?? false,
              isExpired: entry['isExpired'] as bool? ?? false,
              isRevoked: entry['isRevoked'] as bool? ?? false,
            ),
          )
          .where((entry) => PurchaseProductIds.all.contains(entry.productId))
          .toList(growable: false);
    } catch (error) {
      nativeError = error.runtimeType.toString();
    }

    return StoreKitDiagnosticReport(
      storefrontCountryCode: storefrontCountryCode,
      products: products,
      nativeProducts: nativeProducts,
      notFoundProductIds: notFoundProductIds,
      entitlements: entitlements,
      adoptedPlan: adoptedPlan,
      productError: productError,
      nativeProductError: nativeProductError,
      nativeError: nativeError,
    );
  }

  static Future<Map<String, Object?>>
  _loadNativeDiagnosticsFromChannel() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'loadStoreKitDiagnostics',
    );
    return result ?? const <String, Object?>{};
  }
}
