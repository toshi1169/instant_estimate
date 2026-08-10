import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_language.dart';

class AppLocalizations {
  const AppLocalizations(this.appLanguage);

  final AppLanguage appLanguage;

  bool get isJapanese => appLanguage == AppLanguage.japanese;
  bool get isSimplifiedChinese => appLanguage == AppLanguage.simplifiedChinese;

  // English is also the safe fallback while a newly added language is being
  // translated screen by screen. This prevents Japanese text leaking into a
  // non-Japanese locale.
  bool get isEnglish => !isJapanese;

  String _pick({
    required String japanese,
    required String english,
    required String simplifiedChinese,
  }) => switch (appLanguage) {
    AppLanguage.japanese => japanese,
    AppLanguage.english => english,
    AppLanguage.simplifiedChinese => simplifiedChinese,
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLanguage.japanese);
  }

  String get appTitle => _pick(
    japanese: 'インスタント見積',
    english: 'Instant Estimate',
    simplifiedChinese: '即时估算',
  );
  String get language =>
      _pick(japanese: '言語', english: 'Language', simplifiedChinese: '语言');
  String get chooseLanguage => _pick(
    japanese: '言語を選択',
    english: 'Choose language',
    simplifiedChinese: '选择语言',
  );
  String get languageGuidance => _pick(
    japanese: 'アプリで使用する言語を選んでください。後から設定で変更できます。',
    english:
        'Select the language used in the app. You can change it later in Settings.',
    simplifiedChinese: '请选择应用中使用的语言。之后可在设置中更改。',
  );
  String get continueLabel =>
      _pick(japanese: '次へ', english: 'Continue', simplifiedChinese: '继续');
  String get japanese =>
      _pick(japanese: '日本語', english: 'Japanese', simplifiedChinese: '日语');
  String get english => 'English';
  String get simplifiedChinese => '简体中文';
  String get occupationTitle => _pick(
    japanese: '業種を選択',
    english: 'Choose occupation',
    simplifiedChinese: '选择行业',
  );
  String get occupationPrompt => _pick(
    japanese: 'あなたの主な業種を選んでください',
    english: 'Select your main occupation',
    simplifiedChinese: '请选择您的主要行业',
  );
  String get occupationGuidance => _pick(
    japanese: '表示する計算機能や見積項目の初期設定に使用します。後から設定で変更できます。',
    english:
        'This is used to prepare the initial calculators and estimate items. You can change it later in Settings.',
    simplifiedChinese: '用于设置初始计算功能和估算项目。之后可在设置中更改。',
  );
  String get startWithOccupation => _pick(
    japanese: 'この業種で始める',
    english: 'Start with this occupation',
    simplifiedChinese: '以此行业开始',
  );

  String occupation(String value) => switch (value) {
    '建築監督' => isEnglish ? 'Building supervisor' : value,
    '土木監督' => isEnglish ? 'Civil supervisor' : value,
    '建築基礎' => isEnglish ? 'Building foundations' : value,
    '外構' => isEnglish ? 'Exterior works' : value,
    '内装' => isEnglish ? 'Interior works' : value,
    '多能工' => isEnglish ? 'Multi-skilled worker' : value,
    _ => isEnglish ? 'Other' : value,
  };

  String get settings =>
      _pick(japanese: '設定', english: 'Settings', simplifiedChinese: '设置');
  String get help =>
      _pick(japanese: 'ヘルプ', english: 'Help', simplifiedChinese: '帮助');
  String get adFreePlan => _pick(
    japanese: '広告なし版（買い切り）',
    english: 'Ad-free (one-time purchase)',
    simplifiedChinese: '无广告版（一次性购买）',
  );
  String get fullPlan => _pick(
    japanese: '完全版（月額）',
    english: 'Full plan (monthly)',
    simplifiedChinese: '完整版（按月订阅）',
  );
  String get convenientCalculations => _pick(
    japanese: '便利計算一覧',
    english: 'Convenient calculations',
    simplifiedChinese: '实用计算',
  );
  String get unitConversion => _pick(
    japanese: '単位変換',
    english: 'Unit conversion',
    simplifiedChinese: '单位换算',
  );
  String get instantEstimate => _pick(
    japanese: 'インスタント見積',
    english: 'Instant estimate',
    simplifiedChinese: '即时估算',
  );
  String get unitPriceMaster => _pick(
    japanese: '単価マスタ',
    english: 'Unit price master',
    simplifiedChinese: '单价资料库',
  );
  String get productivityMaster => isEnglish ? '歩掛：BUGAKARI' : '歩掛・生産性マスタ';
  String get productivityTermTitle => isEnglish ? '歩掛：BUGAKARI' : '歩掛';
  String get productivityTermExplanation => isEnglish
      ? 'Bugakari is a Japanese construction term for the labor required per unit of completed work. It is managed together with productivity records in this app.'
      : '歩掛は、施工数量1単位あたりに必要な人工や作業量を表す建設実務用語です。';
  String get adArea =>
      _pick(japanese: '広告エリア', english: 'Ad area', simplifiedChinese: '广告区域');

  String text(String japanese) {
    if (!isEnglish) return japanese;
    return const <String, String>{
          'プライバシー': 'Privacy',
          '広告のプライバシー設定': 'Ad privacy choices',
          '広告に関する同意内容を確認・変更します':
              'Review or change your advertising consent choices.',
          '広告のプライバシー設定を開けませんでした': 'Could not open ad privacy choices.',
          '購入状況': 'Purchase status',
          '未購入': 'Not purchased',
          '購入済み': 'Purchased',
          '完全版特典で有効': 'Included with Full plan',
          '未契約': 'Not subscribed',
          '契約中': 'Active subscription',
          '便利計算一覧': 'Convenient calculations',
          '土量計算': 'Earthwork calculation',
          '掘削・搬出': 'Excavation & haul',
          '埋戻し': 'Backfill',
          '盛土': 'Embankment',
          '掘削・埋戻し・搬出土・運搬回数': 'Excavation, backfill, hauled soil and trips',
          '比重・重量計算': 'Density & weight',
          '材料と体積から重量を算出': 'Calculate weight from material and volume',
          '勾配計算': 'Slope calculation',
          '高さ・水平距離・法長・角度を算出': 'Calculate height, run, slope length and angle',
          '面積計算': 'Area calculation',
          '4辺と対角線から面積を算出': 'Calculate area from four sides and a diagonal',
          '5辺以上の面積計算': 'Polygon area (5+ sides)',
          '外周と対角線から三角形へ分割して自動合算':
              'Split into triangles and total automatically',
          '対比計算': 'Ratio calculation',
          '3つの値から残りの比率を算出': 'Calculate the remaining ratio from three values',
          '歩掛・生産性計算': 'Productivity calculation',
          '必要人工・必要日数・施工実績を計算':
              'Calculate labor, duration and actual productivity',
          '長さ・面積・重量・勾配・土量などを変換':
              'Convert length, area, weight, slope, earthwork and more',
          'クリア': 'Clear',
          '変換する種類': 'Conversion category',
          '変換する値': 'Value to convert',
          '数値を入力': 'Enter a number',
          '変換前': 'From',
          '変換後': 'To',
          '単位を入れ替える': 'Swap units',
          '尺・寸・間は、1尺＝10/33mを基準に変換します。':
              'SHAKU, SUN and KEN are traditional Japanese length units. This app converts them using 1 shaku = 10/33 m. Tap the information icon next to a unit for details.',
          '坪は、1坪＝400/121㎡（約3.30579㎡）を基準に変換します。':
              'TSUBO is a traditional Japanese area unit. This app uses 1 tsubo = 400/121 m² (about 3.30579 m²). Tap the information icon for details.',
          '俵は品目によって重量が異なります。この画面では参考値として米1俵＝60kgで変換します。':
              'The weight of HYO varies by commodity. This app uses 1 hyo of rice = 60 kg as a reference value. Tap the information icon for details.',
          '1:nは、垂直1に対する水平距離nとして変換します。':
              '1:n represents a horizontal distance of n for a vertical rise of 1.',
          '地山を基準に、ほぐし土量＝地山土量×ほぐし係数、締固め土量＝地山土量×締固め係数で変換します。係数は土質・施工条件に合わせて変更してください。':
              'Using JIYAMA as the reference, loose volume = natural volume × loosening factor, and compacted volume = natural volume × compaction factor. Adjust the factors for the soil and work conditions. Tap the information icon for details.',
          '変換結果は設定画面の小数点以下桁数と丸め方法を反映します。':
              'Conversion results use the decimal places and rounding method selected in Settings.',
          'ほぐし係数': 'Loosening factor',
          '締固め係数': 'Compaction factor',
          '見積へ': 'To estimate',
          '運搬車両': 'Transport vehicle',
          '通常車両': 'Standard vehicles',
          'クローラータイプ': 'Crawler vehicles',
          'ユーザー登録車両': 'User vehicles',
          '車両を追加': 'Add vehicle',
          '車両名': 'Vehicle name',
          '車両名を入力してください': 'Enter a vehicle name',
          '積載容量': 'Load capacity',
          '最大積載重量': 'Maximum payload',
          '登録': 'Save',
          '※積載容量は車両・土質・積載条件により調整してください。':
              '※ Adjust load capacity for the vehicle, soil and loading conditions.',
          '※ 土量変化率・積載容量・法勾配等は、土質・車両・現場条件・設計条件等により異なります。表示値は初期値・参考値として扱い、実際の条件に合わせて変更してください。':
              '※ Earthwork factors, load capacities and slope ratios vary with soil, vehicle, site and design conditions. Treat displayed values as defaults or references and adjust them to actual conditions.',
          '入力を消去': 'Clear input',
          '計算する': 'Calculate',
          '幅': 'Width',
          '深さ': 'Depth',
          '天端の長さ': 'Top length',
          '天端の幅': 'Top width',
          '盛土高さ': 'Embankment height',
          '法面あり': 'Include side slopes',
          'OFFの場合は直方体として計算': 'When off, calculate as a rectangular prism',
          '法勾配（垂直1：水平）': 'Slope ratio (vertical 1 : horizontal)',
          '任意入力': 'Custom',
          '任意の水平比': 'Custom horizontal ratio',
          '搬入時のほぐし係数': 'Loosening factor at delivery',
          '控除する構造物体積（任意）': 'Structure volume to deduct (optional)',
          '入力しない場合は0m³': '0 m³ when left blank',
          '地山掘削量': 'Bank excavation volume',
          'ほぐし土量（搬出土量）': 'Loose volume (hauled soil)',
          '必要運搬回数': 'Required trips',
          '掘削体積': 'Excavation volume',
          '埋戻し対象体積': 'Backfill target volume',
          '必要土量': 'Required soil volume',
          '余剰土量': 'Surplus soil',
          '不足土量': 'Soil shortage',
          '完成盛土量': 'Completed embankment volume',
          '締固めを考慮した必要土量': 'Required soil after compaction',
          '必要搬入土量': 'Required delivered soil',
          '端数切り上げ': 'Rounded up',
          '掘削後のほぐし土量と運搬回数を算出します。':
              'Calculate loose soil volume after excavation and required haul trips.',
          '構造物施工後に戻す土量を算出します。':
              'Calculate the soil volume to return after structure work.',
          '完成形状から必要な搬入土量を算出します。':
              'Calculate required delivered soil from the completed shape.',
          '変換結果': 'Result',
          '有効な数値を入力してください': 'Enter a valid number',
          '新しい見積': 'New estimate',
          '名称未設定の見積': 'Untitled estimate',
          '工種未設定': 'Uncategorized',
          '見積を削除': 'Delete estimate',
          '見積を複製しました': 'Estimate duplicated',
          '見積を複製できませんでした': 'Could not duplicate estimate',
          '最後の見積は削除できません': 'The last estimate cannot be deleted',
          '見積を削除しました': 'Estimate deleted',
          '見積を削除できませんでした': 'Could not delete estimate',
          '新しい見積を作成できませんでした': 'Could not create a new estimate',
          '見積を開けませんでした': 'Could not open estimate',
          '複製': 'Duplicate',
          '編集': 'Edit',
          'コピー': 'Copy',
          'カット': 'Cut',
          'ペースト': 'Paste',
          '消去': 'Clear',
          '共有': 'Share',
          'スター': 'Star',
          '関数一覧': 'Functions',
          '計算できません': 'Cannot calculate',
          '0で割ることはできません': 'Cannot divide by zero',
          '分数の入力を完了してから関数を選択してください':
              'Complete the fraction before selecting a function',
          'この関数はまだ利用できません': 'This function is not available yet',
          '先に数値を入力してください': 'Enter a number first',
          'これ以上入力できません': 'No more digits can be entered',
          '分数に変換できません': 'Cannot convert to a fraction',
          '0より大きい数値を入力': 'Enter a number greater than 0',
          '0以上の数値を入力': 'Enter a number of 0 or greater',
          'm³/回': 'm³/trip',
          '回': 'trips',
          '回（切り上げ）': 'trips (rounded up)',
          '完成形状': 'Completed shape',
          '土工': 'Earthwork',
          '掘削': 'Excavation',
          '搬出土': 'Hauled soil',
          '土砂運搬': 'Soil hauling',
          '埋戻し必要土': 'Required backfill soil',
          '余剰土': 'Surplus soil',
          '不足土': 'Soil shortage',
          '盛土必要土': 'Required embankment soil',
          '搬入土': 'Delivered soil',
          '地山掘削量 × ほぐし係数': 'Bank excavation volume × loosening factor',
          '掘削体積 − 控除する構造物体積': 'Excavation volume − structure volume deduction',
          '埋戻し対象体積 ÷ 締固め係数': 'Backfill target volume ÷ compaction factor',
          '完成盛土量 ÷ 締固め係数': 'Completed embankment volume ÷ compaction factor',
          '必要土量 × ほぐし係数': 'Required soil × loosening factor',
          '控除': 'Deduction',
          '法面形状（参考）': 'Side slope geometry (reference)',
          '片側水平距離': 'Horizontal run per side',
          '底面': 'Bottom dimensions',
          '法面なし': 'No side slopes',
          '天端': 'Top',
          '注意\n盛土高さが大きい場合は、地盤条件・法面安定・排水条件・設計図書・関係法令等を確認してください。':
              'Caution\nFor high embankments, check ground conditions, slope stability, drainage, design documents and applicable regulations.',
          '寸法・ほぐし係数・積載容量には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions, loosening factor and load capacity',
          '寸法・締固め係数には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions and compaction factor',
          '控除する構造物体積には0以上の数値を入力してください':
              'Enter a structure volume deduction of 0 or greater',
          '控除する構造物体積が掘削体積を超えています':
              'The structure volume deduction exceeds the excavation volume',
          '寸法・係数・積載容量には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions, factors and load capacity',
          '寸法・変化率・積載容量には0より大きい数値を入力してください':
              'Enter values greater than 0 for dimensions, soil factor and load capacity',
          '構造物体積には0以上の数値を入力してください': 'Enter a structure volume of 0 or greater',
          '構造物体積が掘削量を超えています':
              'The structure volume exceeds the excavation volume',
          '材料名を入力': 'Enter a material name',
          '同じ材料名が登録されています': 'A material with this name is already saved',
          '体積に0より大きい数値を入力してください': 'Enter a volume greater than 0',
          '比重に0より大きい数値を入力してください': 'Enter a density greater than 0',
          'すべての長さに0より大きい数値を入力してください':
              'Enter a number greater than 0 for every length',
          '入力した長さでは三角形を作れません': 'The entered lengths cannot form a triangle',
          '外周は5辺以上入力してください': 'Enter at least five outer sides',
          '辺数に対応する対角線を入力してください':
              'Enter the diagonals required for the number of sides',
          '広告スペース': 'Ad space',
          '広告なし版で非表示に！': 'Remove ads with Ad-free!',
          '今すぐ\nアップグレード': 'Upgrade\nnow',
          '保存': 'Save',
          '閉じる': 'Close',
          '用語説明': 'Term information',
          '完全版：件数制限なし': 'Full plan: unlimited',
          '長さ': 'Length',
          '面積': 'Area',
          '体積': 'Volume',
          '重量': 'Weight',
          '温度': 'Temperature',
          '圧力': 'Pressure',
          '勾配': 'Slope',
          '土量変換': 'Earthwork volume',
          '追加先': 'Active',
          '見積メニュー': 'Estimate menu',
          '税込': 'Tax included',
          '4辺面積計算': 'Four-sided area',
          '5辺以上面積計算': 'Polygon area (5+ sides)',
          '面積を計算': 'Calculate area',
          '計算結果': 'Result',
          '見積明細へ追加': 'Add to estimate',
          '重量を計算': 'Calculate weight',
          '材料': 'Material',
          '材料名': 'Material name',
          '材料を追加': 'Add material',
          '登録材料を削除': 'Delete saved material',
          '比重': 'Density',
          '単位': 'Unit',
          '追加': 'Add',
          '勾配・法面計算': 'Slope calculation',
          '必要人工': 'Required labor',
          '必要日数': 'Required days',
          '生産性・実績': 'Productivity & actuals',
          '工種': 'Work category',
          '施工日': 'Work date',
          '実績として保存': 'Save as actual record',
          '保存された実績はありません': 'No saved records',
          '実績を削除': 'Delete record',
          '保存上限に達しました': 'Storage limit reached',
          '見積基本情報': 'Estimate information',
          '作成日': 'Created date',
          '基本情報を保存': 'Save information',
          '単価を登録': 'Add unit price',
          '単価を編集': 'Edit unit price',
          '単価を削除': 'Delete unit price',
          '明細を追加': 'Add detail',
          '見積明細を編集': 'Edit estimate detail',
          '変更': 'Change',
          '変更を保存': 'Save changes',
          '追加して見積を開く': 'Add and open estimate',
          '計算根拠': 'Calculation details',
          '金額（数量 × 単価）': 'Amount (quantity × unit price)',
          'この内容を単価マスタへ登録': 'Save to unit price master',
          '見積明細はまだありません': 'No estimate details yet',
          '印刷する明細がありません': 'There are no details to print',
          '印刷用PDFを作成できませんでした': 'Could not create the print PDF',
          '出力する明細がありません': 'There are no details to export',
          'Excelファイルを作成できませんでした': 'Could not create the Excel file',
          'コピーする明細がありません': 'There are no details to copy',
          '見積明細をコピーできませんでした': 'Could not copy estimate details',
          '見積明細を保存できませんでした': 'Could not save estimate details',
          '同じ計算内容があります': 'Same calculation found',
          '既存明細を更新': 'Update existing detail',
          'そのまま追加': 'Add separately',
          '既存明細へ数量を加算': 'Add quantity to existing detail',
          '既存明細へ加算': 'Add to existing detail',
          '別明細として追加': 'Add as a separate detail',
          '追加先の見積を選択': 'Choose destination estimate',
          '単価マスタから選択': 'Select from unit price master',
          '単価を検索': 'Search unit prices',
          '過去の見積から選択': 'Select from past estimates',
          '過去の名称・工種・現場などを検索': 'Search past name, category or site',
          '材料と体積から重量を計算します。初期の比重は目安のため、現場条件に合わせて変更できます。':
              'Calculate weight from material and volume. Default densities are references and can be adjusted to site conditions.',
          '登録済み': 'Saved',
          'RCコンクリート': 'Reinforced concrete',
          '砕石': 'Crushed stone',
          'アスファルト': 'Asphalt',
          '砂': 'Sand',
          '山砂': 'Pit sand',
          '改良土': 'Improved soil',
          '残土': 'Surplus soil',
          '軽トラック': 'Mini truck',
          '1tトラック': '1 t truck',
          '2tダンプ': '2 t dump truck',
          '3tダンプ': '3 t dump truck',
          '4tダンプ': '4 t dump truck',
          '8tダンプ': '8 t dump truck',
          '10tダンプ': '10 t dump truck',
          '12tダンプ': '12 t dump truck',
          'セミトレーラー（土砂）': 'Semi-trailer (soil)',
          'クローラーダンプ 0.5t': '0.5 t crawler carrier',
          'クローラーダンプ 1t': '1 t crawler carrier',
          'クローラーダンプ 2t': '2 t crawler carrier',
          'クローラーダンプ 3t': '3 t crawler carrier',
          '見積明細と単価マスタへ追加しました': 'Added to the estimate and unit price master',
          '見積明細を複製し単価マスタへ追加しました':
              'Duplicated and added to the unit price master',
          '見積明細を複製しました': 'Estimate detail duplicated',
          '見積明細を更新し単価マスタへ追加しました': 'Updated and added to the unit price master',
          '見積明細を更新しました': 'Estimate detail updated',
          '数量を加算し単価マスタへ追加しました':
              'Quantity added and saved to the unit price master',
          '既存明細を更新し単価マスタへ追加しました':
              'Existing detail updated and saved to the unit price master',
          '既存の見積明細を更新しました': 'Existing estimate detail updated',
          'コピーしました': 'Copied',
          'カットしました': 'Cut',
          'ペーストしました': 'Pasted',
          '貼り付けできる計算式がありません': 'No calculation available to paste',
          '見積へ送る計算式がありません': 'No calculation available to send',
          '履歴をコピーしました': 'History entry copied',
          '計算式を編集欄へ戻しました': 'Calculation restored for editing',
          '履歴を削除しました': 'History entry deleted',
          'スターはアルティメット版で利用できます': 'Stars are available with the full plan',
          'その他': 'Other',
          '入力方法': 'Input guide',
          '高さ（V）': 'Height (V)',
          '高さ': 'Height',
          '法長（L）': 'Slope length (L)',
          '法長': 'Slope length',
          '法勾配': 'Slope ratio',
          '角度（θ）': 'Angle (θ)',
          '勾配（%）': 'Slope (%)',
          '法面積（延長1mあたり）': 'Slope area (per 1 m length)',
          '延長': 'Length',
          '4項目のうち3項目を入力すると、\n空欄の値を自動計算します。':
              'Enter three of the four values to calculate the missing value.',
          '例：A＝2、B＝5、C＝8 と入力すると、D＝20 を算出します。':
              'Example: Enter A=2, B=5 and C=8 to calculate D=20.',
          '頂点Aから対角線を引いて三角形に分割し、ヘロンの公式で面積を自動合算します。':
              'Draw diagonals from vertex A, split the polygon into triangles, and total their areas using Heron’s formula.',
          '辺を減らす': 'Remove side',
          '辺を増やす': 'Add side',
          '外周の辺': 'Outer sides',
          '頂点Aからの対角線': 'Diagonals from vertex A',
          '見積基本情報を保存しました': 'Estimate information saved',
          '見積基本情報を保存できませんでした': 'Could not save estimate information',
          '見積明細を複製できませんでした': 'Could not duplicate the estimate detail',
          '見積明細を更新できませんでした': 'Could not update the estimate detail',
          '見積明細を削除': 'Delete estimate detail',
          '見積明細を削除しました': 'Estimate detail deleted',
          '見積明細を削除できませんでした': 'Could not delete estimate detail',
          '元に戻す': 'Undo',
          '直前の追加を取り消しました': 'The last addition was undone',
          '追加を取り消せませんでした': 'Could not undo the addition',
          '税抜合計': 'Subtotal before tax',
          '消費税（10%）': 'Tax (10%)',
          '税込総額': 'Total including tax',
          '現場': 'Site',
          '宛名': 'Client',
          '備考': 'Notes',
          '名称未入力': 'Unnamed detail',
          '金額未設定': 'Amount not set',
          '数量未設定': 'Quantity not set',
          '摘要': 'Description',
          '工種小計': 'Work subtotal',
          '名称': 'Name',
          '仕様': 'Specification',
          '数量': 'Quantity',
          '単価': 'Unit price',
          '金額': 'Amount',
          '追加して続ける': 'Add and continue',
          '単価マスタ（登録なし）': 'Unit price master (empty)',
          '過去の見積（履歴なし）': 'Past estimates (none)',
          '次回から単価マスタで検索・選択できます':
              'You can search and select it from the unit price master next time',
          '名称と単価を入力すると登録できます': 'Enter a name and unit price to save it',
          '作業情報': 'Work information',
          '施工数量と基準歩掛を入力してください':
              'Enter the work quantity and standard productivity rate',
          '施工数量・作業人数・作業日数を入力してください':
              'Enter the work quantity, workers and work days',
          '一致する単価がありません': 'No matching unit prices',
          '一致する過去明細がありません': 'No matching past details',
          'キャンセル': 'Cancel',
          '削除': 'Delete',
          '登録された単価はありません\n右下の「単価を登録」から追加できます':
              'No unit prices saved\nUse "Add unit price" at the bottom right',
          '工種・名称・仕様・単位・摘要を検索':
              'Search category, name, specification, unit or description',
          '検索をクリア': 'Clear search',
          '未入力': 'Not entered',
          '詳細未入力': 'No details',
          '単価を登録しました': 'Unit price saved',
          '単価を登録できませんでした': 'Could not save unit price',
          '単価を更新しました': 'Unit price updated',
          '単価を更新できませんでした': 'Could not update unit price',
          '単価を削除しました': 'Unit price deleted',
          '単価を削除できませんでした': 'Could not delete unit price',
          '作業名称': 'Work name',
          '現場名': 'Site name',
          '施工数量': 'Work quantity',
          '土工事': 'Earthwork',
          '地業工事': 'Groundwork',
          '鉄筋工事': 'Reinforcement work',
          'コンクリート工事': 'Concrete work',
          '型枠工事': 'Formwork',
          '舗装工事': 'Pavement work',
          '外構工事': 'Exterior work',
          '内装工事': 'Interior work',
          '基準歩掛（任意・人工/単位）': 'Standard BUGAKARI (optional, labor/unit)',
          '基準歩掛（人工/単位）': 'Standard BUGAKARI (labor/unit)',
          '作業人数（任意）': 'Workers (optional)',
          '作業人数': 'Workers',
          '作業日数（任意・小数可）': 'Work days (optional, decimals allowed)',
          '作業日数（小数可）': 'Work days (decimals allowed)',
          '実作業時間（任意）': 'Actual work hours (optional)',
          '1日の作業時間（任意）': 'Hours per day (optional)',
          '施工条件・備考（任意）': 'Work conditions / notes (optional)',
          '延べ作業時間': 'Total work hours',
          '実人工': 'Actual labor',
          '実績歩掛': 'Actual BUGAKARI',
          '1人工生産性': 'Productivity per worker-day',
          '基準歩掛': 'Standard BUGAKARI',
          '差': 'Difference',
          '効率差': 'Efficiency difference',
          '歩掛・生産性マスタへ保存しました': 'Saved to the BUGAKARI & productivity master',
          '実績を保存できませんでした': 'Could not save the actual record',
          '工種・作業名称・現場名・数量・単位・人数・日数を入力してください':
              'Enter category, work name, site, quantity, unit, workers and days',
          '保存済み実績': 'Saved actual records',
          '保存上限に達しています。既存データは引き続き閲覧できます。':
              'The storage limit has been reached. Existing data remains available.',
          '平均実績歩掛': 'Average actual BUGAKARI',
          '平均生産性': 'Average productivity',
          '最小歩掛': 'Minimum BUGAKARI',
          '最大歩掛': 'Maximum BUGAKARI',
          '名称（必須）': 'Name (required)',
          '名称を入力してください': 'Enter a name',
          '数値を入力してください': 'Enter a number',
          '単価マスタへ登録': 'Save to unit price master',
          '入力': 'Enter',
          '自動計算': 'Calculated automatically',
          '計算する1項目を空欄にしてください': 'Leave one value blank to calculate it',
          '4項目のうち3項目を入力してください': 'Enter three of the four values',
          '0より大きい数値を入力してください': 'Enter a number greater than 0',
          'この値では計算できません': 'These values cannot be calculated',
          '距離の項目と1つ以上組み合わせて入力してください': 'Select a distance and one other value',
          '勾配の入力項目を選択してください': 'Select a slope input',
          '高さは0より大きい数値を入力してください': 'Enter a height greater than 0',
          '法長は0より大きい数値を入力してください': 'Enter a slope length greater than 0',
          '水平距離は0より大きい数値を入力してください':
              'Enter a horizontal distance greater than 0',
          '法長は高さより大きい数値を入力してください':
              'Enter a slope length greater than the height',
          '法長は水平距離より大きい数値を入力してください':
              'Enter a slope length greater than the horizontal distance',
          '法勾配は0より大きい数値を入力してください': 'Enter a slope ratio greater than 0',
          '入力値は0以上の数値を入力してください': 'Enter a value of 0 or greater',
          '勾配比は0より大きい数値を入力してください': 'Enter a gradient ratio greater than 0',
          '角度は0度以上90度未満で入力してください':
              'Enter an angle from 0 degrees up to but not including 90 degrees',
          '計算に使う2つの入力欄を順にタップし、数値を入力してください。残りの値は自動計算されます。法勾配 1:n は、縦1に対する水平距離nを表します。':
              'Tap two input fields in order and enter their values. The remaining values are calculated automatically. A slope ratio of 1:n means a horizontal distance of n for a vertical rise of 1.',
          '入力項目（選択した2つから自動計算）':
              'Inputs (calculated automatically from two selected values)',
          '水平距離（H）': 'Horizontal distance (H)',
          '水平距離': 'Horizontal distance',
          '法面積（延長分）': 'Slope area (total length)',
          '見積名': 'Estimate name',
          '見積番号': 'Estimate number',
          '例：○○邸 外構工事': 'Example: Smith Residence exterior works',
          '履歴の並び順': 'History order',
          '昇順': 'Ascending',
          '降順': 'Descending',
          '計算式・解を検索': 'Search expressions and results',
          '検索を消去': 'Clear search',
          '一致する履歴がありません': 'No matching history',
          '計算履歴はまだありません': 'No calculation history yet',
          '履歴メニュー': 'History menu',
          '小数': 'Decimal',
          '仮分数': 'Improper fraction',
          '帯分数': 'Mixed fraction',
          '履歴を削除': 'Delete history',
          'この計算履歴を削除しますか？': 'Delete this calculation history?',
          '見積を開く': 'Open estimate',
          '見積へ送る': 'Send to estimate',
          '送信内容': 'Content to send',
          '送信先': 'Destination',
          '送信内容の確認': 'Confirm content',
          '次へ': 'Next',
          '式': 'Expression',
          '解': 'Result',
          '式＋解': 'Expression + result',
          'DEG（度）': 'DEG (degrees)',
          'RAD（ラジアン）': 'RAD (radians)',
          '四角形を対角線で2つの三角形に分け、ヘロンの公式で面積を求めます。':
              'Split the quadrilateral into two triangles along a diagonal and calculate the area using Heron\'s formula.',
          '辺A': 'Side A',
          '辺B': 'Side B',
          '辺C': 'Side C',
          '辺D': 'Side D',
          '対角線': 'Diagonal',
          '初期参考値 1.25（現場条件に合わせて変更可能）':
              'Initial reference value: 1.25 (adjust to site conditions)',
          '初期参考値 0.90（現場条件に合わせて変更可能）':
              'Initial reference value: 0.90 (adjust to site conditions)',
          '例：1 : 1.7 の場合は 1.7': 'Example: enter 1.7 for 1 : 1.7',
          '※候補は参考値です。設計図書や現場条件に合わせて確認・変更してください。':
              'Presets are reference values. Check and adjust them to the design documents and site conditions.',
          '初期参考値 0.90': 'Initial reference value: 0.90',
          '初期参考値 1.25': 'Initial reference value: 1.25',
        }[japanese] ??
        japanese;
  }

  String itemCount(int count) => isEnglish ? '$count items' : '$count件';
  String productivityUnit(String value) {
    if (!isEnglish) return value;
    return switch (value) {
      '本' => 'pcs',
      '枚' => 'sheets',
      '個' => 'items',
      '箇所' => 'locations',
      '組' => 'sets',
      '式' => 'lump sum',
      _ => text(value),
    };
  }

  String itemCountWithLimit(int count, int limit) =>
      isEnglish ? '$count / $limit items' : '$count / $limit件';
  String currentSaveLimit(int limit) =>
      isEnglish ? 'Current storage limit: $limit items' : '現在の保存上限：$limit件';
  String productivityLimitMessage(int limit) => isEnglish
      ? 'The current plan can save up to $limit records. The full plan can save up to 100 records.'
      : '現在のプランでは最大$limit件まで保存できます。完全版では100件まで保存できます。';
  String get freeEstimateLimit => isEnglish
      ? 'The free plan can store up to 5 estimates'
      : '無料版では見積を5件まで保存できます';

  String specializedUnit(String id, String japanese) {
    if (!isEnglish) return japanese;
    return switch (id) {
      'shaku' => '尺：SHAKU',
      'sun' => '寸：SUN',
      'ken' => '間：KEN',
      'tsubo' => '坪：TSUBO',
      'hyo' => '俵：HYO',
      'natural' => '地山：JIYAMA',
      'loose' => 'ほぐし：HOGUSHI',
      'compacted' => '締固め：SHIMEKATAME',
      _ => japanese,
    };
  }

  bool isSpecializedUnit(String id) => const {
    'shaku',
    'sun',
    'ken',
    'tsubo',
    'hyo',
    'natural',
    'loose',
    'compacted',
  }.contains(id);

  String get unitInformation => isEnglish ? 'Unit information' : '単位の説明';

  String get showUnitInformation =>
      isEnglish ? 'Show unit information' : '単位の説明を表示';

  String specializedUnitExplanation(String id) {
    if (isEnglish) {
      return switch (id) {
        'shaku' =>
          '尺 (SHAKU) is a traditional Japanese unit of length. This app uses 1 shaku = 10/33 m (about 0.30303 m).',
        'sun' =>
          '寸 (SUN) is a traditional Japanese unit of length. This app uses 1 sun = 1/10 shaku = 1/33 m (about 0.030303 m).',
        'ken' =>
          '間 (KEN) is a traditional Japanese unit of length. This app uses 1 ken = 6 shaku = 20/11 m (about 1.81818 m).',
        'tsubo' =>
          '坪 (TSUBO) is a traditional Japanese unit of area. This app uses 1 tsubo = 400/121 m² (about 3.30579 m²).',
        'hyo' =>
          '俵 (HYO) is a traditional Japanese unit whose weight varies by commodity. This app uses 1 hyo of rice = 60 kg as a reference value.',
        'natural' =>
          '地山 (JIYAMA) means soil in its natural condition before excavation. It is the reference volume for earthwork conversion.',
        'loose' =>
          'ほぐし (HOGUSHI) means the expanded, loose volume after excavation. Loose volume = natural volume × loosening factor.',
        'compacted' =>
          '締固め (SHIMEKATAME) means the volume after compaction. Compacted volume = natural volume × compaction factor.',
        _ => '',
      };
    }
    return switch (id) {
      'shaku' => '尺は日本の伝統的な長さの単位です。このアプリでは1尺＝10/33m（約0.30303m）で換算します。',
      'sun' => '寸は日本の伝統的な長さの単位です。1寸＝1/10尺＝1/33m（約0.030303m）で換算します。',
      'ken' => '間は日本の伝統的な長さの単位です。1間＝6尺＝20/11m（約1.81818m）で換算します。',
      'tsubo' => '坪は日本の伝統的な面積の単位です。1坪＝400/121㎡（約3.30579㎡）で換算します。',
      'hyo' => '俵は品目によって重量が異なる日本の伝統的な単位です。このアプリでは参考値として米1俵＝60kgで換算します。',
      'natural' => '地山は、掘削前の自然な状態の土量です。土量変換の基準として使用します。',
      'loose' => 'ほぐしは、掘削後に膨らんだ土量です。ほぐし土量＝地山土量×ほぐし係数で求めます。',
      'compacted' => '締固めは、締め固め後の土量です。締固め土量＝地山土量×締固め係数で求めます。',
      _ => '',
    };
  }

  String estimateDetails(int count) =>
      isEnglish ? '$count details' : '$count明細';

  String deleteEstimateQuestion(String name) => isEnglish
      ? 'Delete "$name"?\nAll details in this estimate will also be deleted.'
      : '「$name」を削除しますか？\n含まれる明細もすべて削除されます。';

  String get displayAndCalculation =>
      isEnglish ? 'Display & calculation' : '表示・計算';
  String get theme => isEnglish ? 'Theme' : 'テーマ';
  String get systemTheme => isEnglish ? 'Follow device setting' : '端末に合わせる';
  String get whiteTheme => isEnglish ? 'White' : '白';
  String get grayTheme => isEnglish ? 'Gray' : 'グレー';
  String get blackTheme => isEnglish ? 'Black' : '黒';
  String get decimalPlaces => isEnglish ? 'Decimal places' : '小数点以下の表示桁数';
  String digits(int count) => isEnglish ? '$count places' : '$count桁';
  String get roundingMethod => isEnglish ? 'Rounding method' : '丸め方法';
  String get roundHalfUp => isEnglish ? 'Round half up' : '四捨五入';
  String get roundUp => isEnglish ? 'Round up' : '切上げ';
  String get roundDown => isEnglish ? 'Round down' : '切捨て';
  String get angleUnit => isEnglish ? 'Angle unit' : '角度単位';
  String get degrees => isEnglish ? 'Degrees (DEG)' : '度（DEG）';
  String get radians => isEnglish ? 'Radians (RAD)' : 'ラジアン（RAD）';
  String get calculationHistory => isEnglish ? 'Calculation history' : '計算履歴';
  String get ascendingHistory =>
      isEnglish ? 'Show history ascending' : '履歴を昇順で表示';
  String get ascendingOldest =>
      isEnglish ? 'Ascending (oldest first)' : '昇順（古い順）';
  String get descendingNewest =>
      isEnglish ? 'Descending (newest first)' : '降順（新しい順）';
  String get confirmHistoryDeletion =>
      isEnglish ? 'Confirm before deleting history' : '履歴削除時に確認する';
  String get clearAllHistory => isEnglish ? 'Delete all history' : '履歴をすべて削除';
  String get clearHistoryQuestion => isEnglish
      ? 'Delete all calculation history except starred entries?'
      : 'スター付き以外の計算履歴をすべて削除します。よろしいですか？';
  String get cancel => isEnglish ? 'Cancel' : 'キャンセル';
  String get delete => isEnglish ? 'Delete' : '削除';
  String get historyCleared =>
      isEnglish ? 'Calculation history was deleted' : '計算履歴をすべて削除しました';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'ja', 'en', 'zh'}.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final language = switch (locale.languageCode) {
      'en' => AppLanguage.english,
      'zh' => AppLanguage.simplifiedChinese,
      _ => AppLanguage.japanese,
    };
    return SynchronousFuture(AppLocalizations(language));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
