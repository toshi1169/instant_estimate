import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/widgets/installed_app_version.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_side_menu.dart';

void main() {
  testWidgets('サイドメニューはパッケージの1.1.1を表示する', (tester) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => {
        'appName': 'Instant Estimate',
        'packageName': 'com.matsumotoboundary.constructioncalc',
        'version': '1.1.1',
        'buildNumber': '15',
        'buildSignature': '',
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalculatorSideMenu(
            onSelected: (_) {},
            showAds: false,
            accessPlan: AppAccessPlan.free,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sideMenuVersion')),
      150,
    );
    expect(find.text('Version 1.1.1'), findsOneWidget);
    expect(find.text('Version 1.1.0'), findsNothing);
  });

  testWidgets('取得中は安全な表示で待ち将来の番号も手動変更なしで表示する', (tester) async {
    final pending = Completer<String>();
    var calls = 0;
    Future<String> load() {
      calls++;
      return pending.future;
    }

    await tester.pumpWidget(
      MaterialApp(home: InstalledAppVersion(loadVersion: load)),
    );
    expect(find.text('Version —'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(home: InstalledAppVersion(loadVersion: load)),
    );
    expect(calls, 1);
    pending.complete('2.3.4');
    await tester.pumpAndSettle();
    expect(find.text('Version 2.3.4'), findsOneWidget);
  });

  for (final failure in ['async', 'sync', 'empty']) {
    testWidgets('取得失敗$failureでも画面エラーにしない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InstalledAppVersion(
            loadVersion: () {
              if (failure == 'sync') throw StateError('unavailable');
              if (failure == 'empty') return Future.value(' ');
              return Future.error(PlatformException(code: 'unavailable'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Version —'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
