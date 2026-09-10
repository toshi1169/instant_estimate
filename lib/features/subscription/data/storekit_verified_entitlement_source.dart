import 'package:flutter/services.dart';

typedef VerifiedEntitlementLoader =
    Future<Set<String>> Function({required bool synchronize});

/// Reads only StoreKit 2 transactions that Apple has returned as `.verified`.
class StoreKitVerifiedEntitlementSource {
  static const _channel = MethodChannel(
    'com.matsumotoboundary.constructioncalc/storekit_entitlements',
  );

  Future<Set<String>> load({required bool synchronize}) async {
    final productIds = await _channel.invokeListMethod<String>(
      'loadVerifiedEntitlementProductIds',
      <String, Object>{'synchronize': synchronize},
    );
    return Set.unmodifiable(productIds ?? const <String>[]);
  }
}
