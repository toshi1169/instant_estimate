import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/app_access_plan.dart';
import '../domain/purchase_store.dart';

class InAppPurchaseStore implements PurchaseStore {
  InAppPurchaseStore({
    InAppPurchase? inAppPurchase,
    Stream<List<PurchaseDetails>>? purchaseStream,
    Future<void> Function()? restorePurchases,
  }) : _inAppPurchase =
           inAppPurchase ??
           (purchaseStream == null || restorePurchases == null
               ? InAppPurchase.instance
               : null) {
    _purchaseStream = purchaseStream ?? _inAppPurchase!.purchaseStream;
    _restorePurchases = restorePurchases ?? _inAppPurchase!.restorePurchases;
  }

  final InAppPurchase? _inAppPurchase;
  late final Stream<List<PurchaseDetails>> _purchaseStream;
  late final Future<void> Function() _restorePurchases;
  final ValueNotifier<PurchaseStoreState> _state = ValueNotifier(
    const PurchaseStoreState(),
  );
  final StreamController<AppAccessPlan> _entitlementChanges =
      StreamController<AppAccessPlan>.broadcast();
  final StreamController<PurchaseEntitlementSnapshot> _entitlementSnapshots =
      StreamController<PurchaseEntitlementSnapshot>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Map<String, ProductDetails> _productDetails = const {};
  bool _initialized = false;
  Set<AppAccessPlan>? _refreshingPlans;
  Future<PurchaseEntitlementSnapshot>? _refreshingEntitlements;

  @override
  ValueListenable<PurchaseStoreState> get state => _state;

  @override
  Stream<AppAccessPlan> get entitlementChanges => _entitlementChanges.stream;

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
    await refreshEntitlements();
  }

  @override
  Future<PurchaseEntitlementSnapshot> refreshEntitlements() {
    final pending = _refreshingEntitlements;
    if (pending != null) return pending;
    final refresh = _refreshCurrentEntitlements();
    _refreshingEntitlements = refresh;
    return refresh.whenComplete(() => _refreshingEntitlements = null);
  }

  Future<PurchaseEntitlementSnapshot> _refreshCurrentEntitlements() async {
    _ensurePurchaseListener();
    _refreshingPlans = <AppAccessPlan>{};
    PurchaseEntitlementSnapshot snapshot;
    try {
      await _restorePurchases();
      // StoreKit sends restored transactions before completing the restore
      // method call. Yield once so the purchase stream can deliver them.
      await Future<void>.delayed(Duration.zero);
      snapshot = PurchaseEntitlementSnapshot.verified(_refreshingPlans!);
      if (_state.value.operation == PurchaseOperation.restoring) {
        _setState(PurchaseOperation.ready);
      }
    } catch (error) {
      snapshot = PurchaseEntitlementSnapshot.failed(error.toString());
      _setState(PurchaseOperation.error, message: error.toString());
    } finally {
      _refreshingPlans = null;
    }
    _entitlementSnapshots.add(snapshot);
    return snapshot;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    var granted = false;
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // This is the replaceable verification boundary. Before store release,
        // verificationData must be validated by the app's purchase backend.
        final hasVerificationData =
            purchase.verificationData.serverVerificationData.isNotEmpty ||
            purchase.verificationData.localVerificationData.isNotEmpty;
        final plan = PurchaseProductIds.planFor(purchase.productID);
        if (hasVerificationData && plan != null) {
          final refreshingPlans = _refreshingPlans;
          if (refreshingPlans != null) {
            refreshingPlans.add(plan);
          } else {
            _entitlementChanges.add(plan);
          }
          granted = true;
        }
      } else if (purchase.status == PurchaseStatus.error) {
        _setState(PurchaseOperation.error, message: purchase.error?.message);
      } else if (purchase.status == PurchaseStatus.canceled) {
        _setState(PurchaseOperation.ready);
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase!.completePurchase(purchase);
      }
    }
    if (granted) _setState(PurchaseOperation.completed);
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
    unawaited(_entitlementChanges.close());
    unawaited(_entitlementSnapshots.close());
    _state.dispose();
  }
}
