import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/app/app.dart';
import 'package:instant_estimate/core/domain/app_access_plan.dart';
import 'package:instant_estimate/core/domain/angle_unit.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/core/theme/app_theme.dart';
import 'package:instant_estimate/features/calculator/application/calculator_controller.dart';
import 'package:instant_estimate/features/calculator/presentation/calculator_screen.dart';
import 'package:instant_estimate/features/onboarding/data/onboarding_preferences.dart';
import 'package:instant_estimate/features/settings/data/app_settings_store.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/presentation/settings_screen.dart';
import 'package:instant_estimate/features/subscription/data/app_access_state_store.dart';
import 'package:instant_estimate/features/subscription/domain/app_access_state.dart';
import 'package:instant_estimate/features/estimate/data/estimate_item_store.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_document.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_workspace.dart';
import 'package:instant_estimate/features/estimate/domain/unit_price_master.dart';
import 'package:instant_estimate/features/estimate/application/estimate_controller.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_item_editor_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_items_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_documents_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/unit_price_master_screen.dart';

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

class FakeLanguageOnboardingPreferences
    implements OnboardingPreferences, LanguageOnboardingPreferences {
  FakeLanguageOnboardingPreferences({
    required this.hasSelected,
    required this.hasSelectedLanguageValue,
  });

  bool hasSelected;
  bool hasSelectedLanguageValue;
  String? savedOccupation;
  String? savedLanguage;

  @override
  Future<bool> hasSelectedOccupation() async => hasSelected;

  @override
  Future<void> saveOccupation(String occupation) async {
    savedOccupation = occupation;
    hasSelected = true;
  }

  @override
  Future<bool> hasSelectedLanguage() async => hasSelectedLanguageValue;

  @override
  Future<void> saveLanguage(String language) async {
    savedLanguage = language;
    hasSelectedLanguageValue = true;
  }
}

class FakeAppSettingsStore implements AppSettingsStore {
  FakeAppSettingsStore({this.settings = const AppSettings()});

  AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
  }
}

class FakeAppAccessStateStore implements AppAccessStateStore {
  FakeAppAccessStateStore(this.state);

  AppAccessState state;

  @override
  Future<AppAccessState> load() async => state;

  @override
  Future<void> save(AppAccessState state) async {
    this.state = state;
  }
}

class FakeEstimateItemStore implements EstimateItemStore {
  late EstimateWorkspace workspace;

  FakeEstimateItemStore() {
    final document = EstimateDocument(
      info: EstimateInfo.initial(DateTime(2026, 8, 2)),
      items: const [],
    );
    workspace = EstimateWorkspace(
      activeEstimateId: document.info.id,
      estimates: [document],
    );
  }

  EstimateDocument get document => workspace.estimates.firstWhere(
    (estimate) => estimate.info.id == workspace.activeEstimateId,
  );

  List<EstimateItem> get items => document.items;

  @override
  Future<EstimateWorkspace> load() async => workspace;

  @override
  Future<void> save(EstimateWorkspace workspace) async {
    this.workspace = EstimateWorkspace(
      activeEstimateId: workspace.activeEstimateId,
      estimates: [
        for (final document in workspace.estimates)
          EstimateDocument(info: document.info, items: List.of(document.items)),
      ],
      unitPriceMasters: List.of(workspace.unitPriceMasters),
    );
  }
}

