import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const Key('helpScreen'),
      appBar: AppBar(title: Text(l10n.help)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _HelpIntroCard(l10n: l10n),
            const SizedBox(height: 14),
            _HelpSection(
              key: const Key('helpSectionCalculator'),
              icon: Icons.calculate_outlined,
              title: l10n.choose(
                japanese: '電卓の基本操作',
                english: 'Calculator basics',
                simplifiedChinese: '计算器基本操作',
                traditionalChinese: '計算機基本操作',
              ),
              items: [
                l10n.choose(
                  japanese: '「…」をタップすると左メニューを開きます。長押しまたはダブルタップで関数一覧を開きます。',
                  english:
                      'Tap “…” to open the side menu. Long-press or double-tap it to open the function list.',
                  simplifiedChinese: '点击“…”打开侧边菜单；长按或双击可打开函数列表。',
                  traditionalChinese: '點按「…」可開啟側邊選單；長按或點按兩下可開啟函數列表。',
                ),
                l10n.choose(
                  japanese: '歯車ボタンで設定画面を開きます。',
                  english: 'Tap the gear button to open Settings.',
                  simplifiedChinese: '点击齿轮按钮打开设置。',
                  traditionalChinese: '點按齒輪按鈕可開啟設定。',
                ),
                l10n.choose(
                  japanese: '「←」をタップするとキャレット左側を削除し、長押しすると左側をまとめて削除します。',
                  english:
                      'Tap “←” to delete at the caret, or long-press it to delete everything to the left.',
                  simplifiedChinese: '点击“←”删除光标左侧内容，长按可删除光标左侧的全部内容。',
                  traditionalChinese: '點按「←」可刪除游標左側內容，長按可刪除左側全部內容。',
                ),
                l10n.choose(
                  japanese: '入力途中は薄い緑色で暫定解を表示し、「=」で計算結果を確定します。',
                  english:
                      'A translucent green preview appears while entering a valid expression. Tap “=” to confirm it.',
                  simplifiedChinese: '输入有效算式时会以半透明绿色显示预览结果，点击“=”确认计算结果。',
                  traditionalChinese: '輸入有效算式時會以半透明綠色顯示預覽結果，點按「=」確認計算結果。',
                ),
              ],
            ),
            _HelpSection(
              key: const Key('helpSectionFraction'),
              icon: Icons.safety_divider_outlined,
              title: l10n.choose(
                japanese: '分数の入力と表示',
                english: 'Fractions',
                simplifiedChinese: '分数输入与显示',
                traditionalChinese: '分數輸入與顯示',
              ),
              items: [
                l10n.choose(
                  japanese:
                      '「a/b」でキャレット位置へ分数枠を挿入します。分子・分母・帯分数の整数部分をタップして編集できます。',
                  english:
                      'Tap “a/b” to insert a fraction at the caret. Tap the numerator, denominator or whole-number part to edit it.',
                  simplifiedChinese: '点击“a/b”在光标位置插入分数框。点击分子、分母或带分数的整数部分即可编辑。',
                  traditionalChinese:
                      '點按「a/b」可在游標位置插入分數框。點按分子、分母或帶分數的整數部分即可編輯。',
                ),
                l10n.choose(
                  japanese: '分子・分母はそれぞれ10桁まで入力できます。',
                  english:
                      'The numerator and denominator can each contain up to 10 digits.',
                  simplifiedChinese: '分子和分母各最多可输入10位数字。',
                  traditionalChinese: '分子和分母各最多可輸入10位數字。',
                ),
                l10n.choose(
                  japanese:
                      '分数へ変換できる解では「=」がオレンジ色になります。「=」または「a/b」で仮分数・帯分数・小数を切り替えられます。',
                  english:
                      'When a result can be shown as a fraction, the “=” button turns orange. Tap “=” or “a/b” to cycle through improper fraction, mixed fraction and decimal.',
                  simplifiedChinese:
                      '结果可转换为分数时，“=”按钮会变为橙色。点击“=”或“a/b”可在假分数、带分数和小数之间切换。',
                  traditionalChinese:
                      '結果可轉換為分數時，「=」按鈕會變成橙色。點按「=」或「a/b」可在假分數、帶分數和小數之間切換。',
                ),
                l10n.choose(
                  japanese: '見積の数量計算には、表示形式にかかわらず小数値を使用します。',
                  english:
                      'Estimate calculations always use the decimal value, regardless of the displayed format.',
                  simplifiedChinese: '估算数量计算始终使用小数值，不受当前显示格式影响。',
                  traditionalChinese: '估算數量計算一律使用小數值，不受目前顯示格式影響。',
                ),
              ],
            ),
            _HelpSection(
              key: const Key('helpSectionHistory'),
              icon: Icons.history_outlined,
              title: l10n.choose(
                japanese: '計算履歴',
                english: 'Calculation history',
                simplifiedChinese: '计算历史',
                traditionalChinese: '計算歷史',
              ),
              items: [
                l10n.choose(
                  japanese: '履歴左側の縦3点から、コピー・共有・編集・削除・スター・見積への送信を選べます。',
                  english:
                      'Use the vertical menu beside a history entry to copy, share, edit, delete, star or send it to an estimate.',
                  simplifiedChinese: '通过历史记录旁的竖向三点菜单，可选择复制、分享、编辑、删除、加星或发送至估算。',
                  traditionalChinese:
                      '透過歷史紀錄旁的直向三點選單，可選擇複製、分享、編輯、刪除、加上星號或傳送至估算。',
                ),
                l10n.choose(
                  japanese: '履歴スペースを長押しすると、検索や並べ替えができる計算履歴画面を開きます。',
                  english:
                      'Long-press the history area to open the full searchable and sortable history screen.',
                  simplifiedChinese: '长按历史区域可打开支持搜索和排序的完整计算历史页面。',
                  traditionalChinese: '長按歷史區域可開啟支援搜尋和排序的完整計算歷史畫面。',
                ),
                l10n.choose(
                  japanese: '履歴の並び順や削除確認は設定画面で変更できます。',
                  english:
                      'History order and delete confirmation can be changed in Settings.',
                  simplifiedChinese: '可在设置中更改历史排序方式和删除确认。',
                  traditionalChinese: '可在設定中變更歷史排序方式和刪除確認。',
                ),
              ],
            ),
            _HelpSection(
              key: const Key('helpSectionConvenientCalculations'),
              icon: Icons.engineering_outlined,
              title: l10n.convenientCalculations,
              items: [
                l10n.choose(
                  japanese: '土量・比重と重量・勾配・面積・対比・歩掛と生産性など、現場向けの計算を選べます。',
                  english:
                      'Choose practical site calculators for earthwork, density and weight, slope, area, ratio, labor and productivity.',
                  simplifiedChinese: '可选择土方、密度与重量、坡度、面积、比例、步挂与生产率等现场实用计算。',
                  traditionalChinese:
                      '可選擇土方、密度與重量、坡度、面積、比例、步掛（BUGAKARI）與生產率等現場實用計算。',
                ),
                l10n.choose(
                  japanese: '入力値や係数は、図面・仕様書・土質・施工条件など実際の条件に合わせて変更してください。',
                  english:
                      'Adjust inputs and factors to the actual drawings, specifications, soil and site conditions.',
                  simplifiedChinese: '请根据图纸、技术要求、土质和施工条件等实际情况调整输入值与系数。',
                  traditionalChinese: '請依圖面、規格、土質和施工條件等實際情況調整輸入值與係數。',
                ),
              ],
            ),
            _HelpSection(
              key: const Key('helpSectionEstimate'),
              icon: Icons.request_quote_outlined,
              title: l10n.instantEstimate,
              items: [
                l10n.choose(
                  japanese: '電卓や各計算画面の結果から「見積へ」を選び、内容を確認・編集して明細へ追加します。',
                  english:
                      'Choose “To estimate” from calculator results, review the details, then add them to an estimate.',
                  simplifiedChinese: '从计算器或各计算页面的结果中选择“发送至估算”，确认并编辑内容后添加到明细。',
                  traditionalChinese: '從計算機或各計算畫面的結果選擇「傳送到估算」，確認並編輯內容後加入明細。',
                ),
                l10n.choose(
                  japanese: '数量と単価から金額を自動計算し、工種小計・税抜合計・消費税・税込総額を確認できます。',
                  english:
                      'Amounts are calculated from quantity and unit price, with work subtotals, pre-tax total, tax and grand total.',
                  simplifiedChinese: '根据数量和单价自动计算金额，并可确认项目小计、未税合计、消费税和含税总额。',
                  traditionalChinese: '依數量和單價自動計算金額，並可確認工種小計、未稅合計、消費稅和含稅總額。',
                ),
                l10n.choose(
                  japanese: '作成した内訳はPDF、Excel形式、表コピー、印刷で利用できます。',
                  english:
                      'Export the breakdown as PDF or Excel, copy it as a table, or print it.',
                  simplifiedChinese: '已创建的明细可导出为PDF或Excel，也可复制为表格或直接打印。',
                  traditionalChinese: '已建立的明細可匯出為PDF或Excel，也可複製為表格或直接列印。',
                ),
              ],
            ),
            _HelpSection(
              key: const Key('helpSectionData'),
              icon: Icons.info_outline,
              title: l10n.choose(
                japanese: 'データとご利用上の注意',
                english: 'Data and safety notes',
                simplifiedChinese: '数据与使用注意事项',
                traditionalChinese: '資料與使用注意事項',
              ),
              items: [
                l10n.choose(
                  japanese: '計算結果は参考値です。施工・安全・法令に関する最終判断は、設計図書や関係基準を確認してください。',
                  english:
                      'Results are reference values. Confirm drawings and applicable standards before making final construction, safety or legal decisions.',
                  simplifiedChinese:
                      '计算结果仅供参考。进行施工、安全或法规方面的最终判断前，请确认设计文件及相关标准。',
                  traditionalChinese:
                      '計算結果僅供參考。進行施工、安全或法規方面的最終判斷前，請確認設計文件及相關標準。',
                ),
                l10n.choose(
                  japanese:
                      '現在の保存データは端末内に保存されます。アプリを端末から削除すると、保存内容も消える場合があります。',
                  english:
                      'Data is currently stored on this device. Deleting the app may also delete saved data.',
                  simplifiedChinese: '当前数据保存在本设备内。删除应用时，已保存的数据也可能被删除。',
                  traditionalChinese: '目前資料儲存在本裝置內。刪除應用程式時，已儲存的資料也可能一併刪除。',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpIntroCard extends StatelessWidget {
  const _HelpIntroCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.handyman_outlined,
              color: theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.choose(
                      japanese: '現場計算をすばやく',
                      english: 'Fast calculations on site',
                      simplifiedChinese: '快速完成现场计算',
                      traditionalChinese: '快速完成現場計算',
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.choose(
                      japanese: '関数電卓、便利計算、インスタント見積の主な使い方を確認できます。',
                      english:
                          'Learn the main features of the calculator, convenient calculations and instant estimates.',
                      simplifiedChinese: '了解科学计算器、实用计算和即时估算的主要使用方法。',
                      traditionalChinese: '瞭解科學計算機、實用計算和即時估算的主要使用方式。',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.items,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
