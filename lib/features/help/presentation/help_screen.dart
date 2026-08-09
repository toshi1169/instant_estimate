import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = l10n.isEnglish;
    return Scaffold(
      key: const Key('helpScreen'),
      appBar: AppBar(title: Text(l10n.help)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _HelpIntroCard(english: english),
            const SizedBox(height: 14),
            _HelpSection(
              key: const Key('helpSectionCalculator'),
              icon: Icons.calculate_outlined,
              title: english ? 'Calculator basics' : '電卓の基本操作',
              items: english
                  ? const [
                      'Tap “…” to open the side menu. Long-press or double-tap it to open the function list.',
                      'Tap the gear button to open Settings.',
                      'Tap “←” to delete at the caret, or long-press it to delete everything to the left.',
                      'A translucent green preview appears while entering a valid expression. Tap “=” to confirm it.',
                    ]
                  : const [
                      '「…」をタップすると左メニューを開きます。長押しまたはダブルタップで関数一覧を開きます。',
                      '歯車ボタンで設定画面を開きます。',
                      '「←」をタップするとキャレット左側を削除し、長押しすると左側をまとめて削除します。',
                      '入力途中は薄い緑色で暫定解を表示し、「=」で計算結果を確定します。',
                    ],
            ),
            _HelpSection(
              key: const Key('helpSectionFraction'),
              icon: Icons.safety_divider_outlined,
              title: english ? 'Fractions' : '分数の入力と表示',
              items: english
                  ? const [
                      'Tap “a/b” to insert a fraction at the caret. Tap the numerator, denominator or whole-number part to edit it.',
                      'The numerator and denominator can each contain up to 10 digits.',
                      'When a result can be shown as a fraction, the “=” button turns orange. Tap “=” or “a/b” to cycle through improper fraction, mixed fraction and decimal.',
                      'Estimate calculations always use the decimal value, regardless of the displayed format.',
                    ]
                  : const [
                      '「a/b」でキャレット位置へ分数枠を挿入します。分子・分母・帯分数の整数部分をタップして編集できます。',
                      '分子・分母はそれぞれ10桁まで入力できます。',
                      '分数へ変換できる解では「=」がオレンジ色になります。「=」または「a/b」で仮分数・帯分数・小数を切り替えられます。',
                      '見積の数量計算には、表示形式にかかわらず小数値を使用します。',
                    ],
            ),
            _HelpSection(
              key: const Key('helpSectionHistory'),
              icon: Icons.history_outlined,
              title: english ? 'Calculation history' : '計算履歴',
              items: english
                  ? const [
                      'Use the vertical menu beside a history entry to copy, share, edit, delete, star or send it to an estimate.',
                      'Long-press the history area to open the full searchable and sortable history screen.',
                      'History order and delete confirmation can be changed in Settings.',
                    ]
                  : const [
                      '履歴左側の縦3点から、コピー・共有・編集・削除・スター・見積への送信を選べます。',
                      '履歴スペースを長押しすると、検索や並べ替えができる計算履歴画面を開きます。',
                      '履歴の並び順や削除確認は設定画面で変更できます。',
                    ],
            ),
            _HelpSection(
              key: const Key('helpSectionConvenientCalculations'),
              icon: Icons.engineering_outlined,
              title: l10n.convenientCalculations,
              items: english
                  ? const [
                      'Choose practical site calculators for earthwork, density and weight, slope, area, ratio, labor and productivity.',
                      'Adjust inputs and factors to the actual drawings, specifications, soil and site conditions.',
                    ]
                  : const [
                      '土量・比重と重量・勾配・面積・対比・歩掛と生産性など、現場向けの計算を選べます。',
                      '入力値や係数は、図面・仕様書・土質・施工条件など実際の条件に合わせて変更してください。',
                    ],
            ),
            _HelpSection(
              key: const Key('helpSectionEstimate'),
              icon: Icons.request_quote_outlined,
              title: l10n.instantEstimate,
              items: english
                  ? const [
                      'Choose “To estimate” from calculator results, review the details, then add them to an estimate.',
                      'Amounts are calculated from quantity and unit price, with work subtotals, pre-tax total, tax and grand total.',
                      'Export the breakdown as PDF or Excel, copy it as a table, or print it.',
                    ]
                  : const [
                      '電卓や各計算画面の結果から「見積へ」を選び、内容を確認・編集して明細へ追加します。',
                      '数量と単価から金額を自動計算し、工種小計・税抜合計・消費税・税込総額を確認できます。',
                      '作成した内訳はPDF、Excel形式、表コピー、印刷で利用できます。',
                    ],
            ),
            _HelpSection(
              key: const Key('helpSectionData'),
              icon: Icons.info_outline,
              title: english ? 'Data and safety notes' : 'データとご利用上の注意',
              items: english
                  ? const [
                      'Results are reference values. Confirm drawings and applicable standards before making final construction, safety or legal decisions.',
                      'Data is currently stored on this device. Deleting the app may also delete saved data.',
                    ]
                  : const [
                      '計算結果は参考値です。施工・安全・法令に関する最終判断は、設計図書や関係基準を確認してください。',
                      '現在の保存データは端末内に保存されます。アプリを端末から削除すると、保存内容も消える場合があります。',
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpIntroCard extends StatelessWidget {
  const _HelpIntroCard({required this.english});

  final bool english;

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
                    english ? 'Fast calculations on site' : '現場計算をすばやく',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    english
                        ? 'Learn the main features of the calculator, convenient calculations and instant estimates.'
                        : '関数電卓、便利計算、インスタント見積の主な使い方を確認できます。',
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