void main() {
  testWidgets('英語設定では単価マスタの組み込み項目と空詳細を英語で表示する', (tester) async {
    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.addUnitPriceMaster(
      const UnitPriceMasterDraft(
        trade: '土工事',
        name: 'Custom excavation',
        unit: '本',
        unitPrice: 4500,
      ),
    );
    await controller.addUnitPriceMaster(
      const UnitPriceMasterDraft(name: 'Blank details'),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        home: UnitPriceMasterScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Earthwork / Unit: pcs'), findsOneWidget);
    expect(find.text('No details'), findsOneWidget);
    expect(find.text('Custom excavation'), findsOneWidget);
  });

  testWidgets('英語設定では見積の初期名称と未分類工種を英語で表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.add(
      const EstimateItemDraft(name: 'Custom item', quantity: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        home: EstimateItemsScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Untitled estimate'), findsOneWidget);
    expect(find.text('Uncategorized'), findsOneWidget);
    expect(find.text('Custom item'), findsOneWidget);
  });

  testWidgets('英語設定の見積一覧では初期名称を英語で表示する', (tester) async {
    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ja'), Locale('en')],
        localizationsDelegates: const [AppLocalizationsDelegate()],
        home: EstimateDocumentsScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Untitled estimate'), findsOneWidget);
  });

  testWidgets('単価マスタを工種・名称・仕様・単位・摘要から検索できる', (tester) async {
    final controller = EstimateController();
    await controller.load();
    await controller.addUnitPriceMaster(
      const UnitPriceMasterDraft(
        trade: '土工事',
        name: '根切り',
        specification: '機械掘削',
        unit: 'm³',
        unitPrice: 4500,
        description: '小運搬別途',
      ),
    );
    await controller.addUnitPriceMaster(
      const UnitPriceMasterDraft(
        trade: '内装工事',
        name: 'クロス貼り',
        specification: '量産品',
        unit: 'm²',
        unitPrice: 1200,
        description: '材料施工共',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: UnitPriceMasterScreen(controller: controller)),
    );

    expect(find.text('根切り'), findsOneWidget);
    expect(find.text('クロス貼り'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('unitPriceMasterSearch')),
      '土工事 小運搬',
    );
    await tester.pump();

    expect(find.text('根切り'), findsOneWidget);
    expect(find.text('クロス貼り'), findsNothing);
    expect(find.text('1 / 2件'), findsOneWidget);
  });

  testWidgets('単価マスタを選ぶと見積明細へ各項目を反映する', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final master = UnitPriceMaster.fromDraft(
      const UnitPriceMasterDraft(
        trade: '土工事',
        name: '根切り',
        specification: '機械掘削',
        unit: 'm³',
        unitPrice: 4500,
        description: '小運搬別途',
      ),
      id: 'price-1',
      createdAt: DateTime(2026, 8, 5),
    );
    final other = UnitPriceMaster.fromDraft(
      const UnitPriceMasterDraft(
        trade: '内装工事',
        name: 'クロス貼り',
        specification: '量産品',
        unit: 'm²',
        unitPrice: 1200,
      ),
      id: 'price-2',
      createdAt: DateTime(2026, 8, 5),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemEditorScreen(
          initialDraft: const EstimateItemDraft(quantity: 2),
          unitPriceMasters: [master, other],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('selectUnitPriceMaster')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('selectUnitPriceMasterSearch')),
      '機械掘削',
    );
    await tester.pump();
    expect(find.text('クロス貼り'), findsNothing);
    await tester.tap(find.byKey(const Key('selectUnitPrice-price-1')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('estimateTradeField')))
          .controller
          ?.text,
      '土工事',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('estimateNameField')))
          .controller
          ?.text,
      '根切り',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('estimateSpecificationField')),
          )
          .controller
          ?.text,
      '機械掘削',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('estimateUnitField')))
          .controller
          ?.text,
      'm³',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('estimateUnitPriceField')),
          )
          .controller
          ?.text,
      '4500',
    );
    expect(find.text('¥ 9,000'), findsOneWidget);
  });

  testWidgets('過去の見積を検索して明細と単価を呼び出せる', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pastEstimate = EstimateDocument(
      info: EstimateInfo.initial(
        DateTime(2026, 8, 1),
      ).copyWith(estimateName: '○○邸 外構工事', siteName: '○○邸'),
      items: [
        EstimateItem.fromDraft(
          const EstimateItemDraft(
            trade: '外構工事',
            name: '化粧ブロック積み',
            specification: 'スマートC120',
            quantity: 10,
            unit: '本',
            unitPrice: 1350,
            description: '色：ダークグレー',
          ),
          id: 'past-1',
          createdAt: DateTime(2026, 8, 1),
        ),
      ],
    );
    final otherEstimate = EstimateDocument(
      info: EstimateInfo.initial(
        DateTime(2026, 7, 1),
      ).copyWith(estimateName: '△△工事'),
      items: [
        EstimateItem.fromDraft(
          const EstimateItemDraft(
            trade: '内装工事',
            name: 'クロス貼り',
            quantity: 20,
            unit: 'm²',
            unitPrice: 1200,
          ),
          id: 'past-2',
          createdAt: DateTime(2026, 7, 1),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EstimateItemEditorScreen(
          initialDraft: const EstimateItemDraft(quantity: 2),
          estimates: [pastEstimate, otherEstimate],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('selectPastUnitPrice')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('selectPastUnitPriceSearch')),
      '○○邸 ダーク',
    );
    await tester.pump();
    expect(find.text('クロス貼り'), findsNothing);
    await tester.tap(
      find.byKey(Key('selectPastUnitPrice-${pastEstimate.info.id}-past-1')),
    );
    await tester.pumpAndSettle();

    String fieldText(String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
    expect(fieldText('estimateTradeField'), '外構工事');
    expect(fieldText('estimateNameField'), '化粧ブロック積み');
    expect(fieldText('estimateSpecificationField'), 'スマートC120');
    expect(fieldText('estimateQuantityField'), '2');
    expect(fieldText('estimateUnitField'), '本');
    expect(fieldText('estimateUnitPriceField'), '1350');
    expect(
      tester.widget<Text>(find.byKey(const Key('estimateAmountValue'))).data,
      '¥ 2,700',
    );
    expect(fieldText('estimateDescriptionField'), '色：ダークグレー');
  });

  testWidgets('白・グレーテーマのイコールは白文字で表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    expect(
      AppTheme.gray.scaffoldBackgroundColor,
      const Color.fromRGBO(180, 180, 180, 1),
    );

    for (final theme in [AppTheme.light, AppTheme.gray]) {
      await tester.pumpWidget(
        MaterialApp(theme: theme, home: const CalculatorScreen()),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('calculatorKey=')),
      );
      expect(button.style?.foregroundColor?.resolve({}), Colors.white);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('保存済みテーマを復元し設定画面から変更できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsStore = FakeAppSettingsStore(
      settings: const AppSettings(theme: AppThemeSelection.dark),
    );
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('テーマ'), findsOneWidget);
    expect(find.text('黒'), findsOneWidget);

    await tester.tap(find.byKey(const Key('themeSetting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('白'));
    await tester.pumpAndSettle();

    expect(settingsStore.settings.theme, AppThemeSelection.light);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    await tester.tap(find.byKey(const Key('angleUnitSetting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ラジアン（RAD）'));
    await tester.pumpAndSettle();
    expect(settingsStore.settings.angleUnit, AngleUnit.radians);
  });

  testWidgets('必要な場合は設定画面から広告プライバシー設定を開ける', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja'), Locale('en')],
        home: SettingsScreen(
          settings: const AppSettings(),
          onSettingsChanged: (_) {},
          onClearHistory: () async {},
          onShowAdvertisingPrivacyOptions: () async => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final privacySetting = find.byKey(
      const Key('advertisingPrivacyOptionsSetting'),
    );
    await tester.scrollUntilVisible(privacySetting, 250);
    expect(find.text('広告のプライバシー設定'), findsOneWidget);

    await tester.tap(privacySetting);
    await tester.pumpAndSettle();
    expect(opened, isTrue);
  });

  testWidgets('初回起動では業種選択を表示する', (tester) async {
    final preferences = FakeOnboardingPreferences(hasSelected: false);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    expect(find.text('業種を選択'), findsOneWidget);
    expect(find.text('建築監督'), findsOneWidget);
  });

  testWidgets('新規利用者は言語選択後に選択言語の業種画面へ進む', (tester) async {
    final preferences = FakeLanguageOnboardingPreferences(
      hasSelected: false,
      hasSelectedLanguageValue: false,
    );
    final settingsStore = FakeAppSettingsStore();
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: preferences,
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('言語を選択'), findsOneWidget);
    await tester.tap(find.byKey(const Key('languageEnglish')));
    await tester.tap(find.byKey(const Key('completeLanguageSelection')));
    await tester.pumpAndSettle();

    expect(preferences.savedLanguage, AppLanguage.english.name);
    expect(settingsStore.settings.language, AppLanguage.english);
    expect(find.text('Choose occupation'), findsOneWidget);

    await tester.tap(find.text('Civil supervisor'));
    await tester.pump();
    await tester.tap(find.text('Start with this occupation'));
    await tester.pumpAndSettle();

    expect(preferences.savedOccupation, '土木監督');
    expect(find.byKey(const Key('historyPanel')), findsOneWidget);
  });

  testWidgets('新規利用者は簡体字中国語を選択して保存できる', (tester) async {
    final preferences = FakeLanguageOnboardingPreferences(
      hasSelected: false,
      hasSelectedLanguageValue: false,
    );
    final settingsStore = FakeAppSettingsStore();
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: preferences,
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('languageSimplifiedChinese')));
    await tester.tap(find.byKey(const Key('completeLanguageSelection')));
    await tester.pumpAndSettle();

    expect(preferences.savedLanguage, AppLanguage.simplifiedChinese.name);
    expect(settingsStore.settings.language, AppLanguage.simplifiedChinese);
    expect(find.text('选择行业'), findsOneWidget);
    expect(find.text('土木监理'), findsOneWidget);
  });

  testWidgets('新規利用者は繁体字中国語を選択して保存できる', (tester) async {
    final preferences = FakeLanguageOnboardingPreferences(
      hasSelected: false,
      hasSelectedLanguageValue: false,
    );
    final settingsStore = FakeAppSettingsStore();
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: preferences,
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('languageTraditionalChinese')));
    await tester.tap(find.byKey(const Key('completeLanguageSelection')));
    await tester.pumpAndSettle();

    expect(preferences.savedLanguage, AppLanguage.traditionalChinese.name);
    expect(settingsStore.settings.language, AppLanguage.traditionalChinese);
    expect(find.text('選擇行業'), findsOneWidget);
    expect(find.text('土木監督'), findsOneWidget);
  });

  testWidgets('設定から英語へ変更し日本語とローマ字の技術用語解説を表示できる', (tester) async {
    final settingsStore = FakeAppSettingsStore();
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('languageSetting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(settingsStore.settings.language, AppLanguage.english);
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('歩掛：BUGAKARI'), findsOneWidget);

    await tester.tap(find.byKey(const Key('technicalTermInfo-歩掛：BUGAKARI')));
    await tester.pumpAndSettle();
    expect(find.text('歩掛：BUGAKARI'), findsWidgets);
    expect(find.textContaining('Japanese construction term'), findsOneWidget);
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

  testWidgets('メニューボタンからサイドメニューを開き設定へ移動できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculatorSideMenu')), findsOneWidget);
    expect(find.byIcon(Icons.calculate_outlined), findsNothing);
    expect(find.text('ヘルプ'), findsOneWidget);
    expect(find.text('広告なし版（買い切り）'), findsOneWidget);
    expect(find.text('完全版（月額）'), findsOneWidget);
    expect(find.byKey(const Key('sideMenuAdFreeStatus')), findsOneWidget);
    expect(find.byKey(const Key('sideMenuFullStatus')), findsOneWidget);
    expect(find.text('未購入'), findsOneWidget);
    expect(find.text('未契約'), findsOneWidget);
    expect(find.text('便利計算一覧'), findsOneWidget);
    expect(find.text('単位変換'), findsOneWidget);
    expect(find.text('インスタント見積'), findsWidgets);
    expect(find.text('単価マスタ'), findsOneWidget);
    expect(find.text('歩掛・生産性マスタ'), findsOneWidget);
    expect(find.byKey(const Key('sideMenuAdArea')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sideMenuSettings')));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('テーマ'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculatorSideMenu')), findsOneWidget);
    expect(find.text('便利計算一覧'), findsOneWidget);
  });

  testWidgets('左メニューから広告なし版と完全版の内容を確認できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sideMenuAdFree')));
    await tester.pumpAndSettle();
    expect(find.text('¥300（買い切り）'), findsOneWidget);
    expect(find.text('見積は5件まで保存'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sideMenuFull')));
    await tester.pumpAndSettle();
    expect(find.text('¥500／月'), findsOneWidget);
    expect(find.text('初回のみ7日間無料体験'), findsOneWidget);
    expect(find.text('見積の保存件数を無制限に拡張'), findsOneWidget);
  });

  testWidgets('広告なし版では電卓上部と左メニューの広告枠を表示しない', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        accessPlan: AppAccessPlan.adFree,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculatorAdBanner')), findsNothing);

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sideMenuAdArea')), findsNothing);
    expect(find.text('広告なし版（買い切り）'), findsOneWidget);
    expect(find.text('購入済み'), findsOneWidget);
    expect(find.text('未契約'), findsOneWidget);
  });

  testWidgets('完全版では左メニューと設定に契約状況を区別して表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        accessPlan: AppAccessPlan.full,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('完全版特典で有効'), findsOneWidget);
    expect(find.text('契約中'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sideMenuSettings')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('purchaseStatusAdFree')),
      250,
    );

    expect(find.text('購入状況'), findsOneWidget);
    expect(find.byKey(const Key('purchaseStatusAdFree')), findsOneWidget);
    expect(find.byKey(const Key('purchaseStatusFull')), findsOneWidget);
    expect(find.text('完全版特典で有効'), findsOneWidget);
    expect(find.text('契約中'), findsOneWidget);
  });

  testWidgets('端末に保存した広告なし版を起動時に復元する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        accessStateStore: FakeAppAccessStateStore(
          const AppAccessState(plan: AppAccessPlan.adFree),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculatorAdBanner')), findsNothing);
    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sideMenuAdArea')), findsNothing);
  });

  testWidgets('無料版の上部広告から広告なし版の案内を開ける', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculatorAdBanner')), findsOneWidget);
    await tester.tap(find.text('今すぐ\nアップグレード'));
    await tester.pumpAndSettle();

    expect(find.text('広告なし版'), findsWidgets);
    expect(find.text('¥300（買い切り）'), findsOneWidget);
  });

  testWidgets('左メニューから単位変換を開き換算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sideMenuUnitConversion')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unitConversionScreen')), findsOneWidget);
    expect(find.text('単位変換'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('unitConversionValue')),
      '1000',
    );
    await tester.pumpAndSettle();

    expect(find.text('100.00 cm'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calculatorSideMenu')), findsOneWidget);
  });

  testWidgets('英語の単位変換で日本固有単位の説明を開ける', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsStore = FakeAppSettingsStore(
      settings: const AppSettings(language: AppLanguage.english),
    );
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sideMenuUnitConversion')));
    await tester.pumpAndSettle();

    expect(find.text('Unit conversion'), findsOneWidget);
    expect(find.textContaining('SHAKU, SUN and KEN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unitConversionFrom')));
    await tester.pumpAndSettle();
    expect(find.text('尺：SHAKU'), findsOneWidget);
    await tester.tap(find.byKey(const Key('unitInfo-shaku')));
    await tester.pumpAndSettle();

    expect(find.text('尺：SHAKU'), findsWidgets);
    expect(
      find.textContaining('traditional Japanese unit of length'),
      findsOneWidget,
    );
  });

  test('日本固有単位の英語説明をすべて用意する', () {
    const strings = AppLocalizations(AppLanguage.english);
    for (final id in const [
      'shaku',
      'sun',
      'ken',
      'tsubo',
      'hyo',
      'natural',
      'loose',
      'compacted',
    ]) {
      expect(strings.isSpecializedUnit(id), isTrue);
      expect(strings.specializedUnitExplanation(id), isNotEmpty);
    }
  });

  test('簡体字中国語は主要画面と専門計算の文言を翻訳する', () {
    const strings = AppLocalizations(AppLanguage.simplifiedChinese);

    expect(strings.chooseLanguage, '选择语言');
    expect(strings.settings, '设置');
    expect(strings.instantEstimate, '即时估算');
    expect(strings.text('土量計算'), '土方计算');
    expect(strings.calculationHistory, '计算历史');
    expect(strings.text('計算式・解を検索'), '搜索算式和结果');
    expect(strings.text('新しい見積'), '新建估算');
    expect(strings.text('税抜合計'), '未税合计');
    expect(strings.text('材料と体積から重量を算出'), '根据材料和体积计算重量');
    expect(strings.text('4辺面積計算'), '四边形面积计算');
    expect(strings.text('必要人工'), '所需人工');
    expect(strings.text('変換する種類'), '换算类别');
    expect(strings.text('土量変換'), '土方状态换算');
    expect(strings.text('掘削後のほぐし土量と運搬回数を算出します。'), '计算开挖后的松散土方和运输次数。');
    expect(strings.text('運搬車両'), '运输车辆');
    expect(strings.text('必要運搬回数'), '所需运输次数');
    expect(strings.text('履歴をコピーしました'), '已复制历史记录');
    expect(strings.text('0で割ることはできません'), '不能除以0');
    expect(strings.text('法長は高さより大きい数値を入力してください'), '请输入大于高度的边坡长度');
    expect(strings.specializedUnit('ken', '間'), '間：KEN');
    expect(strings.unitInformation, '单位说明');
    expect(strings.showUnitInformation, '显示单位说明');
    expect(strings.specializedUnitExplanation('ken'), contains('日本传统长度单位'));
    expect(strings.printA4Landscape, '以A4横向打印');
    expect(strings.copiedEstimateDetails(3), '已复制估算明细（3项）');
    expect(strings.deleteUnitPriceQuestion('挖掘'), '要从单价主数据中删除“挖掘”吗？');
  });

  test('繁体字中国語は便利計算・土量・比重の文言を翻訳する', () {
    const strings = AppLocalizations(AppLanguage.traditionalChinese);

    expect(strings.text('土量計算'), '土方計算');
    expect(strings.text('掘削・搬出'), '開挖・外運');
    expect(strings.text('材料と体積から重量を算出'), '根據材料和體積計算重量');
    expect(strings.text('材料を追加'), '新增材料');
    expect(strings.text('運搬車両'), '運輸車輛');
    expect(strings.text('必要運搬回数'), '所需運輸次數');
    expect(strings.text('締固め係数'), '壓實係數');
  });

  testWidgets('ヘルプを開き戻るとサイドメニューへ戻る', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sideMenuHelp')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('helpScreen')), findsOneWidget);
    expect(find.text('電卓の基本操作'), findsOneWidget);
    expect(find.text('インスタント見積'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calculatorSideMenu')), findsOneWidget);
    expect(find.text('便利計算一覧'), findsOneWidget);
  });

  testWidgets('メニューボタンの長押しで3列9行の関数一覧を開ける', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('functionListDialog')), findsOneWidget);
    expect(find.byKey(const Key('functionListGrid')), findsOneWidget);
    expect(find.byKey(const Key('functionButton0')), findsOneWidget);
    expect(find.byKey(const Key('functionButton26')), findsOneWidget);
    expect(find.text('π'), findsOneWidget);
    expect(find.text('sinh⁻¹'), findsOneWidget);
    expect(find.text('x!'), findsOneWidget);
    expect(find.byKey(const Key('functionAngleUnitSetting')), findsOneWidget);
    expect(find.text('DEG（度）'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancelFunctionList')));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('functionListDialog')), findsOneWidget);
  });

  testWidgets('英語設定で関数一覧と計算エラーを英語表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: FakeAppSettingsStore(
          settings: const AppSettings(language: AppLanguage.english),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('Functions'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancelFunctionList')));
    await tester.pumpAndSettle();
    for (final key in ['1', '÷', '0', '=']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }

    expect(find.text('Cannot divide by zero'), findsOneWidget);
  });

  testWidgets('関数一覧から角度単位を変更して保存できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsStore = FakeAppSettingsStore();
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('functionAngleUnitDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RAD（ラジアン）').last);
    await tester.pumpAndSettle();

    expect(settingsStore.settings.angleUnit, AngleUnit.radians);
    expect(find.text('RAD（ラジアン）'), findsOneWidget);
    expect(find.byKey(const Key('functionListDialog')), findsOneWidget);
  });

  testWidgets('関数一覧から平方根を選んで計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('√'));
    await tester.pumpAndSettle();

    for (final key in ['9', '=']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }

    expect(find.text('=  3'), findsOneWidget);
  });

  testWidgets('関数一覧の逆数を横棒付き分数として計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.bySemanticsLabel('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1/x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.pump();

    expect(find.text('=  0.25'), findsOneWidget);
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

  testWidgets('計算スペースの長押しで編集メニューを表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('calculationSpace')));
    await tester.pumpAndSettle();

    expect(find.text('コピー'), findsOneWidget);
    expect(find.text('カット'), findsOneWidget);
    expect(find.text('ペースト'), findsOneWidget);
    expect(find.text('消去'), findsOneWidget);
    expect(find.text('見積へ送る'), findsOneWidget);
  });

  testWidgets('英語設定で電卓広告と計算スペースメニューを英語表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: FakeAppSettingsStore(
          settings: const AppSettings(language: AppLanguage.english),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ad space'), findsOneWidget);
    expect(find.text('Remove ads with Ad-free!'), findsOneWidget);
    expect(find.text('Upgrade\nnow'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('calculationSpace')));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Send to estimate'), findsOneWidget);
  });

  testWidgets('a/bボタンから分数枠を入力して計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('a/b'));
    await tester.pump();
    expect(find.text('□'), findsNWidgets(2));

    for (final key in ['1', 'a/b', '2', 'a/b', '=']) {
      final finder = key == 'a/b'
          ? find.bySemanticsLabel('a/b')
          : find.text(key);
      await tester.tap(finder);
      await tester.pump();
    }

    expect(find.text('=  0.5'), findsOneWidget);
  });

  testWidgets('10桁分数は入力中と右側キャレットでエラーを出さない', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('a/b'));
    for (final key in '1234567890'.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, key));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('a/b'));
    for (final key in '0987654321'.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, key));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('a/b'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('calculatorCaret')), findsOneWidget);
    expect(find.byKey(const Key('expressionTrailingTapArea')), findsNothing);
  });

  testWidgets('複数の10桁分数を含む長い式は全体を縮小して表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    const keys = [
      'a/b',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      '1',
      'a/b',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      '2',
      'a/b',
      '×',
      'a/b',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      '3',
      'a/b',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      '4',
      'a/b',
    ];
    for (final key in keys) {
      final finder = key == 'a/b'
          ? find.bySemanticsLabel('a/b')
          : find.widgetWithText(FilledButton, key);
      await tester.tap(finder);
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('分数の11桁目では2秒間入力上限を通知する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final preferences = FakeOnboardingPreferences(hasSelected: true);
    await tester.pumpWidget(
      InstantEstimateApp(onboardingPreferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('a/b'));
    for (var index = 0; index < 11; index++) {
      await tester.tap(find.widgetWithText(FilledButton, '1'));
      await tester.pump();
    }

    expect(find.text('これ以上入力できません'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('これ以上入力できません'), findsNothing);
  });

  testWidgets('帯分数の各欄と左右へキャレットを移動できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    for (final key in ['2', '0', 'a/b', '1', '2', 'a/b', '3', '4']) {
      controller.press(key);
    }
    final fraction = controller.displaySegments
        .whereType<ExpressionFractionSegment>()
        .single;

    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    for (final field in FractionField.values) {
      controller.activateFraction(fraction.marker, field, caretOffset: 1);
      await tester.pump();
      expect(find.byKey(const Key('fractionFieldCaret')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('fractionAfterTapArea')));
    await tester.pump();
    expect(controller.isEditingFraction, isFalse);
    expect(find.byKey(const Key('calculatorCaret')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fractionBeforeTapArea')));
    await tester.pump();
    expect(controller.caretPosition, 0);
  });

  testWidgets('長い式でも分数前後の数字と演算子へキャレットを移動できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('66×55×');
    for (final key in ['a/b', '1', 'a/b', '1', 'a/b']) {
      controller.press(key);
    }
    controller.pasteAtCaret('×222×3333');

    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    Future<void> tapCharacter(
      String containedText,
      int offsetWithinContainedText,
    ) async {
      final finder = find.textContaining(containedText);
      final text = tester.widget<Text>(finder).data!;
      final characterIndex =
          text.indexOf(containedText) + offsetWithinContainedText;
      final rect = tester.getRect(finder);
      final painter = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(fontSize: 42)),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = painter.getOffsetForCaret(
        TextPosition(offset: characterIndex),
        Rect.zero,
      );
      final right = painter.getOffsetForCaret(
        TextPosition(offset: characterIndex + 1),
        Rect.zero,
      );
      final localCenter = (left.dx + right.dx) / 2;
      await tester.tapAt(
        Offset(
          rect.left + localCenter * rect.width / painter.width,
          rect.center.dy,
        ),
      );
      await tester.pump();
    }

    await tapCharacter('66', 0);
    expect(controller.caretPosition, anyOf(0, 1));

    await tapCharacter('222', -2);
    expect(controller.caretPosition, anyOf(7, 8));
    await tapCharacter('222', 1);
    expect(controller.caretPosition, anyOf(9, 10));
    await tapCharacter('3333', 1);
    expect(controller.caretPosition, anyOf(13, 14));
  });

  testWidgets('計算結果を横棒付きの仮分数と帯分数へ切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('2−1÷2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    controller.press('=');
    await tester.pump();
    expect(controller.resultDisplayMode, ResultDisplayMode.improperFraction);
    expect(find.byKey(const Key('resultText')), findsOneWidget);

    controller.press('a/b');
    await tester.pump();
    expect(controller.resultDisplayMode, ResultDisplayMode.mixedFraction);
    expect(find.byKey(const Key('resultText')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('履歴の縦3点からコピー・編集・削除を選べる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();

    expect(find.text('コピー'), findsOneWidget);
    expect(find.text('共有'), findsOneWidget);
    expect(find.text('編集'), findsOneWidget);
    expect(find.text('削除'), findsOneWidget);
    expect(find.text('スター'), findsOneWidget);
    expect(find.text('見積へ送る'), findsOneWidget);
  });

  testWidgets('英語設定で履歴メニューを英語表示する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsStore = FakeAppSettingsStore(
      settings: const AppSettings(language: AppLanguage.english),
    );
    await tester.pumpWidget(
      InstantEstimateApp(
        onboardingPreferences: FakeOnboardingPreferences(hasSelected: true),
        appSettingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    for (final key in ['1', '+', '2', '=']) {
      await tester.tap(find.text(key));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Star'), findsOneWidget);
    expect(find.text('Send to estimate'), findsOneWidget);
  });

  testWidgets('無料版の履歴スターでは利用制限を案内する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スター'));
    await tester.pumpAndSettle();

    expect(find.text('スターはアルティメット版で利用できます'), findsOneWidget);
  });

  testWidgets('履歴から見積へ送る共通画面を開ける', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();

    expect(find.text('送信内容'), findsOneWidget);
    final preview = tester.widget<Text>(
      find.byKey(const Key('estimateTransferPreview')),
    );
    expect(preview.data, '1 + 2 = 3');
  });

  testWidgets('電卓の解を見積数量へ送り単価から金額を計算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('12×2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimateItemEditor')), findsOneWidget);
    expect(find.text('名称未設定の見積'), findsOneWidget);
    final quantity = tester.widget<TextFormField>(
      find.byKey(const Key('estimateQuantityField')),
    );
    expect(quantity.controller?.text, '24');

    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '100',
    );
    await tester.pump();
    expect(find.text('¥ 2,400'), findsOneWidget);
  });

  testWidgets('電卓の見積数量へ小数桁と丸め設定を反映する', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1÷3');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: controller,
          settings: const AppSettings(
            decimalPlaces: 2,
            roundingMode: CalculatorRoundingMode.floor,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    final quantity = tester.widget<TextFormField>(
      find.byKey(const Key('estimateQuantityField')),
    );
    expect(quantity.controller?.text, '0.33');
  });

  testWidgets('見積明細を保存して一覧と合計を表示できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estimateStore = FakeEstimateItemStore();
    final controller = CalculatorController();
    controller.pasteAtCaret('12×2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: controller,
          estimateItemStore: estimateStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('estimateNameField')), '試験明細');
    await tester.enterText(find.byKey(const Key('estimateUnitField')), 'm²');
    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '100',
    );
    await tester.ensureVisible(find.byKey(const Key('addEstimateAndOpen')));
    await tester.tap(find.byKey(const Key('addEstimateAndOpen')));
    await tester.pumpAndSettle();

    expect(estimateStore.items, hasLength(1));
    expect(find.byKey(const Key('estimateItemsList')), findsOneWidget);
    expect(find.text('試験明細'), findsOneWidget);
    expect(find.text('24 m²'), findsOneWidget);
    expect(find.text('税抜合計  ¥ 2,400'), findsOneWidget);
    expect(find.text('消費税（10%）  ¥ 240'), findsOneWidget);
    expect(find.text('税込総額  ¥ 2,640'), findsOneWidget);
  });

  testWidgets('電卓から追加した直後の見積明細を取り消せる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estimateStore = FakeEstimateItemStore();
    final calculator = CalculatorController();
    calculator.pasteAtCaret('12×2');
    calculator.press('=');
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: calculator,
          estimateItemStore: estimateStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('estimateNameField')), '取消確認');
    await tester.drag(
      find.byKey(const Key('estimateItemEditor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addEstimateAndContinue')));
    await tester.pumpAndSettle();

    expect(estimateStore.items, hasLength(1));
    expect(find.byKey(const Key('openAddedEstimate')), findsOneWidget);
    expect(find.byKey(const Key('undoEstimateItemAdd')), findsOneWidget);

    await tester.tap(find.byKey(const Key('undoEstimateItemAdd')));
    await tester.pumpAndSettle();

    expect(estimateStore.items, isEmpty);
    expect(find.text('直前の追加を取り消しました'), findsOneWidget);
  });

  testWidgets('電卓から同じ計算内容を送ると既存明細を更新できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estimateStore = FakeEstimateItemStore();
    final calculator = CalculatorController();
    calculator.pasteAtCaret('12×2');
    calculator.press('=');
    final estimateController = EstimateController(store: estimateStore);
    await estimateController.load();
    await estimateController.add(
      EstimateItemDraft(
        name: '更新前',
        quantity: calculator.estimateQuantityValue,
        calculationBasis:
            '${calculator.estimateExpressionText} = ${calculator.estimateResultText}',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: calculator,
          estimateItemStore: estimateStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('estimateNameField')), '更新後');
    await tester.drag(
      find.byKey(const Key('estimateItemEditor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addEstimateAndContinue')));
    await tester.pumpAndSettle();

    expect(find.text('同じ計算内容があります'), findsOneWidget);
    expect(find.textContaining('更新前'), findsOneWidget);
    await tester.tap(find.byKey(const Key('updateDuplicateEstimateItem')));
    await tester.pumpAndSettle();

    expect(estimateStore.items, hasLength(1));
    expect(estimateStore.items.single.name, '更新後');
    expect(find.text('既存の見積明細を更新しました'), findsOneWidget);
  });

  testWidgets('電卓から送った数量を同じ名称・単位・単価の既存明細へ加算できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final estimateStore = FakeEstimateItemStore();
    final initialController = EstimateController(store: estimateStore);
    await initialController.load();
    await initialController.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 7.2,
        unit: 'm³',
        unitPrice: 4500,
        calculationBasis: '既存の計算根拠',
      ),
    );
    final calculator = CalculatorController();
    calculator.pasteAtCaret('12×2');
    calculator.press('=');
    await tester.pumpWidget(
      MaterialApp(
        home: CalculatorScreen(
          controller: calculator,
          estimateItemStore: estimateStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('historyMenuButton0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('見積へ送る'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDestinationSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数量').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateTransferNext')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('estimateNameField')), '根切り');
    await tester.enterText(find.byKey(const Key('estimateUnitField')), 'm³');
    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '4500',
    );
    await tester.drag(
      find.byKey(const Key('estimateItemEditor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addEstimateAndContinue')));
    await tester.pumpAndSettle();

    expect(find.text('既存明細へ数量を加算'), findsOneWidget);
    expect(find.textContaining('既存：7.2 m³'), findsOneWidget);
    expect(find.textContaining('今回：24 m³'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mergeEstimateQuantities')));
    await tester.pumpAndSettle();

    expect(estimateStore.items, hasLength(1));
    expect(estimateStore.items.single.quantity, closeTo(31.2, 0.000001));
    expect(estimateStore.items.single.calculationBasis, contains('既存の計算根拠'));
    expect(
      estimateStore.items.single.calculationBasis,
      contains(calculator.estimateExpressionText),
    );
    expect(find.text('既存明細の数量を31.2へ加算しました'), findsOneWidget);
  });

  testWidgets('見積明細を編集・削除して合計と端末保存を更新できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final estimateController = EstimateController(store: store);
    await estimateController.load();
    await estimateController.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2,
        unit: 'm³',
        unitPrice: 4000,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: estimateController)),
    );
    await tester.pumpAndSettle();

    expect(find.text('土工事'), findsOneWidget);
    expect(find.byKey(const Key('estimateGroupSubtotal0')), findsOneWidget);
    expect(find.text('¥ 8,000'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('estimateItemMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '5000',
    );
    await tester.ensureVisible(find.byKey(const Key('estimateTradeField')));
    await tester.enterText(find.byKey(const Key('estimateTradeField')), '型枠工事');
    await tester.ensureVisible(find.byKey(const Key('saveEstimateChanges')));
    await tester.tap(find.byKey(const Key('saveEstimateChanges')));
    await tester.pumpAndSettle();

    expect(find.text('税抜合計  ¥ 10,000'), findsOneWidget);
    expect(find.text('税込総額  ¥ 11,000'), findsOneWidget);
    expect(find.text('型枠工事'), findsOneWidget);
    expect(find.text('土工事'), findsNothing);
    expect(find.text('¥ 10,000'), findsNWidgets(2));
    expect(store.items.single.unitPrice, 5000);

    await tester.tap(find.byKey(const Key('estimateItemMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.text('「根切り」を削除しますか？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '削除'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emptyEstimateItems')), findsOneWidget);
    expect(find.text('税抜合計  ¥ 0'), findsOneWidget);
    expect(find.text('消費税（10%）  ¥ 0'), findsOneWidget);
    expect(find.text('税込総額  ¥ 0'), findsOneWidget);
    expect(store.items, isEmpty);
  });

  testWidgets('見積明細を工種ごとに表示して工種小計と見積合計を確認できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = EstimateController();
    await controller.load();
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2,
        unitPrice: 4000,
      ),
    );
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '埋戻し',
        quantity: 1,
        unitPrice: 3000,
      ),
    );
    await controller.add(
      const EstimateItemDraft(name: '諸経費', quantity: 1, unitPrice: 500),
    );

    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('土工事'), findsOneWidget);
    expect(find.text('工種未設定'), findsOneWidget);
    expect(find.byKey(const Key('estimateGroup0')), findsOneWidget);
    expect(find.byKey(const Key('estimateGroup1')), findsOneWidget);
    expect(find.text('工種小計'), findsNWidgets(2));
    expect(find.text('¥ 11,000'), findsOneWidget);
    expect(find.text('¥ 500'), findsNWidgets(2));
    expect(find.text('税抜合計  ¥ 11,500'), findsOneWidget);
    expect(find.text('消費税（10%）  ¥ 1,150'), findsOneWidget);
    expect(find.text('税込総額  ¥ 12,650'), findsOneWidget);
  });

  testWidgets('見積明細をExcel貼り付け用の表としてコピーできる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final controller = EstimateController();
    await controller.load();
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2,
        unit: 'm³',
        unitPrice: 4000,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('copyEstimateTable')));
    await tester.pumpAndSettle();

    expect(copiedText, contains('記号\t名称\t仕様\t数量\t単位\t単価\t金額\t摘要'));
    expect(copiedText, contains('①\t根切り\t\t2\tm³\t4000\t=D2*F2\t'));
    expect(copiedText, isNot(contains('土工事')));
    expect(copiedText, contains('小計\t=SUM(G2:G2)'));
    expect(copiedText, contains('税抜合計'));
    expect(copiedText, contains('消費税（10%）'));
    expect(copiedText, contains('税込総額'));
    expect(find.text('見積明細をコピーしました（1件）'), findsOneWidget);
  });

  testWidgets('見積明細画面から明細を直接追加して工種小計へ反映できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emptyEstimateItems')), findsOneWidget);
    await tester.tap(find.byKey(const Key('addEstimateItemDirect')));
    await tester.pumpAndSettle();
    expect(find.text('見積明細へ追加'), findsOneWidget);
    expect(find.byKey(const Key('addEstimateAndOpen')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('estimateTradeField')),
      'コンクリート工事',
    );
    await tester.enterText(
      find.byKey(const Key('estimateNameField')),
      'コンクリート打設',
    );
    await tester.enterText(find.byKey(const Key('estimateQuantityField')), '3');
    await tester.enterText(find.byKey(const Key('estimateUnitField')), 'm³');
    await tester.ensureVisible(find.byKey(const Key('estimateUnitPriceField')));
    await tester.enterText(
      find.byKey(const Key('estimateUnitPriceField')),
      '15000',
    );
    await tester.ensureVisible(
      find.byKey(const Key('saveEstimateToUnitPriceMaster')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('この内容を単価マスタへ登録'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('estimateItemEditor')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addEstimateAndContinue')));
    await tester.pumpAndSettle();

    expect(find.text('コンクリート工事'), findsOneWidget);
    expect(find.text('コンクリート打設'), findsOneWidget);
    expect(find.text('税抜合計  ¥ 45,000'), findsOneWidget);
    expect(find.text('税込総額  ¥ 49,500'), findsOneWidget);
    expect(find.text('¥ 45,000'), findsNWidgets(2));
    expect(store.items.single.name, 'コンクリート打設');
    expect(controller.unitPriceMasters, hasLength(1));
    expect(controller.unitPriceMasters.single.name, 'コンクリート打設');
    expect(controller.unitPriceMasters.single.unitPrice, 15000);
    expect(find.text('見積明細と単価マスタへ追加しました（1件）'), findsOneWidget);
    expect(find.byKey(const Key('undoEstimateItemAdd')), findsOneWidget);

    await tester.tap(find.byKey(const Key('undoEstimateItemAdd')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('emptyEstimateItems')), findsOneWidget);
    expect(store.items, isEmpty);
    expect(controller.unitPriceMasters, hasLength(1));
    expect(find.text('直前の追加を取り消しました'), findsOneWidget);
  });

  testWidgets('既存の見積明細を複製して編集し同じ工種の小計へ追加できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        specification: 'W1.0 × H0.5',
        quantity: 2,
        unit: 'm³',
        unitPrice: 4000,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('estimateItemMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('複製'));
    await tester.pumpAndSettle();

    expect(find.text('見積明細へ追加'), findsOneWidget);
    expect(find.byKey(const Key('saveEstimateChanges')), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('estimateTradeField')))
          .controller
          ?.text,
      '土工事',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('estimateUnitPriceField')),
          )
          .controller
          ?.text,
      '4000',
    );
    await tester.enterText(
      find.byKey(const Key('estimateNameField')),
      '根切り 追加分',
    );
    await tester.enterText(find.byKey(const Key('estimateQuantityField')), '3');
    await tester.drag(
      find.byKey(const Key('estimateItemEditor')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addEstimateAndContinue')));
    await tester.pumpAndSettle();

    expect(find.text('根切り'), findsOneWidget);
    expect(find.text('根切り 追加分'), findsOneWidget);
    expect(find.text('2件'), findsNWidgets(2));
    expect(find.text('¥ 20,000'), findsOneWidget);
    expect(find.text('税抜合計  ¥ 20,000'), findsOneWidget);
    expect(find.text('税込総額  ¥ 22,000'), findsOneWidget);
    expect(store.items, hasLength(2));
    expect(store.items[0].id, isNot(store.items[1].id));
    expect(store.items[1].specification, 'W1.0 × H0.5');
  });

  testWidgets('見積基本情報を編集し明細を残したまま端末保存できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final estimateController = EstimateController(store: store);
    await estimateController.load();
    await estimateController.add(
      const EstimateItemDraft(name: '根切り', quantity: 2, unit: 'm³'),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: estimateController)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editEstimateInfo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('estimateInfoEditor')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('estimateInfoNameField')),
      '○○邸 外構工事',
    );
    await tester.enterText(
      find.byKey(const Key('estimateInfoSiteField')),
      '○○邸',
    );
    await tester.enterText(
      find.byKey(const Key('estimateInfoClientField')),
      '○○様',
    );
    await tester.enterText(
      find.byKey(const Key('estimateInfoNumberField')),
      '2026-001',
    );
    await tester.ensureVisible(find.byKey(const Key('saveEstimateInfo')));
    await tester.tap(find.byKey(const Key('saveEstimateInfo')));
    await tester.pumpAndSettle();

    expect(find.text('○○邸 外構工事'), findsOneWidget);
    expect(find.textContaining('現場：○○邸'), findsOneWidget);
    expect(store.document.info.clientName, '○○様');
    expect(store.document.info.estimateNumber, '2026-001');
    expect(store.items.single.name, '根切り');
  });

  testWidgets('見積一覧から新しい見積を作成して追加先を切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.updateInfo(
      controller.info.copyWith(estimateName: '1件目の見積'),
    );
    await tester.pumpWidget(
      MaterialApp(home: EstimateDocumentsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 5件'), findsOneWidget);
    await tester.tap(find.byKey(const Key('createEstimateDocument')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('estimateInfoNameField')),
      '2件目の見積',
    );
    await tester.ensureVisible(find.byKey(const Key('saveEstimateInfo')));
    await tester.tap(find.byKey(const Key('saveEstimateInfo')));
    await tester.pumpAndSettle();

    expect(find.text('2件目の見積'), findsOneWidget);
    expect(controller.estimates, hasLength(2));
    expect(controller.info.estimateName, '2件目の見積');
    Navigator.of(tester.element(find.byType(EstimateItemsScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('2 / 5件'), findsOneWidget);

    await tester.tap(find.byKey(const Key('estimateDocument0')));
    await tester.pumpAndSettle();
    expect(find.text('1件目の見積'), findsOneWidget);
    expect(controller.info.estimateName, '1件目の見積');
    expect(store.workspace.activeEstimateId, controller.info.id);

    Navigator.of(tester.element(find.byType(EstimateItemsScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('estimateDocumentMenu1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();
    expect(find.textContaining('含まれる明細もすべて削除されます'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '削除'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 5件'), findsOneWidget);
    expect(controller.estimates, hasLength(1));
  });

  testWidgets('明細追加画面から保存済みの別見積を追加先に選べる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.updateInfo(
      controller.info.copyWith(estimateName: '1件目の見積'),
    );
    final firstId = controller.info.id;
    await controller.createEstimate(
      EstimateInfo.initial(
        DateTime(2026, 8, 5, 12, 0, 0, 1),
      ).copyWith(estimateName: '2件目の見積'),
    );
    final secondId = controller.info.id;
    await tester.pumpWidget(
      MaterialApp(home: EstimateItemsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addEstimateItemDirect')));
    await tester.pumpAndSettle();
    expect(find.text('2件目の見積'), findsOneWidget);
    await tester.tap(find.byKey(const Key('changeEstimateDestination')));
    await tester.pumpAndSettle();
    expect(find.text('追加先の見積を選択'), findsOneWidget);
    await tester.tap(find.text('1件目の見積'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const Key('selectedEstimateDestination')))
          .data,
      '1件目の見積',
    );

    await tester.enterText(find.byKey(const Key('estimateNameField')), '追加先確認');
    await tester.drag(
      find.byKey(const Key('estimateItemEditor')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addEstimateAndContinue')));
    await tester.pumpAndSettle();

    expect(controller.info.id, firstId);
    expect(controller.items.single.name, '追加先確認');
    expect(store.workspace.activeEstimateId, firstId);
    expect(
      controller.estimates
          .firstWhere((estimate) => estimate.info.id == secondId)
          .items,
      isEmpty,
    );
  });

  testWidgets('見積一覧から見積全体を複製してコピーを開ける', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = FakeEstimateItemStore();
    final controller = EstimateController(store: store);
    await controller.load();
    await controller.updateInfo(
      controller.info.copyWith(estimateName: '○○邸 見積'),
    );
    await controller.add(
      const EstimateItemDraft(
        trade: '土工事',
        name: '根切り',
        quantity: 2,
        unitPrice: 4000,
      ),
    );
    final sourceInfoId = controller.info.id;
    final sourceItemId = controller.items.single.id;
    await tester.pumpWidget(
      MaterialApp(home: EstimateDocumentsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('estimateDocumentMenu0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('複製'));
    await tester.pumpAndSettle();

    expect(find.byType(EstimateItemsScreen), findsOneWidget);
    expect(find.text('○○邸 見積（コピー）'), findsOneWidget);
    expect(find.text('根切り'), findsOneWidget);
    expect(find.text('税抜合計  ¥ 8,000'), findsOneWidget);
    expect(find.text('税込総額  ¥ 8,800'), findsOneWidget);
    expect(controller.estimates, hasLength(2));
    expect(controller.info.id, isNot(sourceInfoId));
    expect(controller.items.single.id, isNot(sourceItemId));

    Navigator.of(tester.element(find.byType(EstimateItemsScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('2 / 5件'), findsOneWidget);
    expect(find.byKey(const Key('activeEstimateDocument')), findsOneWidget);
  });

  testWidgets('履歴スペース長押しで全体画面と分数3形式を確認できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('2-1÷2');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.longPress(find.byKey(const Key('historyPanel')));
    await tester.pumpAndSettle();

    expect(find.text('計算履歴'), findsOneWidget);
    expect(find.byKey(const Key('historySearchField')), findsOneWidget);
    expect(find.text('小数'), findsOneWidget);
    expect(find.text('仮分数'), findsOneWidget);
    expect(find.text('帯分数'), findsOneWidget);
    expect(find.text('1.5'), findsOneWidget);
    expect(find.text('3/2'), findsOneWidget);
    expect(find.text('1 1/2'), findsOneWidget);
  });

  testWidgets('履歴全体画面で式と解を検索できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    controller.pasteAtCaret('4+5');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.longPress(find.byKey(const Key('historyPanel')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('historySearchField')),
      '1 + 2',
    );
    await tester.pump();

    expect(find.byKey(const Key('fullHistoryExpression0')), findsOneWidget);
    expect(find.text('4 + 5'), findsNothing);
  });

  testWidgets('履歴全体画面を昇順と降順へ切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = CalculatorController();
    controller.pasteAtCaret('1+2');
    controller.press('=');
    controller.pasteAtCaret('4+5');
    controller.press('=');
    await tester.pumpWidget(
      MaterialApp(home: CalculatorScreen(controller: controller)),
    );

    await tester.longPress(find.byKey(const Key('historyPanel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historyCount')), findsOneWidget);
    expect(find.text('2件'), findsOneWidget);
    expect(find.text('昇順'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('fullHistoryExpression0'))).data,
      '1 + 2',
    );

    await tester.tap(find.byKey(const Key('historySortMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('降順'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('historySortLabel')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('fullHistoryExpression0'))).data,
      '4 + 5',
    );
  });
}
