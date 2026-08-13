import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/estimate/application/estimate_excel_export.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_totals.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';

void main() {
  test('表紙をA1:P17の原本仕様で生成し内訳総額と自社情報を連動する', () {
    final items = [
      _item(
        id: 'item-1',
        trade: '外構工事',
        location: '北側通路',
        name: '舗装工事\n下地調整含む',
        specification: '密粒度As\nt=50',
        description: '材料・施工共',
        quantity: 1.5,
        unit: '式',
        unitPrice: 1,
      ),
    ];
    final excel = _workbook(
      items,
      info: _formalInfo(),
      companyProfile: const CompanyProfile(
        companyName: '山田建設',
        representativeName: '代表取締役 山田太郎',
        postalCode: '100-0001',
        addressLine1: '東京都千代田区千代田1-1',
        addressLine2: '山田ビル2階',
        phoneNumber: '03-1234-5678',
      ),
    );
    final cover = excel['御見積書'];
    final breakdown = excel['内訳'];

    expect(excel.sheetOrder, ['御見積書', '内訳']);
    expect(excel.getDefaultSheet(), '御見積書');
    expect(_text(cover, 'A1'), '御見積書');
    expect(_text(cover, 'O2'), '令和8年8月12日');
    expect(_text(cover, 'C3'), '現場名：○○邸');
    expect(_text(cover, 'C4'), '山田太郎');
    expect(_text(cover, 'J4'), '様');
    expect(_text(cover, 'B6'), '金 額');
    expect(_text(cover, 'D6'), '￥');
    expect(_formula(cover, 'F6'), 'EstimateGrandTotal');
    expect(_text(cover, 'G7'), '外構工事一式として');
    expect(_text(cover, 'I8'), '内訳別紙明細書の通り');
    expect(_text(cover, 'B9'), '上記の通り御見積申し上げますので、何卒ご用命の程お願い申し上げます。');
    expect(_text(cover, 'H11'), '発行日より30日間');
    expect(_text(cover, 'H13'), '契約後30日以内');
    expect(_text(cover, 'H15'), '完了月末締め翌月末払い');
    expect(_text(cover, 'O13'), '〒100-0001 東京都千代田区千代田1-1');
    expect(_text(cover, 'O14'), '山田ビル2階');
    expect(
      cover.spannedItems,
      containsAll(['O13:P13', 'O14:P14', 'O15:P15', 'O16:P16']),
    );
    for (final cell in ['O13', 'O14', 'O15', 'O16']) {
      final style = cover.cell(CellIndex.indexByString(cell)).cellStyle;
      expect(style?.verticalAlignment, VerticalAlign.Bottom);
      expect(style?.fontFamily, 'MS P明朝');
      expect(style?.fontSize, 16);
    }
    expect(_text(cover, 'O15'), '山田建設');
    expect(_text(cover, 'O16'), '代表取締役 山田太郎');
    expect(_text(cover, 'O17'), '');
    expect(_textValues(cover).join('\n'), isNot(contains('03-1234-5678')));
    expect(
      const CompanyProfile(phoneNumber: '03-1234-5678').phoneNumber,
      '03-1234-5678',
    );
    expect(cover.printArea, 'A1:P17');
    expect(cover.pageSetup?.orientation, PageOrientation.landscape);
    expect(cover.pageSetup?.paperSize, PaperSize.a4);
    expect(cover.pageSetup?.fitToWidth, 1);
    expect(cover.pageSetup?.fitToHeight, 1);
    expect(cover.pageSetup?.horizontalCentered, isTrue);
    expect(cover.pageSetup?.verticalCentered, isTrue);
    expect(cover.getColumnWidth(0), closeTo(6.83, 0.001));
    expect(cover.getColumnWidth(14), closeTo(35.5, 0.001));
    expect(cover.getRowHeight(0), closeTo(60, 0.001));
    expect(cover.getRowHeight(16), closeTo(35.25, 0.001));
    expect(
      cover.cell(CellIndex.indexByString('A1')).cellStyle?.fontFamily,
      'MS P明朝',
    );
    expect(cover.cell(CellIndex.indexByString('A1')).cellStyle?.fontSize, 28);
    expect(
      excel.definedNames
          .singleWhere((name) => name.name == 'EstimateGrandTotal')
          .refersTo,
      "'内訳'!\$G\$10",
    );
    expect(_formula(breakdown, 'G5'), 'ROUND(D5*F5,0)');
    expect(estimateGrandTotal(items), 2);
  });

  test('宛名に様が含まれていても二重表示しない', () {
    final info = _formalInfo().copyWith(clientName: '山田太郎様');
    final cover = _workbook(const [], info: info)['御見積書'];

    expect(_text(cover, 'C4'), '山田太郎');
    expect(_text(cover, 'J4'), '様');
    expect(_textValues(cover).join(), isNot(contains('様様')));
  });

  test('内訳はA:J・20行周期でタイトルと見出しを各ページへ実体配置する', () {
    final items = List.generate(
      25,
      (index) => _item(
        id: 'item-$index',
        trade: '印刷しない工種',
        location: '施工場所A',
        name: '明細${index + 1}',
        quantity: index == 0 ? 12.346 : 1,
        unit: 'm²',
        unitPrice: 100,
      ),
    );
    final sheet = _workbook(items)['内訳'];

    expect(sheet.printArea, 'A1:J40');
    expect(sheet.rowPageBreaks, [20]);
    expect(_text(sheet, 'A1'), '内訳書');
    expect(_text(sheet, 'H1'), 'No. 1');
    expect(_text(sheet, 'A3'), '記号');
    expect(_text(sheet, 'H3'), '摘要');
    expect(_text(sheet, 'A21'), '内訳書');
    expect(_text(sheet, 'H21'), 'No. 2');
    expect(_text(sheet, 'A23'), '記号');
    expect(_text(sheet, 'H23'), '摘要');
    expect(sheet.getColumnWidth(0), closeTo(4.83, 0.001));
    expect(sheet.getColumnWidth(7), closeTo(23.17, 0.001));
    expect(sheet.getColumnWidth(9), closeTo(0.91, 0.001));
    expect(sheet.getRowHeight(0), closeTo(43.5, 0.001));
    expect(sheet.getRowHeight(1), closeTo(12, 0.001));
    expect(sheet.getRowHeight(2), closeTo(25.5, 0.001));
    expect(sheet.getRowHeight(3), closeTo(30, 0.001));
    expect(sheet.pageSetup?.orientation, PageOrientation.landscape);
    expect(sheet.pageSetup?.paperSize, PaperSize.a4);
    expect(sheet.pageSetup?.scale, 92);
    expect(sheet.pageSetup?.fitToWidth, isNull);
    expect(sheet.pageSetup?.fitToHeight, isNull);
    expect(_textValues(sheet).join('\n'), isNot(contains('印刷しない工種')));
    expect(
      sheet.cell(CellIndex.indexByString('D5')).value,
      DoubleCellValue(12.346),
    );
    expect(
      sheet
          .cell(CellIndex.indexByString('D5'))
          .cellStyle
          ?.numberFormat
          .toString(),
      contains('#,##0.#####'),
    );
    expect(_formula(sheet, 'G5'), 'ROUND(D5*F5,0)');
  });

  test('施工場所ごとに①②でまとめ小計を出しグループ間を1行空ける', () {
    final items = [
      _item(
        id: 'a1',
        trade: '工種A',
        location: '北側通路',
        name: '掘削',
        quantity: 2,
        unit: 'm³',
        unitPrice: 100,
      ),
      _item(
        id: 'a2',
        trade: '工種B',
        location: '北側通路',
        name: '埋戻し',
        quantity: 3,
        unit: 'm³',
        unitPrice: 100,
      ),
      _item(
        id: 'b1',
        trade: '工種C',
        location: '玄関前',
        name: '舗装',
        quantity: 4,
        unit: 'm²',
        unitPrice: 100,
      ),
    ];
    final sheet = _workbook(items)['内訳'];

    expect(_text(sheet, 'A4'), '①');
    expect(_text(sheet, 'B4'), '北側通路');
    expect(_text(sheet, 'B5'), '掘削');
    expect(_text(sheet, 'B6'), '埋戻し');
    expect(_text(sheet, 'B7'), '小計');
    expect(_formula(sheet, 'G7'), 'SUM(G5,G6)');
    expect(_text(sheet, 'A9'), '②');
    expect(_text(sheet, 'B9'), '玄関前');
    expect(_text(sheet, 'B11'), '小計');
    expect(_formula(sheet, 'G11'), 'SUM(G10)');
    expect(_textValues(sheet).join('\n'), isNot(contains('施工場所：')));
    expect(_textValues(sheet).join('\n'), isNot(contains('工種A')));
  });

  test('次グループがページ送りになる境界では先頭空欄を重複させない', () {
    final items = [
      ...List.generate(
        13,
        (index) => _item(
          id: 'first-$index',
          trade: '工種A',
          location: '第1施工場所',
          name: '第1明細${index + 1}',
          quantity: 1,
          unit: '式',
          unitPrice: 100,
        ),
      ),
      _item(
        id: 'second',
        trade: '工種B',
        location: '第2施工場所',
        name: '第2明細',
        quantity: 1,
        unit: '式',
        unitPrice: 100,
      ),
    ];
    final sheet = _workbook(items)['内訳'];

    expect(sheet.rowPageBreaks, contains(20));
    expect(_text(sheet, 'A24'), '②');
    expect(_text(sheet, 'B24'), '第2施工場所');
    expect(_text(sheet, 'B25'), '第2明細');
    expect(_text(sheet, 'A25'), '');
  });

  test('複数行の名称・仕様と摘要を保持し長文行は10ptで折り返す', () {
    final sheet = _workbook([
      _item(
        id: 'long',
        trade: '工種',
        location: '施工場所',
        name: '舗装工事\n下地調整を含む長い名称です',
        specification: '密粒度アスファルト\nt=50mm',
        description: '材料・施工・運搬を含む長い摘要です',
        quantity: 1,
        unit: '式',
        unitPrice: 1000,
      ),
    ])['内訳'];

    expect(_text(sheet, 'B5'), '舗装工事\n下地調整を含む長い名称です');
    expect(_text(sheet, 'C5'), '密粒度アスファルト\nt=50mm');
    expect(_text(sheet, 'H5'), '材料・施工・運搬を含む長い摘要です');
    expect(sheet.cell(CellIndex.indexByString('B5')).cellStyle?.fontSize, 10);
    expect(
      sheet.cell(CellIndex.indexByString('B5')).cellStyle?.wrap,
      TextWrapping.WrapText,
    );
    expect(sheet.getRowHeight(4), closeTo(30, 0.001));
  });

  test('税抜合計・消費税・税込総額は正式丸め済み小計を参照する', () {
    final items = [
      _item(
        id: 'one',
        trade: '工種',
        location: '場所',
        name: '1.5円',
        quantity: 1.5,
        unit: '式',
        unitPrice: 1,
      ),
      _item(
        id: 'two',
        trade: '工種',
        location: '場所',
        name: '1997円',
        quantity: 199.7,
        unit: '式',
        unitPrice: 10,
      ),
    ];
    final sheet = _workbook(items)['内訳'];

    expect(estimateSubtotal(items), 1999);
    expect(estimateTax(1999), 199);
    expect(estimateGrandTotal(items), 2198);
    expect(_formula(sheet, 'G7'), 'SUM(G5,G6)');
    expect(_formula(sheet, 'G9'), 'SUM(G7)');
    expect(_formula(sheet, 'G10'), 'INT(G9*10%)');
    expect(_formula(sheet, 'G11'), 'G9+G10');
  });

  for (final pages in [6, 10]) {
    test('$pagesページ相当でも20行周期・改ページ・最終集計を維持する', () {
      final itemCount = pages * 15;
      final items = List.generate(
        itemCount,
        (index) => _item(
          id: 'many-$index',
          trade: '工種',
          location: '長期工事',
          name: '明細${index + 1}',
          quantity: 1,
          unit: '式',
          unitPrice: 100,
        ),
      );
      final excel = _workbook(items);
      final sheet = excel['内訳'];
      final pageCount = int.parse(sheet.printArea!.split(':J').last) ~/ 20;

      expect(pageCount, greaterThanOrEqualTo(pages));
      expect(
        sheet.rowPageBreaks,
        List.generate(pageCount - 1, (index) => (index + 1) * 20),
      );
      for (var page = 0; page < pageCount; page++) {
        final firstRow = page * 20 + 1;
        expect(_text(sheet, 'A$firstRow'), '内訳書');
        expect(_text(sheet, 'H$firstRow'), 'No. ${page + 1}');
        expect(_text(sheet, 'A${firstRow + 2}'), '記号');
      }
      final grandTotal = excel.definedNames
          .singleWhere((name) => name.name == 'EstimateGrandTotal')
          .refersTo;
      expect(grandTotal, startsWith("'内訳'!\$G\$"));
      expect(_textValues(sheet).where((text) => text == '税込総額'), hasLength(1));
    });
  }

  test('追加情報と自社情報がない旧見積でも空欄で生成できる', () {
    final excel = _workbook(
      const [],
      info: EstimateInfo.initial(DateTime(2026, 8, 12)),
    );
    final cover = excel['御見積書'];

    expect(excel.sheetOrder, ['御見積書', '内訳']);
    expect(_text(cover, 'G7'), '');
    expect(_text(cover, 'H11'), '');
    expect(_text(cover, 'H13'), '');
    expect(_text(cover, 'H15'), '');
    expect(_text(cover, 'O13'), '');
    expect(_formula(cover, 'F6'), 'EstimateGrandTotal');
  });
}

