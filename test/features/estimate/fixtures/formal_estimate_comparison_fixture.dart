import 'package:instant_estimate/features/estimate/domain/estimate_info.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item.dart';
import 'package:instant_estimate/features/estimate/domain/estimate_item_draft.dart';
import 'package:instant_estimate/features/settings/domain/app_settings.dart';
import 'package:instant_estimate/features/settings/domain/company_profile.dart';

final formalEstimateComparisonInfo = EstimateInfo(
  id: 'formal-estimate-comparison',
  estimateName: '松本邸 外構改修工事',
  siteName: '旧現場名（正式帳票非表示）',
  clientName: '旧宛名（正式帳票非表示）',
  createdDate: DateTime(2026, 8, 19),
  estimateNumber: '旧番号（正式帳票非表示）',
  notes: '施工条件および現地状況により協議のうえ変更する場合があります。',
  proviso: '外構改修工事一式として',
  validityPeriod: '2026年9月30日',
  constructionPeriod: '契約後30日以内',
  paymentTerms: '工事完了後30日以内',
);

const formalEstimateComparisonCompanyProfile = CompanyProfile(
  companyName: '有限会社 松本建設',
  representativeName: '代表取締役 松本 太郎',
  postalCode: '〒123-4567',
  addressLine1: '埼玉県さいたま市中央区一丁目二番三号',
  addressLine2: '松本建設ビル2階',
  phoneNumber: '048-123-4567',
  displayOrder: [
    CompanyProfileSection.companyName,
    CompanyProfileSection.postalCode,
    CompanyProfileSection.addressLine1,
    CompanyProfileSection.representativeName,
    CompanyProfileSection.addressLine2,
    CompanyProfileSection.phoneNumber,
  ],
  excelVisibleSections: [
    CompanyProfileSection.companyName,
    CompanyProfileSection.postalCode,
    CompanyProfileSection.addressLine1,
    CompanyProfileSection.representativeName,
    CompanyProfileSection.addressLine2,
  ],
);

const formalEstimateComparisonSettings = AppSettings(
  estimateDecimalPlaces: 2,
  companyProfile: formalEstimateComparisonCompanyProfile,
);

List<EstimateItem> buildFormalEstimateComparisonItems() => [
  _item(
    'north-1',
    symbol: '①',
    location: '西・北面　隣地側　土留CB',
    name: '根伐り・砕石地業・組鉄筋\nベースコンクリート打設',
    specification: 'ベース t=120 w=450\n鉄筋 長辺2D-10 短辺D10@400',
    quantity: 12.6,
    unitPrice: 12345,
    description: '既存構造物との取り合いを含む',
  ),
  _item(
    'north-2',
    symbol: '①',
    location: '西・北面　隣地側　土留CB',
    name: '残土処分',
    specification: '場外搬出処分',
    quantity: 1,
    unitPrice: 1000,
    description: '運搬費を含む',
  ),
  _item(
    'north-3',
    symbol: '①',
    location: '西・北面　隣地側　土留CB',
    name: '化粧ブロック積み',
    specification: 'C種 t=120',
    quantity: 37,
    unitPrice: 1100,
    description: '標準色',
  ),
  _item(
    'north-4',
    symbol: '①',
    location: '西・北面　隣地側　土留CB',
    name: '端数確認A',
    specification: '行単位四捨五入',
    quantity: 2.5,
    unitPrice: 1,
    description: '2.5円は3円',
  ),
  _item(
    'north-5',
    symbol: '①',
    location: '西・北面　隣地側　土留CB',
    name: '端数確認B',
    specification: '小数数量',
    quantity: 3.333,
    unitPrice: 300,
    description: '999.9円は1,000円',
  ),
  _item(
    'north-6',
    symbol: '①',
    location: '西・北面　隣地側　土留CB',
    name: '養生・清掃',
    specification: '一式',
    quantity: 10,
    unitPrice: 5000,
    description: '作業完了時',
  ),
  for (var index = 0; index < 7; index++)
    _item(
      'south-${index + 1}',
      symbol: '②',
      location: '南　道路側　土留めブロック工事',
      name: '道路側工事項目 ${index + 1}',
      specification: '施工仕様 ${index + 1}',
      quantity: 37.0 + index,
      unitPrice: 18900.0 + index * 250,
      description: '道路側摘要 ${index + 1}',
    ),
];

EstimateItem _item(
  String id, {
  required String symbol,
  required String location,
  required String name,
  required String specification,
  required double quantity,
  required double unitPrice,
  required String description,
}) => EstimateItem.fromDraft(
  EstimateItemDraft(
    constructionSymbol: symbol,
    constructionLocation: location,
    trade: '正式帳票には表示しない工種',
    name: name,
    specification: specification,
    quantity: quantity,
    unit: 'm²',
    unitPrice: unitPrice,
    description: description,
  ),
  id: id,
  createdAt: DateTime(2026, 8, 19),
);
