import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/app_access_plan.dart';
import '../domain/purchase_store.dart';
import 'storekit_verified_entitlement_source.dart';

typedef PurchaseCompleter = Future<void> Function(PurchaseDetails purchase);

class InAppPurchaseStore implements PurchaseStore {
  InAppPurchaseStore({
    InAppPurchase? inAppPurchase,
    Stream<List<PurchaseDetails>>? purchaseStream,
    VerifiedEntitlementLoader? loadVerifiedEntitlements,
    PurchaseCompleter? completePurchase,
  }) : _inAppPurchase =
           inAppPurchase ??
           (purchaseStream == null ? InAppPurchase.instance : null) {
    _purchaseStream = purchaseStream ?? _inAppPurchase!.purchaseStream;
    _loadVerifiedEntitlements =
        loadVerifiedEntitlements ?? StoreKitVerifiedEntitlementSource().load;
    _completePurchase =
        completePurchase ?? _inAppPurchase?.completePurchase ?? (_) async {};
  }

  final InAppPurchase? _inAppPurchase;
  late final Stream<List<PurchaseDetails>> _purchaseStream;
  late final VerifiedEntitlementLoader _loadVerifiedEntitlements;
  late final PurchaseCompleter _completePurchase;
  final ValueNotifier<PurchaseStoreState> _state = ValueNotifier(
    const PurchaseStoreState(),
  );
  final StreamController<PurchaseEntitlementSnapshot> _entitlementSnapshots =
      StreamController<PurchaseEntitlementSnapshot>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Map<String, ProductDetails> _productDetails = const {};
  bool _initialized = false;
  Future<PurchaseEntitlementSnapshot>? _refreshingEntitlements;

  @override
  ValueListenable<PurchaseStoreState> get state => _state;

  @override
  Stream<PurchaseEntitlementSnapshot> get entitlementSnapshots =>
      _entitlementSnapshots.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _ensurePurchaseListener();
    _setState(PurchaseOperation.loading);

    try {
      await _loadProducts();
    } catch (error) {
      _setState(PurchaseOperation.error, message: error.toString());
    }
  }

  void _ensurePurchaseListener() {
    _purchaseSubscription ??= _purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _setState(PurchaseOperation.error, message: error.toString());
      },
    );
  }

  @override
  Future<void> purchase(AppAccessPlan plan) async {
    try {
      final productId = PurchaseProductIds.forPlan(plan);
      var product = productId == null ? null : _productDetails[productId];
      if (product == null && productId != null) {
        _setState(PurchaseOperation.loading);
        await _loadProducts();
        product = _productDetails[productId];
      }
      if (product == null) {
        _setState(
          PurchaseOperation.unavailable,
          message: 'Store product could not be loaded.',
        );
        return;
      }
      _setState(PurchaseOperation.purchasing);
      final started = await _inAppPurchase!.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _setState(PurchaseOperation.error);
      }
    } catch (error) {
      _setState(PurchaseOperation.error, message: error.toString());
    }
  }

  Future<void> _loadProducts() async {
    if (!await _inAppPurchase!.isAvailable()) {
      _setState(PurchaseOperation.unavailable);
      return;
    }
    final response = await _inAppPurchase.queryProductDetails(
      PurchaseProductIds.all,
    );
    if (response.error != null) {
      _setState(PurchaseOperation.error, message: response.error!.message);
      return;
    }
    _productDetails = {
      for (final product in response.productDetails) product.id: product,
    };
    final products = response.productDetails
        .map((product) {
          final plan = PurchaseProductIds.planFor(product.id);
          return plan == null
              ? null
              : PurchaseProduct(
                  id: product.id,
                  plan: plan,
                  displayPrice: product.price,
                );
        })
        .whereType<PurchaseProduct>()
        .toList(growable: false);
    _state.value = PurchaseStoreState(
      operation: products.isEmpty
          ? PurchaseOperation.unavailable
          : PurchaseOperation.ready,
      products: products,
    );
  }

  @override
  Future<void> restorePurchases() async {
    _setState(PurchaseOperation.restoring);
    await _refreshEntitlements(synchronize: true);
  }

  @override
  Future<PurchaseEntitlementSnapshot> refreshEntitlements() {
    return _refreshEntitlements(synchronize: false);
  }

  Future<PurchaseEntitlementSnapshot> _refreshEntitlements({
    required bool synchronize,
  }) {
    final pending = _refreshingEntitlements;
    if (pending != null) return pending;
    final refresh = _refreshCurrentEntitlements(synchronize: synchronize);
    _refreshingEntitlements = refresh;
    return refresh.whenComplete(() => _refreshingEntitlements = null);
  }

  Future<PurchaseEntitlementSnapshot> _refreshCurrentEntitlements({
    required bool synchronize,
  }) async {
    _ensurePurchaseListener();
    PurchaseEntitlementSnapshot snapshot;
    try {
      final productIds = await _loadVerifiedEntitlements(
        synchronize: synchronize,
      );
      snapshot = PurchaseEntitlementSnapshot.verified(
        productIds.map(PurchaseProductIds.planFor).whereType<AppAccessPlan>(),
      );
      if (_state.value.operation == PurchaseOperation.restoring) {
        _setState(PurchaseOperation.ready);
      }
    } catch (error) {
      snapshot = PurchaseEntitlementSnapshot.failed(error.toString());
      _setState(PurchaseOperation.error, message: error.toString());
    }
    _entitlementSnapshots.add(snapshot);
    return snapshot;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final completedPurchases = purchases
        .where(
          (purchase) =>
              purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored,
        )
        .where(
          (purchase) => PurchaseProductIds.planFor(purchase.productID) != null,
        )
        .toList(growable: false);

    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.error) {
        _setState(PurchaseOperation.error, message: purchase.error?.message);
      } else if (purchase.status == PurchaseStatus.canceled) {
        _setState(PurchaseOperation.ready);
      }
    }

    if (completedPurchases.isEmpty) return;

    final snapshot = await refreshEntitlements();
    if (!snapshot.isVerified) return;

    var granted = false;
    for (final purchase in completedPurchases) {
      final plan = PurchaseProductIds.planFor(purchase.productID)!;
      if (!snapshot.activePlans.contains(plan)) continue;
      granted = true;
      if (purchase.pendingCompletePurchase) {
        try {
          await _completePurchase(purchase);
        } catch (error) {
          _setState(PurchaseOperation.error, message: error.toString());
          return;
        }
      }
    }
    _setState(granted ? PurchaseOperation.completed : PurchaseOperation.error);
  }

  void _setState(PurchaseOperation operation, {String? message}) {
    _state.value = PurchaseStoreState(
      operation: operation,
      products: _state.value.products,
      message: message,
    );
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription?.cancel());
    unawaited(_entitlementSnapshots.close());
    _state.dispose();
  }
}
