import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/theme/app_colors.dart';

void main() {
  test('iOS release targets iPhone only and keeps the production identity', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(
      RegExp(r'TARGETED_DEVICE_FAMILY = 1;').allMatches(project),
      hasLength(3),
    );
    expect(project, isNot(contains('TARGETED_DEVICE_FAMILY = "1,2";')));
    expect(
      RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = '
        r'com\.matsumotoboundary\.constructioncalc;',
      ).allMatches(project),
      hasLength(3),
    );
  });

  test(
    'iOS remains portrait only without the deprecated full-screen opt-out',
    () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(infoPlist, contains('UIInterfaceOrientationPortrait'));
      expect(infoPlist, isNot(contains('UIInterfaceOrientationLandscape')));
      expect(infoPlist, isNot(contains('UIRequiresFullScreen')));
    },
  );

  test('Launch Screen uses the adaptive background color without an image', () {
    final storyboard = File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsStringSync();
    final colors =
        jsonDecode(
              File(
                'ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final entries = (colors['colors']! as List<Object?>).cast<Map>();
    final lightComponents =
        (entries.first['color']! as Map)['components']! as Map;
    final darkComponents =
        (entries.last['color']! as Map)['components']! as Map;

    expect(storyboard, contains('name="LaunchBackground"'));
    expect(storyboard, isNot(contains('LaunchImage')));
    expect(storyboard, isNot(contains('<imageView')));
    expect(lightComponents['red'], '0.9686274510');
    expect(lightComponents['green'], '0.9725490196');
    expect(lightComponents['blue'], '0.9686274510');
    expect(darkComponents['red'], '0.000');
    expect(darkComponents['green'], '0.000');
    expect(darkComponents['blue'], '0.000');
    expect(entries.last['appearances'], isNotEmpty);
    expect(AppColors.lightBackground, const Color(0xFFF7F8F7));
    expect(AppColors.darkBackground, const Color(0xFF000000));
  });

  test('iPad icon assets remain available for a future release', () {
    const iconRoot = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

    expect(File('$iconRoot/Icon-App-76x76@2x.png').existsSync(), isTrue);
    expect(File('$iconRoot/Icon-App-83.5x83.5@2x.png').existsSync(), isTrue);
  });
}