Excel _workbook(
  List<EstimateItem> items, {
  EstimateInfo? info,
  CompanyProfile companyProfile = const CompanyProfile(),
}) {
  return Excel.decodeBytes(
    buildEstimateWorkbook(
      info: info ?? _formalInfo(),
      items: items,
      companyProfile: companyProfile,
    ),
  );
}

EstimateInfo _formalInfo() => EstimateInfo(
  id: 'estimate-formal',
  estimateName: '○○邸 正式見積',
  siteName: '○○邸',
  clientName: '山田太郎',
  createdDate: DateTime(2026, 8, 12),
  estimateNumber: '2026-001',
  notes: '',
  proviso: '外構工事一式として',
  validityPeriod: '発行日より30日間',
  constructionPeriod: '契約後30日以内',
  paymentTerms: '完了月末締め翌月末払い',
);

String _text(Sheet sheet, String cell) {
  final value = sheet.cell(CellIndex.indexByString(cell)).value;
  return value is TextCellValue ? value.value.toString() : '';
}

String _formula(Sheet sheet, String cell) =>
    (sheet.cell(CellIndex.indexByString(cell)).value as FormulaCellValue)
        .formula;

Iterable<String> _textValues(Sheet sheet) sync* {
  for (final row in sheet.rows) {
    for (final cell in row) {
      if (cell?.value case TextCellValue(:final value)) yield value.toString();
    }
  }
}

EstimateItem _item({
  required String id,
  required String trade,
  required String location,
  required String name,
  String specification = '',
  String description = '',
  required double quantity,
  required String unit,
  required double unitPrice,
}) {
  return EstimateItem.fromDraft(
    EstimateItemDraft(
      trade: trade,
      constructionLocation: location,
      name: name,
      specification: specification,
      description: description,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
    ),
    id: id,
    createdAt: DateTime(2026, 8, 3),
  );
}
