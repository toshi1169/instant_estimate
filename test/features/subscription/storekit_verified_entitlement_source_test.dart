import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/subscription/data/storekit_verified_entitlement_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.matsumotoboundary.constructioncalc/storekit_entitlements',
  );

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Store同期指定をnativeへ渡しverified product IDだけを集合で返す', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return <String>[
            'instant_estimate_ad_free',
            'instant_estimate_full_monthly',
            'instant_estimate_full_monthly',
          ];
        });

    final result = await StoreKitVerifiedEntitlementSource().load(
      synchronize: true,
    );

    expect(receivedCall?.method, 'loadVerifiedEntitlementProductIds');
    expect(receivedCall?.arguments, <String, Object>{'synchronize': true});
    expect(result, {
      'instant_estimate_ad_free',
      'instant_estimate_full_monthly',
    });
  });

  test('native取得失敗は空の権利と混同せず例外として返す', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'STOREKIT_ENTITLEMENTS_FAILED');
        });

    expect(
      StoreKitVerifiedEntitlementSource().load(synchronize: false),
      throwsA(isA<PlatformException>()),
    );
  });
}
