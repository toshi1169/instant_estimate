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

  String choose({
    required String japanese,
    required String english,
    required String simplifiedChinese,
  }) => _pick(
    japanese: japanese,
    english: english,
    simplifiedChinese: simplifiedChinese,
  );

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
    '建築監督' => _pick(
      japanese: value,
      english: 'Building supervisor',
      simplifiedChinese: '建筑监理',
    ),
    '土木監督' => _pick(
      japanese: value,
      english: 'Civil supervisor',
      simplifiedChinese: '土木监理',
    ),
    '建築基礎' => _pick(
      japanese: value,
      english: 'Building foundations',
      simplifiedChinese: '建筑基础',
    ),
    '外構' => _pick(
      japanese: value,
      english: 'Exterior works',
      simplifiedChinese: '室外工程',
    ),
    '内装' => _pick(
      japanese: value,
      english: 'Interior works',
      simplifiedChinese: '室内装修',
    ),
    '多能工' => _pick(
      japanese: value,
      english: 'Multi-skilled worker',
      simplifiedChinese: '多技能工',
    ),
    _ => _pick(japanese: value, english: 'Other', simplifiedChinese: '其他'),
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
  String get productivityMaster => _pick(
    japanese: '歩掛・生産性マスタ',
    english: '歩掛：BUGAKARI',
    simplifiedChinese: '步挂：BUGAKARI・生产率资料库',
  );
  String get productivityTermTitle => _pick(
    japanese: '歩掛',
    english: '歩掛：BUGAKARI',
    simplifiedChinese: '步挂：BUGAKARI',
  );
  String get productivityTermExplanation => _pick(
    japanese: '歩掛は、施工数量1単位あたりに必要な人工や作業量を表す建設実務用語です。',
    english:
        'Bugakari is a Japanese construction term for the labor required per unit of completed work. It is managed together with productivity records in this app.',
    simplifiedChinese:
        '“步挂（BUGAKARI）”是日本建筑行业术语，表示每单位完工数量所需的人工或工作量。本应用将其与生产率记录一并管理。',
  );
  String get adArea =>
      _pick(japanese: '広告エリア', english: 'Ad area', simplifiedChinese: '广告区域');

  String text(String japanese) {
    if (isJapanese) return japanese;
    if (isSimplifiedChinese) {
      final translated = const <String, String>{
        '便利計算一覧': '实用计算',
        '土量計算': '土方计算',
        '掘削・搬出': '开挖・外运',
        '埋戻し': '回填',
        '盛土': '填土',
        '比重・重量計算': '密度・重量计算',
        '勾配計算': '坡度计算',
        '面積計算': '面积计算',
        '5辺以上の面積計算': '五边以上面积计算',
        '対比計算': '比例计算',
        '歩掛・生産性計算': '步挂・生产率计算',
        'クリア': '清除',
        '見積へ': '添加到估算',
        'コピー': '复制',
        'カット': '剪切',
        'ペースト': '粘贴',
        '消去': '清除',
        '共有': '分享',
        '編集': '编辑',
        '削除': '删除',
        'スター': '星标',
        '関数一覧': '函数列表',
        '計算履歴': '计算历史',
        '履歴の並び順': '历史排序',
        '昇順': '升序',
        '降順': '降序',
        '計算式・解を検索': '搜索算式和结果',
        '検索を消去': '清除搜索',
        '検索をクリア': '清除搜索',
        '一致する履歴がありません': '没有匹配的历史记录',
        '計算履歴はまだありません': '暂无计算历史',
        '履歴メニュー': '历史菜单',
        '履歴を削除': '删除历史记录',
        'この計算履歴を削除しますか？': '要删除这条计算历史吗？',
        '小数': '小数',
        '仮分数': '假分数',
        '帯分数': '带分数',
        '見積へ送る': '发送到估算',
        '見積を開く': '打开估算',
        '送信内容': '发送内容',
        '送信先': '发送位置',
        '送信内容の確認': '确认发送内容',
        '次へ': '下一步',
        '式': '算式',
        '解': '结果',
        '式＋解': '算式＋结果',
        '角度単位': '角度单位',
        'DEG（度）': 'DEG（度）',
        'RAD（ラジアン）': 'RAD（弧度）',
        '新しい見積': '新建估算',
        '名称未設定の見積': '未命名估算',
        '見積メニュー': '估算菜单',
        '見積基本情報': '估算基本信息',
        '見積名': '估算名称',
        '見積番号': '估算编号',
        '現場': '现场',
        '現場名': '现场名称',
        '宛名': '客户名称',
        '作成日': '创建日期',
        '備考': '备注',
        '基本情報を保存': '保存基本信息',
        '見積明細はまだありません': '暂无估算明细',
        '明細を追加': '添加明细',
        '追加先': '添加位置',
        '追加先の見積を選択': '选择要添加到的估算',
        '変更': '更改',
        '変更を保存': '保存更改',
        '工種': '工种',
        '名称': '名称',
        '名称（必須）': '名称（必填）',
        '名称を入力してください': '请输入名称',
        '名称未入力': '未输入名称',
        '仕様': '规格',
        '数量': '数量',
        '単位': '单位',
        '単価': '单价',
        '金額（数量 × 単価）': '金额（数量 × 单价）',
        '摘要': '摘要',
        '計算根拠': '计算依据',
        '詳細未入力': '未输入详细信息',
        '金額未設定': '未设置金额',
        '工種小計': '工种小计',
        '税抜合計': '未税合计',
        '消費税（10%）': '消费税（10%）',
        '税込': '含税',
        '税込総額': '含税总额',
        '工種・名称・仕様・単位・摘要を検索': '搜索工种、名称、规格、单位或摘要',
        '過去の名称・工種・現場などを検索': '搜索历史名称、工种或现场',
        '単価を検索': '搜索单价',
        '単価マスタから選択': '从单价资料库选择',
        '単価マスタ（登録なし）': '单价资料库（无记录）',
        '過去の見積から選択': '从历史估算选择',
        '過去の見積（履歴なし）': '历史估算（无记录）',
        '一致する単価がありません': '没有匹配的单价',
        '一致する過去明細がありません': '没有匹配的历史明细',
        'この内容を単価マスタへ登録': '将此内容保存到单价资料库',
        '追加して見積を開く': '添加并打开估算',
        '同じ計算内容があります': '已存在相同的计算内容',
        'そのまま追加': '仍然添加',
        '既存明細を更新': '更新现有明细',
        '既存明細へ数量を加算': '数量加到现有明细',
        '既存明細へ加算': '加到现有明细',
        '別明細として追加': '作为新明细添加',
        '複製': '复制明细',
        'キャンセル': '取消',
        '未入力': '未输入',
        '未購入': '未购买',
        '購入済み': '已购买',
        '未契約': '未订阅',
        '契約中': '订阅中',
        '完全版特典で有効': '完整版权益已启用',
        '完全版：件数制限なし': '完整版：无数量限制',
        '掘削・埋戻し・搬出土・運搬回数': '开挖、回填、外运土方和运输次数',
        '材料と体積から重量を算出': '根据材料和体积计算重量',
        '高さ・水平距離・法長・角度を算出': '计算高度、水平距离、边坡长度和角度',
        '4辺と対角線から面積を算出': '根据四边和对角线计算面积',
        '外周と対角線から三角形へ分割して自動合算': '根据外周边和对角线分割为三角形并自动合计',
        '3つの値から残りの比率を算出': '根据三个数值计算剩余比例',
        '必要人工・必要日数・施工実績を計算': '计算所需人工、所需天数和施工实际记录',
        '長さ・面積・重量・勾配・土量などを変換': '换算长度、面积、重量、坡度和土方等单位',
        '体積': '体积',
        '同じ材料名が登録されています': '已登记相同的材料名称',
        '材料': '材料',
        '材料と体積から重量を計算します。初期の比重は目安のため、現場条件に合わせて変更できます。':
            '根据材料和体积计算重量。初始密度仅供参考，可按现场条件修改。',
        '材料を追加': '添加材料',
        '材料名': '材料名称',
        '材料名を入力': '请输入材料名称',
        '比重': '密度',
        '登録材料を削除': '删除已登记材料',
        '見積明細へ追加': '添加到估算明细',
        '計算結果': '计算结果',
        '追加': '添加',
        '重量を計算': '计算重量',
        'RCコンクリート': '钢筋混凝土',
        '砕石': '碎石',
        'アスファルト': '沥青',
        '砂': '砂',
        '山砂': '山砂',
        '改良土': '改良土',
        '残土': '剩余土',
        '体積に0より大きい数値を入力してください': '请输入大于0的体积',
        '比重に0より大きい数値を入力してください': '请输入大于0的密度',
        '材料データを読み込めません': '无法读取材料数据',
        '材料の比重が正しくありません': '材料密度无效',
        '入力方法': '输入方法',
        '入力項目（選択した2つから自動計算）': '输入项目（根据所选两项自动计算）',
        '勾配': '坡度',
        '勾配・法面計算': '坡度・边坡计算',
        '勾配（%）': '坡度（%）',
        '延長': '延伸长度',
        '水平距離': '水平距离',
        '水平距離（H）': '水平距离（H）',
        '法勾配': '边坡坡比',
        '法長': '边坡长度',
        '法長（L）': '边坡长度（L）',
        '法面積（延長1mあたり）': '边坡面积（每延米）',
        '法面積（延長分）': '边坡面积（总延长）',
        '角度（θ）': '角度（θ）',
        '計算に使う2つの入力欄を順にタップし、数値を入力してください。': '请依次点击两个用于计算的输入框并输入数值。',
        '高さ': '高度',
        '高さ（V）': '高度（V）',
        '法長は高さより大きい数値を入力してください': '请输入大于高度的边坡长度',
        '法長は水平距離より大きい数値を入力してください': '请输入大于水平距离的边坡长度',
        '法勾配は0より大きい数値を入力してください': '请输入大于0的边坡坡比',
        '水平距離は0より大きい数値を入力してください': '请输入大于0的水平距离',
        '入力値は0以上の数値を入力してください': '请输入大于或等于0的数值',
        '勾配比は0より大きい数値を入力してください': '请输入大于0的坡度比',
        '角度は0度以上90度未満で入力してください': '请输入0度以上且小于90度的角度',
        '高さは0より大きい数値を入力してください': '请输入大于0的高度',
        '水平距離と高さに0より大きい数値を入力してください': '请输入大于0的水平距离和高度',
        '水平距離と法長に0より大きい数値を入力してください': '请输入大于0的水平距离和边坡长度',
        '高さと法長に0より大きい数値を入力してください': '请输入大于0的高度和边坡长度',
        '4辺面積計算': '四边形面积计算',
        '5辺以上面積計算': '五边以上面积计算',
        '四角形を対角線で2つの三角形に分け、ヘロンの公式で面積を求めます。': '用对角线将四边形分成两个三角形，并使用海伦公式计算面积。',
        '外周の辺': '外周边长',
        '対角線': '对角线',
        '辺A': '边A',
        '辺B': '边B',
        '辺C': '边C',
        '辺D': '边D',
        '辺を増やす': '增加边',
        '辺を減らす': '减少边',
        '面積を計算': '计算面积',
        '頂点Aからの対角線': '从顶点A引出的对角线',
        '頂点Aから対角線を引いて三角形に分割し、ヘロンの公式で面積を自動合算します。':
            '从顶点A引出对角线，将多边形分成三角形，并用海伦公式自动合计面积。',
        'すべての長さに0より大きい数値を入力してください': '请为所有长度输入大于0的数值',
        '入力した長さでは三角形を作れません': '输入的长度无法构成三角形',
        '外周は5辺以上入力してください': '请输入至少5条外周边',
        '辺数に対応する対角線を入力してください': '请输入与边数对应的对角线',
        '4項目のうち3項目を入力すると、\n空欄の値を自動計算します。': '输入4个项目中的3个，\n即可自动计算空白值。',
        '例：A＝2、B＝5、C＝8 と入力すると、D＝20 を算出します。': '例：输入A＝2、B＝5、C＝8，将计算D＝20。',
        '入力': '输入',
        '自動計算': '自动计算',
        '1人工生産性': '每人工生产率',
        '作業名称': '作业名称',
        '作業情報': '作业信息',
        '基準歩掛（任意・人工/単位）': '基准步挂（BUGAKARI）（可选、人工/单位）',
        '基準歩掛（人工/単位）': '基准步挂（BUGAKARI）（人工/单位）',
        '作業人数（任意）': '作业人数（可选）',
        '作業人数': '作业人数',
        '作業日数（任意・小数可）': '作业天数（可选、可输入小数）',
        '作業日数（小数可）': '作业天数（可输入小数）',
        '実作業時間（任意）': '实际作业时间（可选）',
        '1日の作業時間（任意）': '每日作业时间（可选）',
        '効率差': '效率差',
        '基準歩掛': '基准步挂（BUGAKARI）',
        '実人工': '实际人工',
        '実績として保存': '保存为实际记录',
        '実績を保存できませんでした': '无法保存实际记录',
        '実績歩掛': '实际步挂（BUGAKARI）',
        '工種・作業名称・現場名・数量・単位・人数・日数を入力してください': '请输入工种、作业名称、现场名称、数量、单位、人数和天数',
        '差': '差值',
        '延べ作業時間': '累计作业时间',
        '必要人工': '所需人工',
        '必要日数': '所需天数',
        '施工数量': '施工数量',
        '施工数量と基準歩掛を入力してください': '请输入施工数量和基准步挂（BUGAKARI）',
        '施工数量・作業人数・作業日数を入力してください': '请输入施工数量、作业人数和作业天数',
        '施工日': '施工日期',
        '施工条件・備考（任意）': '施工条件・备注（可选）',
        '歩掛・生産性マスタへ保存しました': '已保存到步挂（BUGAKARI）・生产率资料库',
        '生産性・実績': '生产率・实际记录',
        '土工事': '土方工程',
        '地業工事': '地基工程',
        '鉄筋工事': '钢筋工程',
        'コンクリート工事': '混凝土工程',
        '型枠工事': '模板工程',
        '舗装工事': '铺装工程',
        '外構工事': '室外工程',
        '内装工事': '室内装修工程',
        'ほぐし係数': '松散系数',
        '単位を入れ替える': '交换单位',
        '変換する値': '换算数值',
        '変換する種類': '换算类别',
        '変換前': '换算前',
        '変換後': '换算后',
        '数値を入力': '请输入数值',
        '締固め係数': '压实系数',
        '長さ': '长度',
        '面積': '面积',
        '重量': '重量',
        '温度': '温度',
        '圧力': '压力',
        '土量変換': '土方状态换算',
        '変換結果': '换算结果',
        '変換結果は設定画面の小数点以下桁数と丸め方法を反映します。': '换算结果会采用设置页面中的小数位数和舍入方式。',
        '尺・寸・間は、1尺＝10/33mを基準に変換します。': '尺、寸、间以1尺＝10/33米为基准进行换算。',
        '坪は、1坪＝400/121㎡（約3.30579㎡）を基準に変換します。':
            '坪以1坪＝400/121平方米（约3.30579平方米）为基准进行换算。',
        '俵は品目によって重量が異なります。この画面では参考値として米1俵＝60kgで変換します。':
            '俵的重量会因品目而异。本页面以1俵大米＝60公斤作为参考值进行换算。',
        '1:nは、垂直1に対する水平距離nとして変換します。': '1:n表示垂直高度为1时，水平距离为n。',
        '地山を基準に、ほぐし土量＝地山土量×ほぐし係数、締固め土量＝地山土量×締固め係数で変換します。係数は土質・施工条件に合わせて変更してください。':
            '以原状土为基准：松散土方＝原状土方×松散系数，压实土方＝原状土方×压实系数。请根据土质和施工条件调整系数。',
        '掘削後のほぐし土量と運搬回数を算出します。': '计算开挖后的松散土方和运输次数。',
        '構造物施工後に戻す土量を算出します。': '计算结构物施工后需要回填的土方。',
        '完成形状から必要な搬入土量を算出します。': '根据完成形状计算所需运入土方。',
        '幅': '宽度',
        '深さ': '深度',
        '掘削': '开挖',
        '掘削体積': '开挖体积',
        '地山掘削量': '原状土开挖量',
        'ほぐし土量（搬出土量）': '松散土方（外运土方）',
        '必要運搬回数': '所需运输次数',
        '運搬車両': '运输车辆',
        '積載容量': '装载容量',
        '最大積載重量': '最大载重量',
        '通常車両': '普通车辆',
        'クローラータイプ': '履带式车辆',
        'ユーザー登録車両': '用户登记车辆',
        '車両を追加': '添加车辆',
        '車両名': '车辆名称',
        '軽トラック': '轻型卡车',
        '1tトラック': '1吨卡车',
        '2tダンプ': '2吨自卸车',
        '3tダンプ': '3吨自卸车',
        '4tダンプ': '4吨自卸车',
        '8tダンプ': '8吨自卸车',
        '10tダンプ': '10吨自卸车',
        '12tダンプ': '12吨自卸车',
        'セミトレーラー（土砂）': '半挂车（土砂）',
        'クローラーダンプ 0.5t': '履带式自卸车 0.5吨',
        'クローラーダンプ 1t': '履带式自卸车 1吨',
        'クローラーダンプ 2t': '履带式自卸车 2吨',
        'クローラーダンプ 3t': '履带式自卸车 3吨',
        'm³/回': '立方米/次',
        '回': '次',
        '回（切り上げ）': '次（向上取整）',
        '端数切り上げ': '尾数向上取整',
        '控除': '扣除',
        '控除する構造物体積（任意）': '扣除的结构物体积（可选）',
        '埋戻し対象体積': '回填对象体积',
        '必要土量': '所需土方',
        '埋戻し必要土': '所需回填土',
        '余剰土': '多余土方',
        '余剰土量': '多余土方量',
        '不足土': '不足土方',
        '不足土量': '不足土方量',
        '盛土高さ': '填土高度',
        '完成盛土量': '完成填土量',
        '締固めを考慮した必要土量': '考虑压实后的所需土方',
        '必要搬入土量': '所需运入土方',
        '盛土必要土': '所需填土',
        '搬入土': '运入土方',
        '搬出土': '外运土方',
        '土砂運搬': '土方运输',
        '法面あり': '有边坡',
        '法面なし': '无边坡',
        '法勾配（垂直1：水平）': '边坡坡比（垂直1：水平）',
        '任意の水平比': '自定义水平比',
        '片側水平距離': '单侧水平距离',
        '法面形状（参考）': '边坡形状（参考）',
        '完成形状': '完成形状',
        '天端': '顶面',
        '天端の幅': '顶面宽度',
        '天端の長さ': '顶面长度',
        '底面': '底面',
        '搬入時のほぐし係数': '运入时的松散系数',
        '初期参考値 1.25': '初始参考值 1.25',
        '初期参考値 0.90': '初始参考值 0.90',
        '初期参考値 1.25（現場条件に合わせて変更可能）': '初始参考值1.25（可按现场条件修改）',
        '初期参考値 0.90（現場条件に合わせて変更可能）': '初始参考值0.90（可按现场条件修改）',
        '掘削体積 − 控除する構造物体積': '开挖体积－扣除的结构物体积',
        '地山掘削量 × ほぐし係数': '原状土开挖量×松散系数',
        '埋戻し対象体積 ÷ 締固め係数': '回填对象体积÷压实系数',
        '完成盛土量 ÷ 締固め係数': '完成填土量÷压实系数',
        '必要土量 × ほぐし係数': '所需土方×松散系数',
        '※積載容量は車両・土質・積載条件により調整してください。': '※请根据车辆、土质和装载条件调整装载容量。',
        '※候補は参考値です。設計図書や現場条件に合わせて確認・変更してください。': '※候选值仅供参考，请根据设计文件和现场条件确认并修改。',
        '※ 土量変化率・積載容量・法勾配等は、土質・車両・現場条件・設計条件等により異なります。表示値は初期値・参考値として扱い、実際の条件に合わせて変更してください。':
            '※土方变化率、装载容量和边坡坡比会因土质、车辆、现场及设计条件而异。显示值为初始参考值，请按实际条件修改。',
        '注意\n盛土高さが大きい場合は、地盤条件・法面安定・排水条件・設計図書・関係法令等を確認してください。':
            '注意\n填土较高时，请确认地基条件、边坡稳定、排水条件、设计文件及相关法规。',
        '入力しない場合は0m³': '未输入时按0立方米计算',
        '例：1 : 1.7 の場合は 1.7': '例：1 : 1.7时输入1.7',
        '任意入力': '自定义输入',
        '0より大きい数値を入力': '请输入大于0的数值',
        '0以上の数値を入力': '请输入大于或等于0的数值',
        '0より大きい数値を入力してください': '请输入大于0的数值',
        '数値を入力してください': '请输入数值',
        '有効な数値を入力してください': '请输入有效数值',
        '車両名を入力してください': '请输入车辆名称',
        '寸法・ほぐし係数・積載容量には0より大きい数値を入力してください': '请为尺寸、松散系数和装载容量输入大于0的数值',
        '寸法・締固め係数には0より大きい数値を入力してください': '请为尺寸和压实系数输入大于0的数值',
        '控除する構造物体積には0以上の数値を入力してください': '扣除的结构物体积请输入大于或等于0的数值',
        '控除する構造物体積が掘削体積を超えています': '扣除的结构物体积超过了开挖体积',
        '法長は0より大きい数値を入力してください': '边坡长度请输入大于0的数值',
        '距離の項目と1つ以上組み合わせて入力してください': '请至少输入一个距离项目并与其他项目组合',
        '保存': '保存',
        '登録': '登记',
        '登録済み': '已登记',
        '入力を消去': '清除输入',
        '計算する': '计算',
        '用語説明': '术语说明',
        'その他': '其他',
        '0で割ることはできません': '不能除以0',
        '計算できません': '无法计算',
        'この値では計算できません': '无法使用该数值计算',
        'この関数はまだ利用できません': '该函数暂不可用',
        'これ以上入力できません': '无法继续输入',
        '分数に変換できません': '无法转换为分数',
        '分数の入力を完了してから関数を選択してください': '请先完成分数输入，再选择函数',
        '先に数値を入力してください': '请先输入数值',
        '4項目のうち3項目を入力してください': '请输入4个项目中的3个',
        '計算する1項目を空欄にしてください': '请将要计算的1个项目留空',
        '勾配の入力項目を選択してください': '请选择坡度输入项目',
        '計算に使う2つの入力欄を順にタップし、数値を入力してください。残りの値は自動計算されます。法勾配 1:n は、縦1に対する水平距離nを表します。':
            '请依次点击两个用于计算的输入框并输入数值，其余数值会自动计算。边坡坡比1:n表示垂直1对应水平距离n。',
        'コピーしました': '已复制',
        'カットしました': '已剪切',
        'ペーストしました': '已粘贴',
        '元に戻す': '撤销',
        '履歴をコピーしました': '已复制历史记录',
        '履歴を削除しました': '已删除历史记录',
        '計算式を編集欄へ戻しました': '已将算式恢复到编辑框',
        '貼り付けできる計算式がありません': '没有可粘贴的算式',
        '見積へ送る計算式がありません': '没有可发送到估算的算式',
        'スターはアルティメット版で利用できます': '星标功能仅完整版可用',
        '閉じる': '关闭',
        '広告スペース': '广告区域',
        '広告なし版で非表示に！': '购买无广告版后隐藏！',
        '今すぐ\nアップグレード': '立即\n升级',
      }[japanese];
      if (translated != null) return translated;
    }
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

  String itemCount(int count) => _pick(
    japanese: '$count件',
    english: '$count items',
    simplifiedChinese: '$count项',
  );
  String productivityUnit(String value) {
    return switch (appLanguage) {
      AppLanguage.japanese => value,
      AppLanguage.english => switch (value) {
        '本' => 'pcs',
        '枚' => 'sheets',
        '個' => 'items',
        '箇所' => 'locations',
        '組' => 'sets',
        '式' => 'lump sum',
        _ => text(value),
      },
      AppLanguage.simplifiedChinese => switch (value) {
        '本' => '根',
        '枚' => '张',
        '個' => '个',
        '箇所' => '处',
        '組' => '组',
        '式' => '项',
        _ => text(value),
      },
    };
  }

  String itemCountWithLimit(int count, int limit) => _pick(
    japanese: '$count / $limit件',
    english: '$count / $limit items',
    simplifiedChinese: '$count / $limit项',
  );
  String currentSaveLimit(int limit) => _pick(
    japanese: '現在の保存上限：$limit件',
    english: 'Current storage limit: $limit items',
    simplifiedChinese: '当前保存上限：$limit项',
  );
  String productivityLimitMessage(int limit) => _pick(
    japanese: '現在のプランでは最大$limit件まで保存できます。完全版では100件まで保存できます。',
    english:
        'The current plan can save up to $limit records. The full plan can save up to 100 records.',
    simplifiedChinese: '当前方案最多可保存$limit条记录。完整版最多可保存100条记录。',
  );
  String get freeEstimateLimit => _pick(
    japanese: '無料版では見積を5件まで保存できます',
    english: 'The free plan can store up to 5 estimates',
    simplifiedChinese: '免费版最多可保存5份估算',
  );

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

  String estimateDetails(int count) => _pick(
    japanese: '$count明細',
    english: '$count details',
    simplifiedChinese: '$count项明细',
  );

  String deleteEstimateQuestion(String name) => _pick(
    japanese: '「$name」を削除しますか？\n含まれる明細もすべて削除されます。',
    english:
        'Delete "$name"?\nAll details in this estimate will also be deleted.',
    simplifiedChinese: '要删除“$name”吗？\n该估算中的所有明细也会被删除。',
  );

  String get displayAndCalculation => _pick(
    japanese: '表示・計算',
    english: 'Display & calculation',
    simplifiedChinese: '显示与计算',
  );
  String get theme =>
      _pick(japanese: 'テーマ', english: 'Theme', simplifiedChinese: '主题');
  String get systemTheme => _pick(
    japanese: '端末に合わせる',
    english: 'Follow device setting',
    simplifiedChinese: '跟随设备设置',
  );
  String get whiteTheme =>
      _pick(japanese: '白', english: 'White', simplifiedChinese: '白色');
  String get grayTheme =>
      _pick(japanese: 'グレー', english: 'Gray', simplifiedChinese: '灰色');
  String get blackTheme =>
      _pick(japanese: '黒', english: 'Black', simplifiedChinese: '黑色');
  String get decimalPlaces => _pick(
    japanese: '小数点以下の表示桁数',
    english: 'Decimal places',
    simplifiedChinese: '小数位数',
  );
  String digits(int count) => _pick(
    japanese: '$count桁',
    english: '$count places',
    simplifiedChinese: '$count位',
  );
  String get roundingMethod => _pick(
    japanese: '丸め方法',
    english: 'Rounding method',
    simplifiedChinese: '舍入方式',
  );
  String get roundHalfUp => _pick(
    japanese: '四捨五入',
    english: 'Round half up',
    simplifiedChinese: '四舍五入',
  );
  String get roundUp =>
      _pick(japanese: '切上げ', english: 'Round up', simplifiedChinese: '向上取整');
  String get roundDown =>
      _pick(japanese: '切捨て', english: 'Round down', simplifiedChinese: '向下取整');
  String get angleUnit =>
      _pick(japanese: '角度単位', english: 'Angle unit', simplifiedChinese: '角度单位');
  String get degrees => _pick(
    japanese: '度（DEG）',
    english: 'Degrees (DEG)',
    simplifiedChinese: '度（DEG）',
  );
  String get radians => _pick(
    japanese: 'ラジアン（RAD）',
    english: 'Radians (RAD)',
    simplifiedChinese: '弧度（RAD）',
  );
  String get calculationHistory => _pick(
    japanese: '計算履歴',
    english: 'Calculation history',
    simplifiedChinese: '计算历史',
  );
  String get ascendingHistory => _pick(
    japanese: '履歴を昇順で表示',
    english: 'Show history ascending',
    simplifiedChinese: '按升序显示历史',
  );
  String get ascendingOldest => _pick(
    japanese: '昇順（古い順）',
    english: 'Ascending (oldest first)',
    simplifiedChinese: '升序（最早优先）',
  );
  String get descendingNewest => _pick(
    japanese: '降順（新しい順）',
    english: 'Descending (newest first)',
    simplifiedChinese: '降序（最新优先）',
  );
  String get confirmHistoryDeletion => _pick(
    japanese: '履歴削除時に確認する',
    english: 'Confirm before deleting history',
    simplifiedChinese: '删除历史前确认',
  );
  String get clearAllHistory => _pick(
    japanese: '履歴をすべて削除',
    english: 'Delete all history',
    simplifiedChinese: '删除全部历史',
  );
  String get clearHistoryQuestion => _pick(
    japanese: 'スター付き以外の計算履歴をすべて削除します。よろしいですか？',
    english: 'Delete all calculation history except starred entries?',
    simplifiedChinese: '要删除除星标记录以外的全部计算历史吗？',
  );
  String get cancel =>
      _pick(japanese: 'キャンセル', english: 'Cancel', simplifiedChinese: '取消');
  String get delete =>
      _pick(japanese: '削除', english: 'Delete', simplifiedChinese: '删除');
  String get historyCleared => _pick(
    japanese: '計算履歴をすべて削除しました',
    english: 'Calculation history was deleted',
    simplifiedChinese: '计算历史已全部删除',
  );
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
