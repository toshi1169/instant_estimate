import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_info_editor_screen.dart';
import 'package:instant_estimate/features/estimate/presentation/estimate_item_editor_screen.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';

void main() {
  group('正式見積用データの後方互換性', () {
    test('旧明細JSONは施工場所なしで読み込める', () {
      final item = EstimateItem.fromJson({
        'id': 'legacy-item',
        'createdAt': '2026-08-12T00:00:00.000',
        'trade': '土工事',
        'name': '根切り',
      });

      expect(item.constructionLocation, isEmpty);
      expect(item.name, '根切り');
    });

    test('旧基本情報JSONは追加項目なしで読み込める', () {
      final info = EstimateInfo.fromJson({
        'id': 'legacy-estimate',
        'estimateName': '既存見積',
        'createdDate': '2026-08-12T00:00:00.000',
      });

      expect(info.proviso, isEmpty);
      expect(info.validityPeriod, isEmpty);
      expect(info.constructionPeriod, isEmpty);
      expect(info.paymentTerms, isEmpty);
      expect(info.displayName, '既存見積');
    });

    test('施工場所を保存・復元できる', () {
      final item = EstimateItem.fromDraft(
        const EstimateItemDraft(
          trade: '外構工事',
          constructionLocation: '北側通路\n玄関前',
          name: '舗装',
        ),
        id: 'item-1',
        createdAt: DateTime(2026, 8, 12),
      );

      final restored = EstimateItem.fromJson(item.toJson());
      expect(restored.constructionLocation, '北側通路\n玄関前');
      expect(restored.toDraft().constructionLocation, '北側通路\n玄関前');
    });

    test('正式見積用基本情報を保存・復元できる', () {
      final original = EstimateInfo.initial(DateTime(2026, 8, 12)).copyWith(
        proviso: '外構工事一式として',
        validityPeriod: '発行日より30日間',
        constructionPeriod: '契約後30日以内',
        paymentTerms: '完了月末締め翌月末払い',
      );

      final restored = EstimateInfo.fromJson(original.toJson());
      expect(restored.proviso, '外構工事一式として');
      expect(restored.validityPeriod, '発行日より30日間');
      expect(restored.constructionPeriod, '契約後30日以内');
      expect(restored.paymentTerms, '完了月末締め翌月末払い');
    });
  });

  testWidgets('施工場所・名称・仕様は複数行、摘要は1行で入力できる', (tester) async {
    EstimateItemEditorResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context)
                  .push<EstimateItemEditorResult>(
                    MaterialPageRoute(
                      builder: (_) => const EstimateItemEditorScreen(
                        initialDraft: EstimateItemDraft(),
                        isEditing: true,
                      ),
                    ),
                  );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    EditableText field(Key key) => tester.widget(
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText)),
    );
    expect(
      field(const Key('estimateConstructionLocationField')).maxLines,
      isNull,
    );
    expect(field(const Key('estimateNameField')).maxLines, isNull);
    expect(field(const Key('estimateSpecificationField')).maxLines, isNull);

    await tester.enterText(
      find.byKey(const Key('estimateConstructionLocationField')),
      '北側通路\n玄関前',
    );
    await tester.enterText(
      find.byKey(const Key('estimateNameField')),
      '舗装工事\n下地調整含む',
    );
    await tester.enterText(
      find.byKey(const Key('estimateSpecificationField')),
      '密粒度As\nt=50',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('estimateDescriptionField')),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('estimateItemEditor')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(field(const Key('estimateDescriptionField')).maxLines, 1);
    await tester.ensureVisible(find.byKey(const Key('saveEstimateChanges')));
    await tester.tap(find.byKey(const Key('saveEstimateChanges')));
    await tester.pumpAndSettle();

    expect(result?.draft.constructionLocation, '北側通路\n玄関前');
    expect(result?.draft.name, '舗装工事\n下地調整含む');
    expect(result?.draft.specification, '密粒度As\nt=50');
  });

  testWidgets('見積基本情報の追加項目を編集して保存できる', (tester) async {
    EstimateInfo? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<EstimateInfo>(
                MaterialPageRoute(
                  builder: (_) => EstimateInfoEditorScreen(
                    initialInfo: EstimateInfo.initial(DateTime(2026, 8, 12)),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Future<void> enter(Key key, String value) async {
      final finder = find.byKey(key);
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
    }

    await enter(const Key('estimateInfoProvisoField'), '外構工事一式として');
    await enter(const Key('estimateInfoValidityPeriodField'), '発行日より30日間');
    await enter(const Key('estimateInfoConstructionPeriodField'), '契約後30日以内');
    await enter(const Key('estimateInfoPaymentTermsField'), '完了月末締め翌月末払い');
    await tester.ensureVisible(find.byKey(const Key('saveEstimateInfo')));
    await tester.tap(find.byKey(const Key('saveEstimateInfo')));
    await tester.pumpAndSettle();

    expect(result?.proviso, '外構工事一式として');
    expect(result?.validityPeriod, '発行日より30日間');
    expect(result?.constructionPeriod, '契約後30日以内');
    expect(result?.paymentTerms, '完了月末締め翌月末払い');
  });

  testWidgets('手入力数量は明細確定時だけ見積専用設定で丸めて保存する', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    EstimateItemEditorResult? result;
    const initialDraft = EstimateItemDraft(quantity: 12.34567);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context)
                  .push<EstimateItemEditorResult>(
                    MaterialPageRoute(
                      builder: (_) => const EstimateItemEditorScreen(
                        initialDraft: initialDraft,
                        isEditing: true,
                        settings: AppSettings(
                          estimateDecimalPlaces: 3,
                          estimateRoundingMode:
                              EstimateQuantityRoundingMode.halfUp,
                        ),
                      ),
                    ),
                  );
            },
            child: const Text('open quantity'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open quantity'));
    await tester.pumpAndSettle();
    final quantityField = tester.widget<TextFormField>(
      find.byKey(const Key('estimateQuantityField')),
    );
    expect(quantityField.controller?.text, '12.34567');
    expect(initialDraft.quantity, 12.34567);

    await tester.scrollUntilVisible(
      find.byKey(const Key('saveEstimateChanges')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('estimateItemEditor')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('saveEstimateChanges')));
    await tester.pumpAndSettle();

    expect(result?.draft.quantity, 12.346);
    expect(result?.draft.originalQuantity, 12.34567);
  });

  testWidgets('既存明細は開いただけでは数量を再丸めしない', (tester) async {
    const initialDraft = EstimateItemDraft(quantity: 12.34567);
    await tester.pumpWidget(
      const MaterialApp(
        home: EstimateItemEditorScreen(
          initialDraft: initialDraft,
          isEditing: true,
          settings: AppSettings(
            estimateDecimalPlaces: 1,
            estimateRoundingMode: EstimateQuantityRoundingMode.floor,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('estimateQuantityField')))
          .controller
          ?.text,
      '12.34567',
    );
    expect(initialDraft.quantity, 12.34567);
  });
}
