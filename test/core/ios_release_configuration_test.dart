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

  test('iOS uses the production AdMob application ID', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('ca-app-pub-5377462997619054~3650317961'));
    expect(
      infoPlist,
      isNot(contains('ca-app-pub-3940256099942544~1458002511')),
    );
  });

  test('iOS declares the complete AdMob SKAdNetwork identifier set', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final identifiers = RegExp(
      r'<string>([a-z0-9]+\.skadnetwork)</string>',
    ).allMatches(infoPlist).map((match) => match.group(1)!).toList();
    const expected = <String>{
      'cstr6suwn9.skadnetwork',
      '4fzdc2evr5.skadnetwork',
      '2fnua5tdw4.skadnetwork',
      'ydx93a7ass.skadnetwork',
      'p78axxw29g.skadnetwork',
      'v72qych5uu.skadnetwork',
      'ludvb6z3bs.skadnetwork',
      'cp8zw746q7.skadnetwork',
      '3sh42y64q3.skadnetwork',
      'c6k4g5qg8m.skadnetwork',
      's39g8k73mm.skadnetwork',
      'wg4vff78zm.skadnetwork',
      '3qy4746246.skadnetwork',
      'f38h382jlk.skadnetwork',
      'hs6bdukanm.skadnetwork',
      'mlmmfzh3r3.skadnetwork',
      'v4nxqhlyqp.skadnetwork',
      'wzmmz9fp6w.skadnetwork',
      'su67r6k2v3.skadnetwork',
      'yclnxrl5pm.skadnetwork',
      't38b2kh725.skadnetwork',
      '7ug5zh24hu.skadnetwork',
      'gta9lk7p23.skadnetwork',
      'vutu7akeur.skadnetwork',
      'y5ghdn5j9k.skadnetwork',
      'v9wttpbfk9.skadnetwork',
      'n38lu8286q.skadnetwork',
      '47vhws6wlr.skadnetwork',
      'kbd757ywx3.skadnetwork',
      '9t245vhmpl.skadnetwork',
      'a2p9lx4jpn.skadnetwork',
      '22mmun2rn5.skadnetwork',
      '44jx6755aq.skadnetwork',
      'k674qkevps.skadnetwork',
      '4468km3ulz.skadnetwork',
      '2u9pt9hc89.skadnetwork',
      '8s468mfl3y.skadnetwork',
      'klf5c3l5u5.skadnetwork',
      'ppxm28t8ap.skadnetwork',
      'kbmxgpxpgc.skadnetwork',
      'uw77j35x4d.skadnetwork',
      '578prtvx9j.skadnetwork',
      '4dzt52r2t5.skadnetwork',
      'tl55sbb4fm.skadnetwork',
      'c3frkrj4fj.skadnetwork',
      'e5fvkxwrpn.skadnetwork',
      '8c4e2ghe7u.skadnetwork',
      '3rd42ekr43.skadnetwork',
      '97r2b46745.skadnetwork',
      '3qcr597p9d.skadnetwork',
    };

    expect(identifiers, hasLength(50));
    expect(identifiers.toSet(), hasLength(50));
    expect(identifiers.toSet(), expected);
  });

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
