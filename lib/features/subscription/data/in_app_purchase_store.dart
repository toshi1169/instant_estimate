import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/domain/app_access_plan.dart';
import '../domain/purchase_store.dart';

class InAppPurchaseStore implements PurchaseStore {
  InAppPurchaseStore({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;
  final ValueNotifier<PurchaseStoreState> _state = ValueNotifier(
    const PurchaseStoreState(),
  );
  final StreamController<AppAccessPlan> _entitlementChanges =
      StreamController<AppAccessPlan>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Map<String, ProductDetails> _productDetails = const {};
  bool _initialized = false;

  @override
  ValueListenable<PurchaseStoreState> get state => _state;

  @override
  Stream<AppAccessPlan> get entitlementChanges => _entitlementChanges.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _setState(PurchaseOperation.error, message: error.toString());
      },
    );
    _setState(PurchaseOperation.loading);

    try {
      if (!await _inAppPurchase.isAvailable()) {
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
    } catch (error) {
      _setState(PurchaseOperation.error, message: error.toString());
    }
  }

  @override
  Future<void> purchase(AppAccessPlan plan) async {
    final productId = PurchaseProductIds.forPlan(plan);
    final product = productId == null ? null : _productDetails[productId];
    if (product == null) {
      _setState(PurchaseOperation.unavailable);
      return;
    }
    _setState(PurchaseOperation.purchasing);
    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _setState(PurchaseOperation.error);
      }
    } catch (error) {
      _setState(PurchaseOperation.error, message: error.toString());
    }
  }

  @override
  Future<void> restorePurchases() async {
    _setState(PurchaseOperation.restoring);
    try {
      await _inAppPurchase.restorePurchases();
      if (_state.value.operation == PurchaseOperation.restoring) {
        _setState(PurchaseOperation.ready);
      }
    } catch (error) {
      _setState(PurchaseOperation.error, message: error.toString());
    }
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
          _entitlementChanges.add(plan);
          granted = true;
        }
      } else if (purchase.status == PurchaseStatus.error) {
        _setState(PurchaseOperation.error, message: purchase.error?.message);
      } else if (purchase.status == PurchaseStatus.canceled) {
        _setState(PurchaseOperation.ready);
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
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
    _state.dispose();
  }
}
