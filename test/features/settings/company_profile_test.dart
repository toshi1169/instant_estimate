import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  test('自社情報モデルは全項目と空欄を保存・復元できる', () {
    const profile = CompanyProfile(
      companyName: '山田建設',
      representativeName: '山田太郎',
      postalCode: '100-0001',
      addressLine1: '東京都千代田区千代田1-1',
      addressLine2: '山田ビル2階',
      phoneNumber: '03-1234-5678',
    );

    final restored = CompanyProfile.fromJson(profile.toJson());
    final blank = CompanyProfile.fromJson(const {});

    expect(restored.companyName, profile.companyName);
    expect(restored.representativeName, profile.representativeName);
    expect(restored.postalCode, profile.postalCode);
    expect(restored.addressLine1, profile.addressLine1);
    expect(restored.addressLine2, profile.addressLine2);
    expect(restored.phoneNumber, profile.phoneNumber);
    expect(blank.isEmpty, isTrue);
  });

  test('自社情報ラベルを8言語で明示指定している', () {
    for (final language in AppLanguage.values) {
      final strings = AppLocalizations(language);
      expect(strings.companyProfile, isNotEmpty);
      expect(strings.companyProfileGuidance, isNotEmpty);
      expect(strings.companyNameOrTradeName, isNotEmpty);
      expect(strings.representativeName, isNotEmpty);
      expect(strings.postalCode, isNotEmpty);
      expect(strings.addressLine1, isNotEmpty);
      expect(strings.addressLine2, isNotEmpty);
      expect(strings.phoneNumber, isNotEmpty);
      expect(strings.notRegistered, isNotEmpty);
    }

    expect(
      AppLocalizations(AppLanguage.english).companyProfile,
      'Company information',
    );
    expect(
      AppLocalizations(AppLanguage.traditionalChinese).companyNameOrTradeName,
      '公司名稱／商號',
    );
    expect(AppLocalizations(AppLanguage.myanmar).phoneNumber, 'ဖုန်းနံပါတ်');
  });

  testWidgets('設定画面から自社情報を保存し再表示できる', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settings: settings,
          onSettingsChanged: (value) => settings = value,
          onClearHistory: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final setting = find.byKey(const Key('companyProfileSetting'));
    await tester.scrollUntilVisible(setting, 250);
    await tester.tap(setting);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('companyProfileCompanyName')),
      '山田建設',
    );
    await tester.enterText(
      find.byKey(const Key('companyProfileRepresentativeName')),
      '山田太郎',
    );
    await tester.enterText(
      find.byKey(const Key('companyProfilePostalCode')),
      '100-0001',
    );
    await tester.enterText(
      find.byKey(const Key('companyProfileAddressLine1')),
      '東京都千代田区千代田1-1',
    );
    await tester.enterText(
      find.byKey(const Key('companyProfileAddressLine2')),
      '山田ビル2階',
    );
    await tester.enterText(
      find.byKey(const Key('companyProfilePhoneNumber')),
      '03-1234-5678',
    );
    await tester.tap(find.byKey(const Key('saveCompanyProfile')));
    await tester.pumpAndSettle();

    expect(settings.companyProfile.companyName, '山田建設');
    expect(settings.companyProfile.representativeName, '山田太郎');
    expect(settings.companyProfile.postalCode, '100-0001');
    expect(settings.companyProfile.addressLine1, '東京都千代田区千代田1-1');
    expect(settings.companyProfile.addressLine2, '山田ビル2階');
    expect(settings.companyProfile.phoneNumber, '03-1234-5678');
    expect(find.text('山田建設'), findsOneWidget);

    await tester.tap(find.byKey(const Key('companyProfileSetting')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'companyProfileCompanyName'), '山田建設');
    expect(_fieldText(tester, 'companyProfileRepresentativeName'), '山田太郎');
    expect(_fieldText(tester, 'companyProfilePostalCode'), '100-0001');
    expect(_fieldText(tester, 'companyProfileAddressLine1'), '東京都千代田区千代田1-1');
    expect(_fieldText(tester, 'companyProfileAddressLine2'), '山田ビル2階');
    expect(_fieldText(tester, 'companyProfilePhoneNumber'), '03-1234-5678');
  });

  testWidgets('空欄保存とキャンセルを区別する', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings(
      companyProfile: CompanyProfile(companyName: '既存会社'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settings: settings,
          onSettingsChanged: (value) => settings = value,
          onClearHistory: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('companyProfileSetting')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('companyProfileCompanyName')),
      'キャンセル対象',
    );
    await tester.tap(find.byKey(const Key('cancelCompanyProfile')));
    await tester.pumpAndSettle();
    expect(settings.companyProfile.companyName, '既存会社');

    await tester.tap(find.byKey(const Key('companyProfileSetting')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('companyProfileCompanyName')),
      '',
    );
    await tester.tap(find.byKey(const Key('saveCompanyProfile')));
    await tester.pumpAndSettle();
    expect(settings.companyProfile.isEmpty, isTrue);
  });
}

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
