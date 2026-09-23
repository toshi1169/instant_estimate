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
    expect(_text(cover, 'I1'), '御　見　積　書');
    expect(cover.spannedItems, contains('I1:N1'));
    expect(
      cover.cell(CellIndex.indexByString('I1')).cellStyle?.horizontalAlignment,
      HorizontalAlign.Center,
    );
    expect(
      cover.cell(CellIndex.indexByString('I1')).cellStyle?.verticalAlignment,
      VerticalAlign.Bottom,
    );
    expect(cover.cell(CellIndex.indexByString('I1')).cellStyle?.fontSize, 28);
    expect(_text(cover, 'O2'), '2026年8月12日');
    expect(cover.cell(CellIndex.indexByString('O2')).cellStyle?.fontSize, 16);
    expect(cover.getRowHeight(1), closeTo(22, 0.001));
    expect(cover.getRowHeight(2), closeTo(23, 0.001));
    expect(_text(cover, 'C3'), '');
    expect(_text(cover, 'C4'), '○○邸 正式見積');
    expect(cover.spannedItems, contains('C4:J4'));
    expect(cover.cell(CellIndex.indexByString('C4')).cellStyle?.fontSize, 22);
    expect(
      cover.cell(CellIndex.indexByString('C4')).cellStyle?.horizontalAlignment,
      HorizontalAlign.Center,
    );
    expect(
      cover.cell(CellIndex.indexByString('C4')).cellStyle?.verticalAlignment,
      VerticalAlign.Bottom,
    );
    expect(
      cover.cell(CellIndex.indexByString('C4')).cellStyle?.wrap,
      TextWrapping.Clip,
    );
    expect(_text(cover, 'J4'), '');
    expect(_text(cover, 'B6'), '金 額');
    expect(_text(cover, 'F6'), '¥');
    expect(_formula(cover, 'H6'), 'EstimateGrandTotal');
    expect(
      cover.cell(CellIndex.indexByString('H6')).cellStyle?.horizontalAlignment,
      HorizontalAlign.Left,
    );
    expect(
      cover.cell(CellIndex.indexByString('H6')).cellStyle?.verticalAlignment,
      VerticalAlign.Bottom,
    );
    expect(cover.cell(CellIndex.indexByString('H6')).cellStyle?.indent, 1);
    expect(
      cover.spannedItems,
      containsAll(['B6:C6', 'F6:G6', 'H6:M6', 'F7:G7', 'H7:N7', 'I8:N9']),
    );
    for (final cell in ['B6', 'D6', 'E6', 'F6', 'H6']) {
      final style = cover.cell(CellIndex.indexByString(cell)).cellStyle!;
      expect(style.bottomBorder.borderStyle, BorderStyle.Thin);
      expect(style.topBorder.borderStyle, isNull);
      expect(style.leftBorder.borderStyle, isNull);
      expect(style.rightBorder.borderStyle, isNull);
    }
    expect(_text(cover, 'F7'), '但');
    expect(_text(cover, 'H7'), '外構工事一式として');
    expect(cover.cell(CellIndex.indexByString('F7')).cellStyle?.fontSize, 16);
    expect(
      cover.cell(CellIndex.indexByString('F7')).cellStyle?.horizontalAlignment,
      HorizontalAlign.Center,
    );
    expect(
      cover.cell(CellIndex.indexByString('F7')).cellStyle?.verticalAlignment,
      VerticalAlign.Bottom,
    );
    expect(_text(cover, 'I8'), '内 訳 別 紙 明 細 書 の 通 り');
    expect(
      cover.cell(CellIndex.indexByString('I8')).cellStyle?.verticalAlignment,
      VerticalAlign.Center,
    );
    expect(
      cover.cell(CellIndex.indexByString('I8')).cellStyle?.horizontalAlignment,
      HorizontalAlign.Center,
    );
    expect(cover.cell(CellIndex.indexByString('I8')).cellStyle?.fontSize, 14);
    expect(_text(cover, 'B10'), '上記の通り御見積申し上げますので、何卒ご用命の程お願い申し上げます。');
    expect(
      cover.cell(CellIndex.indexByString('B10')).cellStyle?.horizontalAlignment,
      HorizontalAlign.Left,
    );
    expect(_text(cover, 'E11'), '');
    expect(_text(cover, 'H11'), '発行日より30日間');
    expect(_text(cover, 'H13'), '契約後30日以内');
    expect(_text(cover, 'H15'), '完了月末締め翌月末払い');
    expect(_text(cover, 'H16'), '既存備考');
    expect(
      cover.spannedItems,
      containsAll(['H11:M11', 'H13:M13', 'H15:M15', 'H16:M16']),
    );
    expect(cover.spannedItems, isNot(contains('H16:N16')));
    for (final cell in ['H11', 'H13', 'H15']) {
      final style = cover.cell(CellIndex.indexByString(cell)).cellStyle!;
      expect(style.horizontalAlignment, HorizontalAlign.Left);
      expect(style.verticalAlignment, VerticalAlign.Bottom);
      expect(style.wrap, TextWrapping.Clip);
    }
    final notesStyle = cover.cell(CellIndex.indexByString('H16')).cellStyle!;
    expect(notesStyle.fontSize, 10);
    expect(notesStyle.horizontalAlignment, HorizontalAlign.Left);
    expect(notesStyle.verticalAlignment, VerticalAlign.Bottom);
    expect(notesStyle.wrap, TextWrapping.WrapText);
    expect(notesStyle.bottomBorder.borderStyle, BorderStyle.Thin);
    expect(notesStyle.bottomBorder.borderColorHex, 'FF000000');
    expect(notesStyle.topBorder.borderStyle, isNull);
    expect(notesStyle.leftBorder.borderStyle, isNull);
    expect(notesStyle.rightBorder.borderStyle, isNull);
    expect(_textValues(cover).join('\n'), isNot(contains('2026-001')));
    expect(_text(cover, 'O11'), '山田建設');
    expect(_text(cover, 'O12'), '代表取締役 山田太郎');
    expect(_text(cover, 'O13'), '100-0001');
    expect(_text(cover, 'O14'), '東京都千代田区千代田1-1');
    expect(_text(cover, 'O15'), '山田ビル2階');
    expect(_text(cover, 'O16'), '');
    expect(
      cover.spannedItems,
      containsAll([
        'O11:P11',
        'O12:P12',
        'O13:P13',
        'O14:P14',
        'O15:P15',
        'O16:P16',
      ]),
    );
    for (final cell in ['O11', 'O12', 'O13', 'O14', 'O15']) {
      final style = cover.cell(CellIndex.indexByString(cell)).cellStyle;
      expect(style?.horizontalAlignment, HorizontalAlign.Left);
      expect(style?.verticalAlignment, VerticalAlign.Bottom);
      expect(style?.fontFamily, 'MS P明朝');
      expect(style?.fontSize, 16);
      expect(style?.isBold, isTrue);
      expect(style?.wrap, TextWrapping.Clip);
    }
    final reserveStyle = cover.cell(CellIndex.indexByString('O16')).cellStyle;
    expect(reserveStyle?.fontFamily, 'MS P明朝');
    expect(reserveStyle?.fontSize, 10);
    expect(reserveStyle?.isBold, isFalse);
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
    for (var row = 10; row <= 14; row++) {
      expect(cover.getRowHeight(row), closeTo(24.75, 0.001));
    }
    expect(cover.getRowHeight(15), closeTo(38.25, 0.001));
    expect(cover.getRowHeight(16), closeTo(18.75, 0.001));
    expect(
      cover.cell(CellIndex.indexByString('I1')).cellStyle?.fontFamily,
      'MS P明朝',
    );
    expect(cover.cell(CellIndex.indexByString('I1')).cellStyle?.fontSize, 28);
    expect(
      excel.definedNames
          .singleWhere((name) => name.name == 'EstimateGrandTotal')
          .refersTo,
      "'内訳'!\$G\$10",
    );
    expect(_formula(breakdown, 'G5'), 'ROUND(D5*F5,0)');
    expect(estimateGrandTotal(items), 2);
  });

  test('自社情報は設定順を維持しO:P11から独立項目として配置する', () {
    final cover = _workbook(
      const [],
      companyProfile: const CompanyProfile(
        companyName: '山田建設',
        representativeName: '山田太郎',
        postalCode: '100-0001',
        addressLine1: '東京都千代田区',
        addressLine2: '山田ビル2階',
        displayOrder: [
          CompanyProfileSection.postalCode,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.companyName,
          CompanyProfileSection.representativeName,
          CompanyProfileSection.addressLine2,
          CompanyProfileSection.phoneNumber,
        ],
      ),
    )['御見積書'];

    expect(_text(cover, 'O11'), '100-0001');
    expect(_text(cover, 'O12'), '東京都千代田区');
    expect(_text(cover, 'O13'), '山田建設');
    expect(_text(cover, 'O14'), '山田太郎');
    expect(_text(cover, 'O15'), '山田ビル2階');
    expect(_text(cover, 'O16'), '');
  });

  test('Excel非表示と空欄項目を除外し表示項目を上から繰り上げる', () {
    final cover = _workbook(
      const [],
      companyProfile: const CompanyProfile(
        companyName: '山田建設',
        representativeName: '山田太郎',
        postalCode: '〒100-0001',
        addressLine1: '東京都千代田区',
        addressLine2: '',
        phoneNumber: '03-1234-5678',
        displayOrder: [
          CompanyProfileSection.postalCode,
          CompanyProfileSection.addressLine2,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.phoneNumber,
          CompanyProfileSection.companyName,
          CompanyProfileSection.representativeName,
        ],
        excelVisibleSections: [
          CompanyProfileSection.postalCode,
          CompanyProfileSection.addressLine2,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.companyName,
        ],
      ),
    )['御見積書'];

    expect(_text(cover, 'O11'), '〒100-0001');
    expect(_text(cover, 'O12'), '東京都千代田区');
    expect(_text(cover, 'O13'), '山田建設');
    expect(_text(cover, 'O14'), '');
    expect(_text(cover, 'O15'), '');
    expect(_textValues(cover), isNot(contains('03-1234-5678')));
    expect(_textValues(cover), isNot(contains('山田太郎')));
  });

  test('電話番号は明示表示時だけ正式XLSXへ出力できる', () {
    final cover = _workbook(
      const [],
      companyProfile: const CompanyProfile(
        companyName: '山田建設',
        phoneNumber: '03-1234-5678',
        displayOrder: [
          CompanyProfileSection.phoneNumber,
          CompanyProfileSection.companyName,
          CompanyProfileSection.representativeName,
          CompanyProfileSection.postalCode,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.addressLine2,
        ],
        excelVisibleSections: [
          CompanyProfileSection.phoneNumber,
          CompanyProfileSection.companyName,
        ],
      ),
    )['御見積書'];

    expect(_text(cover, 'O11'), '03-1234-5678');
    expect(_text(cover, 'O12'), '山田建設');
    expect(_text(cover, 'O13'), '');
  });

  test('表紙は見積名だけを表示し旧現場名・宛名・見積番号を表示しない', () {
    final info = _formalInfo().copyWith(
      estimateName: '松本邸 外構工事',
      siteName: '旧現場名',
      clientName: '旧宛名様',
      estimateNumber: '旧見積番号',
    );
    final cover = _workbook(const [], info: info)['御見積書'];

    expect(_text(cover, 'C4'), '松本邸 外構工事');
    expect(cover.spannedItems, contains('C4:J4'));
    expect(_textValues(cover).join(), isNot(contains('旧現場名')));
    expect(_textValues(cover).join(), isNot(contains('旧宛名様')));
    expect(_textValues(cover).join(), isNot(contains('旧見積番号')));
  });

  test('独立した様を表紙へ表示しない', () {
    final info = _formalInfo().copyWith(estimateName: '松本邸 外構工事');
    final cover = _workbook(const [], info: info)['御見積書'];

    expect(_text(cover, 'C4'), '松本邸 外構工事');
    expect(_textValues(cover), isNot(contains('様')));
  });

  test('表紙情報を変更しても内訳シートの内容とページ構造は変わらない', () {
    final items = [
      _item(
        id: 'unchanged-breakdown',
        trade: '工種',
        location: '施工場所',
        name: '明細',
        quantity: 12.34567,
        unit: 'm²',
        unitPrice: 100,
      ),
    ];
    final first = _workbook(items)['内訳'];
    final second = _workbook(
      items,
      info: _formalInfo().copyWith(
        siteName: '別の現場名',
        clientName: '別の宛名',
        proviso: '別の但し書き',
      ),
      companyProfile: const CompanyProfile(
        companyName: '別会社',
        addressLine1: '別住所',
        displayOrder: [
          CompanyProfileSection.companyName,
          CompanyProfileSection.representativeName,
          CompanyProfileSection.postalCode,
          CompanyProfileSection.addressLine1,
          CompanyProfileSection.addressLine2,
          CompanyProfileSection.phoneNumber,
        ],
      ),
    )['内訳'];

    expect(_sheetValues(first), _sheetValues(second));
    expect(first.printArea, second.printArea);
    expect(first.rowPageBreaks, second.rowPageBreaks);
    expect(first.getColumnWidths, second.getColumnWidths);
    expect(first.getRowHeights, second.getRowHeights);
  });

  for (var decimalPlaces = 1; decimalPlaces <= 5; decimalPlaces++) {
    test('数量は数値セルのまま有効小数を最大5桁表示する', () {
      final sheet = _workbook([
        _item(
          id: 'quantity-$decimalPlaces',
          trade: '工種',
          location: '施工場所',
          name: '数量確認',
          quantity: 37,
          unit: 'm',
          unitPrice: 100,
        ),
      ], estimateDecimalPlaces: decimalPlaces)['内訳'];
      final quantityCell = sheet.cell(CellIndex.indexByString('D5'));
      const expectedFormat = '#,##0.#####';

      expect(quantityCell.value, IntCellValue(37));
      expect(
        quantityCell.cellStyle?.numberFormat.toString(),
        contains(expectedFormat),
      );
      expect(_formula(sheet, 'G5'), 'ROUND(D5*F5,0)');
    });
  }

  test('内訳はA:K・20行周期でタイトルと見出しを各ページへ実体配置する', () {
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
    final excel = _workbook(items);
    final sheet = excel['内訳'];

    expect(sheet.printArea, 'A1:K40');
    expect(sheet.rowPageBreaks, [20]);
    expect(_text(sheet, 'C1'), '　内　訳　書');
    expect(sheet.spannedItems, containsAll(['C1:F1', 'C21:F21']));
    expect(_text(sheet, 'K1'), 'No.1');
    expect(_text(sheet, 'A3'), '記号');
    expect(_text(sheet, 'H3'), '摘要');
    expect(_text(sheet, 'C21'), '　内　訳　書');
    expect(_text(sheet, 'K21'), 'No.2');
    expect(_text(sheet, 'A23'), '記号');
    expect(_text(sheet, 'H23'), '摘要');
    expect(sheet.getColumnWidth(0), closeTo(4.83, 0.001));
    const expectedWidths = [
      32.0,
      32.0,
      6.83,
      4.67,
      10.76,
      13.67,
      11.5,
      3.0,
      3.0,
      10.17,
    ];
    for (var column = 1; column <= 10; column++) {
      expect(
        sheet.getColumnWidth(column),
        closeTo(expectedWidths[column - 1], 0.001),
      );
    }
    expect(sheet.getRowHeight(0), closeTo(43.5, 0.001));
    expect(sheet.getRowHeight(1), closeTo(12, 0.001));
    expect(sheet.getRowHeight(2), closeTo(25.5, 0.001));
    for (final pageStart in [0, 20]) {
      for (var row = pageStart + 3; row <= pageStart + 18; row++) {
        expect(sheet.getRowHeight(row), closeTo(30, 0.001));
      }
    }
    for (final cell in ['C1', 'C21']) {
      final style = sheet.cell(CellIndex.indexByString(cell)).cellStyle!;
      expect(style.fontSize, 26);
      expect(style.horizontalAlignment, HorizontalAlign.Center);
      expect(style.verticalAlignment, VerticalAlign.Bottom);
    }
    for (final cell in ['K1', 'K21']) {
      final style = sheet.cell(CellIndex.indexByString(cell)).cellStyle!;
      expect(style.fontSize, 10);
      expect(style.horizontalAlignment, HorizontalAlign.Center);
      expect(style.verticalAlignment, VerticalAlign.Bottom);
      expect(style.bottomBorder.borderStyle, BorderStyle.Dotted);
      expect(style.topBorder.borderStyle, isNull);
      expect(style.leftBorder.borderStyle, isNull);
      expect(style.rightBorder.borderStyle, isNull);
    }
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

    for (final pageStart in [1, 21]) {
      final headerCell = 'H${pageStart + 2}';
      expect(
        sheet.spannedItems,
        contains('H${pageStart + 2}:K${pageStart + 2}'),
      );
      final headerStyle = sheet
          .cell(CellIndex.indexByString(headerCell))
          .cellStyle!;
      expect(headerStyle.fontSize, 11);
      expect(headerStyle.horizontalAlignment, HorizontalAlign.Center);
      expect(headerStyle.verticalAlignment, VerticalAlign.Bottom);

      for (var row = pageStart + 3; row <= pageStart + 19; row++) {
        expect(sheet.spannedItems, contains('H$row:K$row'));
        final style = sheet.cell(CellIndex.indexByString('H$row')).cellStyle!;
        expect(style.fontSize, 11);
        expect(style.horizontalAlignment, HorizontalAlign.Left);
        expect(style.verticalAlignment, VerticalAlign.Bottom);
        expect(style.wrap, TextWrapping.Clip);
      }
      for (var row = pageStart + 2; row <= pageStart + 19; row++) {
        for (var column = 0; column <= 6; column++) {
          _expectThinBorders(
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: row - 1,
                  ),
                )
                .cellStyle!,
          );
        }
      }
    }
  });

  test('施工場所ごとに①②でまとめ小計を出しグループ間を1行空ける', () {
    final items = [
      _item(
        id: 'a1',
        symbol: '①',
        trade: '工種A',
        location: '北側通路',
        name: '掘削',
        quantity: 2,
        unit: 'm³',
        unitPrice: 100,
      ),
      _item(
        id: 'a2',
        symbol: '①',
        trade: '工種B',
        location: '北側通路',
        name: '埋戻し',
        quantity: 3,
        unit: 'm³',
        unitPrice: 100,
      ),
      _item(
        id: 'b1',
        symbol: '②',
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

  test('摘要の結合範囲は3ページ目まで全セルへ黒い細線を設定する', () {
    final items = List.generate(
      40,
      (index) => _item(
        id: 'border-$index',
        symbol: '①',
        trade: '出力しない工種',
        location: '長期施工場所',
        name: '明細${index + 1}',
        quantity: 1,
        unit: '式',
        unitPrice: 100,
      ),
    );
    final sheet = _workbook(items)['内訳'];

    for (final pageStart in [1, 21, 41]) {
      for (var row = pageStart + 2; row <= pageStart + 19; row++) {
        expect(sheet.spannedItems, contains('H$row:K$row'));
        _expectThinBorders(
          sheet.cell(CellIndex.indexByString('H$row')).cellStyle!,
        );
      }
    }
  });

  test('①小計の次を1行空け今回例では②を13行目へ配置する', () {
    final items = [
      for (var index = 0; index < 6; index++)
        _item(
          id: 'first-$index',
          symbol: '①',
          trade: '工種A',
          location: '西・北　隣地側　土留めブロック工事',
          name: '①明細${index + 1}',
          quantity: 1,
          unit: '式',
          unitPrice: 100,
        ),
      for (var index = 0; index < 7; index++)
        _item(
          id: 'second-$index',
          symbol: '②',
          trade: '工種B',
          location: '南　道路側　土留めブロック工事',
          name: '②明細${index + 1}',
          quantity: 1,
          unit: '式',
          unitPrice: 100,
        ),
    ];
    final excel = _workbook(items);
    final sheet = excel['内訳'];

    expect(_text(sheet, 'B11'), '小計');
    expect(_text(sheet, 'A12'), '');
    expect(_text(sheet, 'B12'), '');
    expect(_text(sheet, 'A13'), '②');
    expect(_text(sheet, 'B13'), '南　道路側　土留めブロック工事');
    expect(_text(sheet, 'B20'), '②明細7');
    expect(_text(sheet, 'B24'), '小計');
    expect(_text(sheet, 'B25'), '');
    expect(_text(sheet, 'B26'), '①+② 計');
    expect(_formula(sheet, 'G26'), 'SUM(G11,G24)');
    expect(_text(sheet, 'B27'), '消費税10%');
    expect(_formula(sheet, 'G27'), 'INT(G26*10%)');
    expect(_text(sheet, 'B28'), '合計');
    expect(_formula(sheet, 'G28'), 'G26+G27');
    expect(
      excel.definedNames
          .singleWhere((name) => name.name == 'EstimateGrandTotal')
          .refersTo,
      "'内訳'!\$G\$28",
    );
  });

  test('次グループがページ送りになる境界では先頭空欄を重複させない', () {
    final items = [
      ...List.generate(
        13,
        (index) => _item(
          id: 'first-$index',
          symbol: '①',
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
        symbol: '②',
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
    for (final cell in ['B5', 'C5']) {
      final style = sheet.cell(CellIndex.indexByString(cell)).cellStyle!;
      expect(style.horizontalAlignment, HorizontalAlign.Left);
      expect(style.wrap, TextWrapping.WrapText);
      expect(style.isBold, isFalse);
    }
    final locationStyle = sheet.cell(CellIndex.indexByString('B4')).cellStyle!;
    expect(locationStyle.isBold, isTrue);
    final subtotalStyle = sheet.cell(CellIndex.indexByString('B6')).cellStyle!;
    expect(subtotalStyle.horizontalAlignment, HorizontalAlign.Right);
    expect(subtotalStyle.isBold, isFalse);
    expect(sheet.getRowHeight(4), closeTo(30, 0.001));
  });

  test('記号合計・消費税・合計は正式丸め済み小計を参照する', () {
    final items = [
      _item(
        id: 'one',
        symbol: '①',
        trade: '工種',
        location: '場所',
        name: '1.5円',
        quantity: 1.5,
        unit: '式',
        unitPrice: 1,
      ),
      _item(
        id: 'two',
        symbol: '①',
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
    expect(_text(sheet, 'B8'), '');
    expect(_text(sheet, 'B9'), '① 計');
    expect(_formula(sheet, 'G9'), 'SUM(G7)');
    expect(_text(sheet, 'B10'), '消費税10%');
    expect(_formula(sheet, 'G10'), 'INT(G9*10%)');
    expect(_text(sheet, 'B11'), '合計');
    expect(_formula(sheet, 'G11'), 'G9+G10');
  });

  test('1～3グループの使用記号を自然順で最終集計名へ反映する', () {
    final cases = <(List<String>, String, int)>[
      (['①'], '① 計', 8),
      (['②', '①'], '①+② 計', 12),
      (['③', '①', '②'], '①+②+③ 計', 16),
    ];

    for (final (symbols, expectedLabel, summaryRow) in cases) {
      final items = [
        for (final (index, symbol) in symbols.indexed)
          _item(
            id: 'symbol-$symbol',
            symbol: symbol,
            trade: '工種',
            location: '場所${index + 1}',
            name: '明細${index + 1}',
            quantity: 1,
            unit: '式',
            unitPrice: 100,
          ),
      ];
      final sheet = _workbook(items)['内訳'];

      expect(_text(sheet, 'B$summaryRow'), expectedLabel);
      expect(_text(sheet, 'B${summaryRow + 1}'), '消費税10%');
      expect(_text(sheet, 'B${summaryRow + 2}'), '合計');
    }
  });

  test('明細3件では小計直後の空欄に続けて最終集計を配置する', () {
    final items = List.generate(
      3,
      (index) => _item(
        id: 'short-$index',
        symbol: '①',
        trade: '工種',
        location: '',
        name: '明細${index + 1}',
        quantity: 1,
        unit: '式',
        unitPrice: 100,
      ),
    );
    final sheet = _workbook(items)['内訳'];

    expect(sheet.printArea, 'A1:K20');
    expect(sheet.rowPageBreaks, isEmpty);
    expect(_text(sheet, 'B8'), '小計');
    expect(_text(sheet, 'B9'), '');
    expect(_text(sheet, 'B10'), '① 計');
    expect(_text(sheet, 'B11'), '消費税10%');
    expect(_text(sheet, 'B12'), '合計');
  });

  test('最後の小計後の空欄が収まらない場合は集計を次ページへ送る', () {
    final items = List.generate(
      12,
      (index) => _item(
        id: 'blank-before-summary-$index',
        symbol: '①',
        trade: '工種',
        location: '場所',
        name: '明細${index + 1}',
        quantity: 1,
        unit: '式',
        unitPrice: 100,
      ),
    );
    final excel = _workbook(items);
    final sheet = excel['内訳'];

    expect(sheet.printArea, 'A1:K40');
    expect(sheet.rowPageBreaks, [20]);
    expect(_text(sheet, 'B17'), '小計');
    expect(_text(sheet, 'B18'), '');
    expect(_text(sheet, 'B24'), '');
    expect(_text(sheet, 'B25'), '① 計');
    expect(_text(sheet, 'B26'), '消費税10%');
    expect(_text(sheet, 'B27'), '合計');
    expect(
      excel.definedNames
          .singleWhere((name) => name.name == 'EstimateGrandTotal')
          .refersTo,
      "'内訳'!\$G\$27",
    );
  });

  test('4ページ境界でも空欄に続けて集計3行を配置する', () {
    final items = List.generate(
      49,
      (index) => _item(
        id: 'four-pages-$index',
        symbol: '①',
        trade: '工種',
        location: '長期工事',
        name: '明細${index + 1}',
        quantity: 1,
        unit: '式',
        unitPrice: 100,
      ),
    );
    final sheet = _workbook(items)['内訳'];

    expect(sheet.printArea, 'A1:K80');
    expect(sheet.rowPageBreaks, [20, 40, 60]);
    expect(_text(sheet, 'B60'), '小計');
    expect(_text(sheet, 'B64'), '');
    expect(_text(sheet, 'B65'), '① 計');
    expect(_text(sheet, 'B66'), '消費税10%');
    expect(_text(sheet, 'B67'), '合計');
    expect(_text(sheet, 'K61'), 'No.4');
  });

  for (final pages in [6, 10]) {
    test('$pagesページ相当でも20行周期・改ページ・最終集計を維持する', () {
      final itemCount = pages * 15;
      final items = List.generate(
        itemCount,
        (index) => _item(
          id: 'many-$index',
          symbol: '①',
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
      final pageCount = int.parse(sheet.printArea!.split(':K').last) ~/ 20;

      expect(pageCount, greaterThanOrEqualTo(pages));
      expect(
        sheet.rowPageBreaks,
        List.generate(pageCount - 1, (index) => (index + 1) * 20),
      );
      for (var page = 0; page < pageCount; page++) {
        final firstRow = page * 20 + 1;
        expect(_text(sheet, 'C$firstRow'), '　内　訳　書');
        expect(_text(sheet, 'K$firstRow'), 'No.${page + 1}');
        expect(_text(sheet, 'A${firstRow + 2}'), '記号');
        for (var row = firstRow + 3; row <= firstRow + 18; row++) {
          expect(sheet.getRowHeight(row - 1), closeTo(30, 0.001));
        }
      }
      final grandTotal = excel.definedNames
          .singleWhere((name) => name.name == 'EstimateGrandTotal')
          .refersTo;
      expect(grandTotal, startsWith("'内訳'!\$G\$"));
      expect(_textValues(sheet).where((text) => text == '合計'), hasLength(1));
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
    expect(_text(cover, 'H16'), '');
    expect(cover.spannedItems, containsAll(['H15:M15', 'H16:M16']));
    final notesStyle = cover.cell(CellIndex.indexByString('H16')).cellStyle!;
    expect(notesStyle.wrap, TextWrapping.WrapText);
    expect(notesStyle.bottomBorder.borderStyle, BorderStyle.Thin);
    expect(notesStyle.bottomBorder.borderColorHex, 'FF000000');
    expect(_text(cover, 'O13'), '');
    expect(_formula(cover, 'H6'), 'EstimateGrandTotal');
  });
}

Excel _workbook(
  List<EstimateItem> items, {
  EstimateInfo? info,
  CompanyProfile companyProfile = const CompanyProfile(),
  int estimateDecimalPlaces = 2,
}) {
  return Excel.decodeBytes(
    buildEstimateWorkbook(
      info: info ?? _formalInfo(),
      items: items,
      companyProfile: companyProfile,
      estimateDecimalPlaces: estimateDecimalPlaces,
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
  notes: '既存備考',
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

List<String> _sheetValues(Sheet sheet) => [
  for (final row in sheet.rows)
    for (final cell in row)
      switch (cell?.value) {
        FormulaCellValue(:final formula) => '=$formula',
        final value => value.toString(),
      },
];

void _expectThinBorders(CellStyle style) {
  for (final border in [
    style.leftBorder,
    style.rightBorder,
    style.topBorder,
    style.bottomBorder,
  ]) {
    expect(border.borderStyle, BorderStyle.Thin);
    expect(border.borderColorHex, 'FF000000');
  }
}

EstimateItem _item({
  required String id,
  String symbol = '',
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
      constructionSymbol: symbol,
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
