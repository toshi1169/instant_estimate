import 'package:flutter/foundation.dart';

import '../../../core/domain/app_access_plan.dart';

/// Store product identifiers are kept in one place because the identifiers
/// registered in App Store Connect and Google Play cannot be changed later.
abstract final class PurchaseProductIds {
  static const adFree = 'instant_estimate_ad_free';
  static const fullMonthly = 'instant_estimate_full_monthly';

  static const all = <String>{adFree, fullMonthly};

  static String? forPlan(AppAccessPlan plan) => switch (plan) {
    AppAccessPlan.adFree => adFree,
    AppAccessPlan.full => fullMonthly,
    AppAccessPlan.free => null,
  };

  static AppAccessPlan? planFor(String productId) => switch (productId) {
    adFree => AppAccessPlan.adFree,
    fullMonthly => AppAccessPlan.full,
    _ => null,
  };
}

enum PurchaseOperation {
  idle,
  loading,
  ready,
  purchasing,
  restoring,
  completed,
  unavailable,
  error,
}

@immutable
class PurchaseProduct {
  const PurchaseProduct({
    required this.id,
    required this.plan,
    required this.displayPrice,
  });

  final String id;
  final AppAccessPlan plan;
  final String displayPrice;
}

@immutable
class PurchaseStoreState {
  const PurchaseStoreState({
    this.operation = PurchaseOperation.idle,
    this.products = const [],
    this.message,
  });

  final PurchaseOperation operation;
  final List<PurchaseProduct> products;
  final String? message;

  bool get isBusy =>
      operation == PurchaseOperation.loading ||
      operation == PurchaseOperation.purchasing ||
      operation == PurchaseOperation.restoring;

  PurchaseProduct? productFor(AppAccessPlan plan) {
    for (final product in products) {
      if (product.plan == plan) return product;
    }
    return null;
  }
}

enum PurchaseEntitlementRefreshStatus { verified, failed }

@immutable
class PurchaseEntitlementSnapshot {
  const PurchaseEntitlementSnapshot._({
    required this.status,
    this.activePlans = const <AppAccessPlan>{},
    this.message,
  });

  factory PurchaseEntitlementSnapshot.verified(
    Iterable<AppAccessPlan> activePlans,
  ) {
    return PurchaseEntitlementSnapshot._(
      status: PurchaseEntitlementRefreshStatus.verified,
      activePlans: Set.unmodifiable(activePlans),
    );
  }

  const PurchaseEntitlementSnapshot.failed([String? message])
    : this._(status: PurchaseEntitlementRefreshStatus.failed, message: message);

  final PurchaseEntitlementRefreshStatus status;
  final Set<AppAccessPlan> activePlans;
  final String? message;

  bool get isVerified => status == PurchaseEntitlementRefreshStatus.verified;

  AppAccessPlan get effectivePlan {
    if (activePlans.contains(AppAccessPlan.full)) return AppAccessPlan.full;
    if (activePlans.contains(AppAccessPlan.adFree)) {
      return AppAccessPlan.adFree;
    }
    return AppAccessPlan.free;
  }
}

abstract interface class PurchaseStore {
  ValueListenable<PurchaseStoreState> get state;
  Stream<PurchaseEntitlementSnapshot> get entitlementSnapshots;

  Future<void> initialize();
  Future<void> purchase(AppAccessPlan plan);
  Future<PurchaseEntitlementSnapshot> refreshEntitlements();
  Future<void> restorePurchases();
  void dispose();
}
