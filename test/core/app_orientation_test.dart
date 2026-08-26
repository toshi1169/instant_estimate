import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/platform/app_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FlutterはPortraitのみを要求する', () async {
    MethodCall? invocation;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          invocation = call;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    expect(supportedAppOrientations, [DeviceOrientation.portraitUp]);
    await configureAppOrientation();
    expect(invocation?.method, 'SystemChrome.setPreferredOrientations');
    expect(invocation?.arguments, ['DeviceOrientation.portraitUp']);
  });

  test('iOSはiPhoneとiPadでPortraitのみを宣言する', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('UIInterfaceOrientationPortrait'));
    expect(infoPlist, isNot(contains('UIInterfaceOrientationLandscapeLeft')));
    expect(infoPlist, isNot(contains('UIInterfaceOrientationLandscapeRight')));
    expect(
      infoPlist,
      isNot(contains('UIInterfaceOrientationPortraitUpsideDown')),
    );
    expect(infoPlist, contains('<key>UIRequiresFullScreen</key>'));
  });
}
