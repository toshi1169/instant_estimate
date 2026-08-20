import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_pdf_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_quantity.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_totals.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('日本語を含むA4横の印刷用PDFを生成する', () async {
    final bytes = await buildEstimatePdf(
      info: EstimateInfo(
        id: 'estimate-1',
        estimateName: '○○邸 外構工事',
        siteName: '○○邸',
        clientName: '○○様',
        createdDate: DateTime(2026, 8, 3),
        estimateNumber: '001',
        notes: '',
      ),
      items: [
        EstimateItem.fromDraft(
          const EstimateItemDraft(
            trade: '外構工事',
            name: '化粧ブロック積み',
            specification: 'スマートC120タイプ',
            quantity: 10,
            unit: '本',
            unitPrice: 1100,
            description: '色：ダークグレー',
          ),
          id: 'item-1',
          createdAt: DateTime(2026, 8, 3),
        ),
      ],
    );

    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('小数明細を共通金額計算で集計してPDFを生成する', () async {
    final items = [
      _item('1', quantity: 1.5, unitPrice: 1),
      _item('2', quantity: 2.5, unitPrice: 1),
      _item('3', quantity: 199.4, unitPrice: 10),
    ];

    expect(items.map(estimateLineAmount), [2, 3, 1994]);
    expect(estimateSubtotal(items), 1999);
    expect(estimateTax(estimateSubtotal(items)), 199);
    expect(estimateGrandTotal(items), 2198);

    final bytes = await buildEstimatePdf(
      info: EstimateInfo.initial(DateTime(2026, 8, 12)),
      items: items,
    );
    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test('PDF数量は正式数量を3桁へ再丸めせずそのまま表示する', () {
    expect(formatEstimateQuantity(12.346), '12.346');
    expect(formatEstimateQuantity(12.34567), '12.34567');
    expect(formatEstimateQuantity(12.300), '12.3');
  });

  test('正式PDF数量は見積設定1～5桁で末尾0を固定表示する', () {
    expect(formatEstimatePdfQuantity(37, 1), '37.0');
    expect(formatEstimatePdfQuantity(12.6, 2), '12.60');
    expect(formatEstimatePdfQuantity(12.346, 3), '12.346');
    expect(formatEstimatePdfQuantity(1, 4), '1.0000');
    expect(formatEstimatePdfQuantity(1, 5), '1.00000');
    expect(formatEstimatePdfQuantity(null, 2), '');
  });

  test('自社情報は設定順・表示設定を維持して空欄を詰め最大5項目にする', () {
    const profile = CompanyProfile(
      companyName: '山田建設',
      representativeName: '山田太郎',
      postalCode: '〒100-0001',
      addressLine1: '東京都千代田区',
      addressLine2: '',
      phoneNumber: '03-1234-5678',
      displayOrder: [
        CompanyProfileSection.postalCode,
        CompanyProfileSection.addressLine1,
        CompanyProfileSection.addressLine2,
        CompanyProfileSection.companyName,
        CompanyProfileSection.representativeName,
        CompanyProfileSection.phoneNumber,
      ],
      excelVisibleSections: [
        CompanyProfileSection.postalCode,
        CompanyProfileSection.addressLine1,
        CompanyProfileSection.companyName,
        CompanyProfileSection.representativeName,
        CompanyProfileSection.phoneNumber,
      ],
    );

    expect(estimatePdfCompanyProfileLines(profile), [
      '〒100-0001',
      '東京都千代田区',
      '山田建設',
      '山田太郎',
      '03-1234-5678',
    ]);
  });

  test('20行雛形に記号・施工場所・小計・空欄・最終集計を配置する', () {
    final items = [
      for (var index = 0; index < 6; index++)
        _groupItem('$index', symbol: '①', location: '北面', quantity: 1),
      _groupItem('second', symbol: '②', location: '南面', quantity: 2),
    ];

    final pages = buildEstimatePdfBreakdownLayout(items);

    expect(pages, hasLength(1));
    expect(pages.single.number, 1);
    expect(pages.single.rows, hasLength(17));
    expect(pages.single.rows[0].type, EstimatePdfRowType.location);
    expect(pages.single.rows[0].symbol, '①');
    expect(pages.single.rows[0].location, '北面');
    expect(pages.single.rows[7].type, EstimatePdfRowType.subtotal);
    expect(pages.single.rows[8].type, EstimatePdfRowType.blank);
    // 帳票4行目を0番とするため、9番はExcel/PDFの13行目に相当する。
    expect(pages.single.rows[9].type, EstimatePdfRowType.location);
    expect(pages.single.rows[9].symbol, '②');
    expect(pages.single.rows[11].type, EstimatePdfRowType.subtotal);
    expect(pages.single.rows[12].type, EstimatePdfRowType.blank);
    expect(pages.single.rows[13].label, '①+② 計');
    expect(pages.single.rows[14].label, '消費税10%');
    expect(pages.single.rows[15].label, '合計');
    expect(pages.single.rows[15].amount, estimateGrandTotal(items));
  });

  test('ページ境界でもXLSXと同じ17帳票行で連番ページだけを生成する', () {
    final items = [
      for (var index = 0; index < 13; index++)
        _groupItem('$index', symbol: '①', location: '北面', quantity: 1),
      _groupItem('second', symbol: '②', location: '南面', quantity: 1),
    ];

    final pages = buildEstimatePdfBreakdownLayout(items);

    expect(pages.map((page) => page.number), [1, 2]);
    expect(pages.every((page) => page.rows.length == 17), isTrue);
    expect(pages.first.rows.last.type, EstimatePdfRowType.blank);
    expect(pages[1].rows.first.type, EstimatePdfRowType.location);
    expect(pages[1].rows.first.symbol, '②');
    expect(
      pages.expand((page) => page.rows).where((row) => row.label == '合計'),
      hasLength(1),
    );
  });
}

EstimateItem _item(
  String id, {
  required double quantity,
  required double unitPrice,
}) => EstimateItem.fromDraft(
  EstimateItemDraft(
    trade: '端数確認',
    name: '端数明細$id',
    quantity: quantity,
    unit: '式',
    unitPrice: unitPrice,
  ),
  id: id,
  createdAt: DateTime(2026, 8, 12),
);

EstimateItem _groupItem(
  String id, {
  required String symbol,
  required String location,
  required double quantity,
}) => EstimateItem.fromDraft(
  EstimateItemDraft(
    constructionSymbol: symbol,
    constructionLocation: location,
    trade: 'PDFへ出力しない工種',
    name: '明細$id',
    specification: '標準仕様',
    quantity: quantity,
    unit: '式',
    unitPrice: 100,
    description: '摘要$id',
  ),
  id: id,
  createdAt: DateTime(2026, 8, 12),
);
