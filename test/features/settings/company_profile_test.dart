import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';

void main() {
  test('自社情報モデルは6項目・表示順・Excel表示設定を保存復元できる', () {
    const profile = CompanyProfile(
      companyName: '山田建設',
      representativeName: '山田太郎',
      postalCode: 'SW1A 1AA',
      addressLine1: 'London',
      addressLine2: 'Westminster',
      phoneNumber: '+44 20 0000 0000',
      displayOrder: [
        CompanyProfileSection.postalCode,
        CompanyProfileSection.addressLine1,
        CompanyProfileSection.companyName,
        CompanyProfileSection.representativeName,
        CompanyProfileSection.addressLine2,
        CompanyProfileSection.phoneNumber,
      ],
      excelVisibleSections: [
        CompanyProfileSection.postalCode,
        CompanyProfileSection.addressLine1,
        CompanyProfileSection.companyName,
        CompanyProfileSection.representativeName,
      ],
    );

    final restored = CompanyProfile.fromJson(profile.toJson());
    final blank = CompanyProfile.fromJson(const {});

    expect(restored.companyName, profile.companyName);
    expect(restored.representativeName, profile.representativeName);
    expect(restored.postalCode, profile.postalCode);
    expect(restored.addressLine1, profile.addressLine1);
    expect(restored.addressLine2, profile.addressLine2);
    expect(restored.phoneNumber, profile.phoneNumber);
    expect(restored.effectiveDisplayOrder, profile.displayOrder);
    expect(
      restored.effectiveExcelVisibleSections,
      profile.excelVisibleSections,
    );
    expect(blank.isEmpty, isTrue);
    expect(blank.effectiveDisplayOrder, defaultCompanyProfileDisplayOrder);
    expect(
      blank.effectiveExcelVisibleSections,
      defaultCompanyProfileExcelVisibleSections,
    );
  });

  test('旧JSONの住所ブロックを6項目へ展開し電話番号はExcel非表示にする', () {
    final restored = CompanyProfile.fromJson(const {
      'companyName': '山田建設',
      'addressLine1': '東京都千代田区',
      'displayOrder': ['address', 'companyName', 'representativeName'],
    });

    expect(restored.effectiveDisplayOrder, [
      CompanyProfileSection.postalCode,
      CompanyProfileSection.addressLine1,
      CompanyProfileSection.addressLine2,
      CompanyProfileSection.companyName,
      CompanyProfileSection.representativeName,
      CompanyProfileSection.phoneNumber,
    ]);
    expect(
      restored.effectiveExcelVisibleSections,
      defaultCompanyProfileExcelVisibleSections,
    );
    expect(
      restored.effectiveExcelVisibleSections,
      isNot(contains(CompanyProfileSection.phoneNumber)),
    );
  });

  test('Excel表示対象は不正な旧値を除外し最大5項目へ正規化する', () {
    const profile = CompanyProfile(
      excelVisibleSections: CompanyProfileSection.values,
    );

    expect(profile.effectiveExcelVisibleSections, hasLength(5));
    expect(
      profile.effectiveExcelVisibleSections,
      isNot(contains(CompanyProfileSection.address)),
    );
  });

  test('自社情報設定の追加文言を8言語で明示指定している', () {
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
      expect(strings.companyProfileDisplaySettings, isNotEmpty);
      expect(strings.companyProfileDisplaySettingsGuidance, isNotEmpty);
      expect(strings.showInExcel, isNotEmpty);
      expect(strings.hideFromExcel, isNotEmpty);
      expect(strings.companyProfileExcelDisplayLimit, isNotEmpty);
    }
  });

  testWidgets('通常画面は簡潔で設定モードだけ並べ替えとExcel切替を表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings(
      companyProfile: CompanyProfile(
        companyName: '山田建設',
        representativeName: '山田太郎',
        postalCode: '100-0001',
        addressLine1: '東京都千代田区',
        addressLine2: '山田ビル2階',
        phoneNumber: '03-1234-5678',
      ),
    );

    await _pumpSettings(tester, settings, (value) => settings = value);
    await _openCompanyProfile(tester);

    expect(
      find.byKey(const Key('companyProfileDisplayOrderTitle')),
      findsNothing,
    );
    expect(find.byIcon(Icons.drag_handle), findsNothing);
    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(find.byKey(const Key('companyProfileSettingsMode')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('companyProfileSettingsMode')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.drag_handle), findsWidgets);
    expect(find.byIcon(Icons.visibility), findsWidgets);
    expect(
      find.byKey(const Key('companyProfileSettingsGuidance')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('companyProfileSettingsMode')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_handle), findsNothing);
    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('電話番号は国内外の記号と先頭0をそのまま保存・復元する', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings();
    for (final phoneNumber in const [
      '09012345678',
      '090-1234-5678',
      '03-1234-5678',
      '+81 90-1234-5678',
      '+81 90 1234 5678',
      '(03)1234-5678',
      '+1 (415) 555-0123',
    ]) {
      await _pumpSettings(tester, settings, (value) => settings = value);
      await _openCompanyProfile(tester);
      final phoneField = find.byKey(const Key('companyProfilePhoneNumber'));
      final widget = tester.widget<TextField>(phoneField);
      expect(widget.keyboardType, TextInputType.text);
      expect(widget.inputFormatters, isNotEmpty);

      await tester.enterText(phoneField, phoneNumber);
      await tester.pump();
      expect(
        tester.widget<TextField>(phoneField).controller!.text,
        phoneNumber,
      );
      await tester.tap(find.byKey(const Key('saveCompanyProfile')));
      await tester.pumpAndSettle();
      expect(settings.companyProfile.phoneNumber, phoneNumber);

      await _pumpSettings(tester, settings, (value) => settings = value);
      await _openCompanyProfile(tester);
      expect(
        tester.widget<TextField>(phoneField).controller!.text,
        phoneNumber,
      );
      await tester.tap(find.byKey(const Key('cancelCompanyProfile')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('入力欄を直接並べ替えExcel表示設定とともに保存・復元する', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings(
      companyProfile: CompanyProfile(companyName: '山田建設'),
    );

    await _pumpSettings(tester, settings, (value) => settings = value);
    await _openCompanyProfile(tester);
    await tester.tap(find.byKey(const Key('companyProfileSettingsMode')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('companyProfileFieldHandle-companyName')),
      const Offset(0, 150),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('companyProfileExcelVisibility-representativeName')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveCompanyProfile')));
    await tester.pumpAndSettle();

    expect(
      settings.companyProfile.effectiveDisplayOrder.first,
      isNot(CompanyProfileSection.companyName),
    );
    expect(
      settings.companyProfile.effectiveExcelVisibleSections,
      isNot(contains(CompanyProfileSection.representativeName)),
    );

    settings = AppSettings.fromJson(settings.toJson());
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpSettings(tester, settings, (value) => settings = value);
    await _openCompanyProfile(tester);
    await tester.tap(find.byKey(const Key('companyProfileSettingsMode')));
    await tester.pumpAndSettle();

    expect(
      _fieldTop(tester, settings.companyProfile.effectiveDisplayOrder.first),
      lessThan(_fieldTop(tester, CompanyProfileSection.companyName)),
    );
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(
                const Key('companyProfileExcelVisibility-representativeName'),
              ),
              matching: find.byType(Icon),
            ),
          )
          .icon,
      Icons.visibility_off,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Excel表示は5項目までで郵便番号は国内外形式を自由入力できる', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings();

    await _pumpSettings(tester, settings, (value) => settings = value);
    await _openCompanyProfile(tester);
    await tester.enterText(
      find.byKey(const Key('companyProfilePostalCode')),
      '〒123-4567 SW1A 1AA',
    );
    expect(
      _fieldText(tester, 'companyProfilePostalCode'),
      '〒123-4567 SW1A 1AA',
    );

    await tester.tap(find.byKey(const Key('companyProfileSettingsMode')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('companyProfileEditor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    final phoneVisibility = find
        .byKey(const Key('companyProfileExcelVisibility-phoneNumber'))
        .hitTestable()
        .first;
    await tester.tap(phoneVisibility);
    await tester.pump();
    expect(find.text('Excelに表示できる自社情報は5項目までです'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('companyProfileEditor')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    final companyVisibility = find
        .byKey(const Key('companyProfileExcelVisibility-companyName'))
        .hitTestable()
        .first;
    await tester.tap(companyVisibility);
    await tester.drag(
      find.byKey(const Key('companyProfileEditor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .byKey(const Key('companyProfileExcelVisibility-phoneNumber'))
          .hitTestable()
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveCompanyProfile')));
    await tester.pumpAndSettle();

    expect(settings.companyProfile.postalCode, '〒123-4567 SW1A 1AA');
    expect(settings.companyProfile.effectiveExcelVisibleSections, hasLength(5));
    expect(
      settings.companyProfile.effectiveExcelVisibleSections,
      contains(CompanyProfileSection.phoneNumber),
    );
    expect(
      settings.companyProfile.effectiveExcelVisibleSections,
      isNot(contains(CompanyProfileSection.companyName)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('空欄保存とキャンセルを区別する', (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var settings = const AppSettings(
      companyProfile: CompanyProfile(companyName: '既存会社'),
    );

    await _pumpSettings(tester, settings, (value) => settings = value);
    await _openCompanyProfile(tester);
    await tester.enterText(
      find.byKey(const Key('companyProfileCompanyName')),
      'キャンセル対象',
    );
    await tester.tap(find.byKey(const Key('cancelCompanyProfile')));
    await tester.pumpAndSettle();
    expect(settings.companyProfile.companyName, '既存会社');

    await _openCompanyProfile(tester);
    await tester.enterText(
      find.byKey(const Key('companyProfileCompanyName')),
      '',
    );
    await tester.tap(find.byKey(const Key('saveCompanyProfile')));
    await tester.pumpAndSettle();
    expect(settings.companyProfile.isEmpty, isTrue);
  });
}

Future<void> _pumpSettings(
  WidgetTester tester,
  AppSettings settings,
  ValueChanged<AppSettings> onChanged,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SettingsScreen(
        settings: settings,
        onSettingsChanged: onChanged,
        onClearHistory: () async {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openCompanyProfile(WidgetTester tester) async {
  final setting = find.byKey(const Key('companyProfileSetting'));
  await tester.scrollUntilVisible(setting, 250);
  await tester.tap(setting);
  await tester.pumpAndSettle();
}

double _fieldTop(WidgetTester tester, CompanyProfileSection section) => tester
    .getTopLeft(find.byKey(ValueKey('companyProfileField-${section.name}')))
    .dy;

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).controller!.text;
