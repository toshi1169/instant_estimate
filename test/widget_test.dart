import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/app/app.dart';
import 'package:instant_estimate/features/onboarding/data/onboarding_preferences.dart';

class FakeOnboardingPreferences implements OnboardingPreferences {
  FakeOnboardingPreferences({required this.hasSelected});

  bool hasSelected;
  String? savedOccupation;

  @override
  Future<bool> hasSelectedOccupation() async => hasSelected;

  @override
  Future<void> saveOccupation(String occupation) async {
    savedOccupation = occupation;
    hasSelected = true;
  }
}

void main() {
  testWidgets('初回起動では業種選択を表示する', (tester) async {
    final preferences = FakeOnboardingPreferences(hasSelected: false);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    expect(find.text('業種を選択'), findsOneWidget);
    expect(find.text('建築監督'), findsOneWidget);
  });

  testWidgets('選択済みの通常起動では電卓を表示する', (tester) async {
    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historyPanel')), findsOneWidget);
    expect(find.bySemanticsLabel('a/b'), findsOneWidget);
  });

  testWidgets('業種を保存すると電卓へ移動する', (tester) async {
    final preferences = FakeOnboardingPreferences(hasSelected: false);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('土木監督'));
    await tester.pump();
    await tester.tap(find.text('この業種で始める'));
    await tester.pumpAndSettle();

    expect(preferences.savedOccupation, '土木監督');
    expect(find.byKey(const Key('historyPanel')), findsOneWidget);
  });

  testWidgets('電卓ボタンから四則演算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    for (final key in ['1', '2', '+', '3', '=']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }

    expect(find.text('=  15'), findsOneWidget);
    expect(find.byKey(const Key('calculatorCaret')), findsNothing);
  });
}
