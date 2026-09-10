import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/domain/app_access_plan.dart';
import '../../../core/localization/app_localizations.dart';
import '../domain/purchase_store.dart';

const privacyPolicyUrl = 'https://matsumotoboundary.com/privacy/';
const termsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class AccessPlanScreen extends StatelessWidget {
  const AccessPlanScreen({
    required this.plan,
    this.currentPlan = AppAccessPlan.free,
    this.purchaseStore,
    this.externalUrlLauncher,
    super.key,
  });

  final AppAccessPlan plan;
  final AppAccessPlan currentPlan;
  final PurchaseStore? purchaseStore;
  final ExternalUrlLauncher? externalUrlLauncher;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFull = plan == AppAccessPlan.full;
    final benefits = (isFull
        ? [
            l10n.choose(
              japanese: 'すべての広告を非表示',
              english: 'Remove all ads',
              simplifiedChinese: '移除全部广告',
              traditionalChinese: '移除所有廣告',
            ),
            l10n.choose(
              japanese: '見積の保存件数を無制限に拡張',
              english: 'Unlimited saved estimates',
              simplifiedChinese: '无限保存估算',
              traditionalChinese: '無限制儲存估算',
            ),
            l10n.choose(
              japanese: '単価マスタの保存件数を無制限に拡張',
              english: 'Unlimited unit price master records',
              simplifiedChinese: '无限保存单价资料',
              traditionalChinese: '無限制儲存單價資料',
            ),
            l10n.choose(
              japanese: '歩掛・生産性実績を100件まで保存',
              english: 'Save up to 100 productivity records',
              simplifiedChinese: '最多保存100条步挂与生产率记录',
              traditionalChinese: '最多儲存100筆步掛（BUGAKARI）與生產率紀錄',
            ),
            l10n.choose(
              japanese: '将来追加される完全版対象機能',
              english: 'Access future full-plan features',
              simplifiedChinese: '使用今后新增的完整版功能',
              traditionalChinese: '使用日後新增的完整版功能',
            ),
          ]
        : [
            l10n.choose(
              japanese: 'バナー広告と動画広告をすべて非表示',
              english: 'Remove banner and video ads',
              simplifiedChinese: '移除横幅广告和视频广告',
              traditionalChinese: '移除橫幅廣告和影片廣告',
            ),
            l10n.choose(
              japanese: '一度の購入で継続利用',
              english: 'One-time purchase',
              simplifiedChinese: '一次购买，持续使用',
              traditionalChinese: '一次購買，持續使用',
            ),
            l10n.choose(
              japanese: '見積は5件まで保存',
              english: 'Save up to 5 estimates',
              simplifiedChinese: '最多保存5份估算',
              traditionalChinese: '最多儲存5份估算',
            ),
            l10n.choose(
              japanese: '単価マスタは10件まで保存',
              english: 'Save up to 10 unit price records',
              simplifiedChinese: '最多保存10条单价资料',
              traditionalChinese: '最多儲存10筆單價資料',
            ),
          ]);
    final planName = l10n.choose(
      japanese: isFull ? '完全版' : '広告なし版',
      english: isFull ? 'Full plan' : 'Ad-free plan',
      simplifiedChinese: isFull ? '完整版' : '无广告版',
      traditionalChinese: isFull ? '完整版' : '無廣告版',
      vietnamese: isFull ? 'Bản đầy đủ' : 'Bản không quảng cáo',
      indonesian: isFull ? 'Versi lengkap' : 'Versi bebas iklan',
      filipino: isFull ? 'Kumpletong bersyon' : 'Bersyong walang ad',
      myanmar: isFull ? 'အပြည့်အစုံဗားရှင်း' : 'ကြော်ငြာမပါဗားရှင်း',
    );
    final fallbackPriceLabel = switch (plan) {
      AppAccessPlan.free => l10n.choose(
        japanese: '無料',
        english: 'Free',
        simplifiedChinese: '免费',
        traditionalChinese: '免費',
      ),
      AppAccessPlan.adFree => l10n.choose(
        japanese: '¥300（買い切り）',
        english: '¥300 (one-time purchase)',
        simplifiedChinese: '¥300（一次性购买）',
        traditionalChinese: '¥300（一次性購買）',
      ),
      AppAccessPlan.full => l10n.choose(
        japanese: '¥500／月',
        english: '¥500 / month',
        simplifiedChinese: '¥500／月',
        traditionalChinese: '¥500／月',
      ),
    };

    final store = purchaseStore;
    if (store != null) {
      return AnimatedBuilder(
        animation: store.state,
        builder: (context, _) => _buildScreen(
          context,
          planName: planName,
          benefits: benefits,
          fallbackPriceLabel: fallbackPriceLabel,
          isFull: isFull,
          store: store,
        ),
      );
    }
    return _buildScreen(
      context,
      planName: planName,
      benefits: benefits,
      fallbackPriceLabel: fallbackPriceLabel,
      isFull: isFull,
    );
  }

  Widget _buildScreen(
    BuildContext context, {
    required String planName,
    required List<String> benefits,
    required String fallbackPriceLabel,
    required bool isFull,
    PurchaseStore? store,
  }) {
    final l10n = AppLocalizations.of(context);
    final purchaseState = store?.state.value;
    final product = purchaseState?.productFor(plan);
    final priceLabel = product?.displayPrice ?? fallbackPriceLabel;
    final isCurrentPlan = currentPlan == plan;
    final canPurchase =
        store != null && !isCurrentPlan && !(purchaseState?.isBusy ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(planName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      isFull
                          ? Icons.workspace_premium_outlined
                          : Icons.block_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      planName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      priceLabel,
                      key: const Key('accessPlanPrice'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.hasSevenDayTrial) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.choose(
                          japanese: '初回のみ7日間無料体験',
                          english: '7-day free trial for first-time users',
                          simplifiedChinese: '首次使用可免费试用7天',
                          traditionalChinese: '首次使用可免費試用7天',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            for (final benefit in benefits)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(benefit),
              ),
            const SizedBox(height: 18),
            if (store != null) ...[
              FilledButton.icon(
                key: const Key('purchasePlanButton'),
                onPressed: canPurchase ? () => store.purchase(plan) : null,
                icon: purchaseState?.isBusy ?? false
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  isCurrentPlan
                      ? l10n.choose(
                          japanese: '現在のプラン',
                          english: 'Current plan',
                          simplifiedChinese: '当前方案',
                          traditionalChinese: '目前方案',
                        )
                      : product == null
                      ? l10n.choose(
                          japanese: 'ストアへ接続',
                          english: 'Connect to store',
                          simplifiedChinese: '连接商店',
                          traditionalChinese: '連接商店',
                        )
                      : l10n.choose(
                          japanese: '購入する',
                          english: 'Purchase',
                          simplifiedChinese: '购买',
                          traditionalChinese: '購買',
                        ),
                ),
              ),
              TextButton.icon(
                key: const Key('restorePurchasesButton'),
                onPressed: purchaseState?.isBusy ?? false
                    ? null
                    : store.restorePurchases,
                icon: const Icon(Icons.restore),
                label: Text(
                  l10n.choose(
                    japanese: '購入履歴を復元',
                    english: 'Restore purchases',
                    simplifiedChinese: '恢复购买记录',
                    traditionalChinese: '恢復購買紀錄',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _purchaseStatusText(l10n, purchaseState),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              Text(
                l10n.choose(
                  japanese: '購入手続きはストア公開準備の工程で有効になります。',
                  english:
                      'Purchases will be enabled when the store release is prepared.',
                  simplifiedChinese: '完成应用商店发布准备后将启用购买功能。',
                  traditionalChinese: '完成App Store上架準備後將啟用購買功能。',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 0,
              children: [
                TextButton(
                  key: const Key('privacyPolicyLink'),
                  onPressed: () =>
                      _openExternalUrl(context, Uri.parse(privacyPolicyUrl)),
                  child: Text(l10n.privacyPolicy),
                ),
                TextButton(
                  key: const Key('termsOfUseLink'),
                  onPressed: () =>
                      _openExternalUrl(context, Uri.parse(termsOfUseUrl)),
                  child: Text(l10n.termsOfUse),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened =
          await (externalUrlLauncher?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } on Object {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).externalLinkOpenFailed),
        ),
      );
    }
  }

  String _purchaseStatusText(AppLocalizations l10n, PurchaseStoreState? state) {
    return switch (state?.operation) {
      PurchaseOperation.loading => l10n.choose(
        japanese: 'ストアへ接続しています…',
        english: 'Connecting to the store…',
        simplifiedChinese: '正在连接商店…',
        traditionalChinese: '正在連接商店…',
      ),
      PurchaseOperation.purchasing => l10n.choose(
        japanese: '購入手続き中です…',
        english: 'Processing purchase…',
        simplifiedChinese: '正在处理购买…',
        traditionalChinese: '正在處理購買…',
      ),
      PurchaseOperation.restoring => l10n.choose(
        japanese: '購入履歴を復元しています…',
        english: 'Restoring purchases…',
        simplifiedChinese: '正在恢复购买记录…',
        traditionalChinese: '正在恢復購買紀錄…',
      ),
      PurchaseOperation.completed => l10n.choose(
        japanese: '購入内容を反映しました',
        english: 'Purchase restored.',
        simplifiedChinese: '购买内容已恢复。',
        traditionalChinese: '已套用購買內容。',
      ),
      PurchaseOperation.unavailable => l10n.choose(
        japanese: '現在のストアでは商品を取得できません',
        english: 'This product is not available in the current store.',
        simplifiedChinese: '当前商店无法获取此商品。',
        traditionalChinese: '目前商店無法取得此商品。',
      ),
      PurchaseOperation.error => l10n.choose(
        japanese: 'ストア処理を完了できませんでした。再度お試しください',
        english: 'Could not complete the store operation. Please try again.',
        simplifiedChinese: '无法完成商店操作，请重试。',
        traditionalChinese: '無法完成商店操作，請再試一次。',
      ),
      _ => l10n.choose(
        japanese: '価格・無料体験期間はストアに表示される内容が適用されます',
        english: 'The price and trial terms shown by the store apply.',
        simplifiedChinese: '价格和免费试用期限以商店显示内容为准。',
        traditionalChinese: '價格和免費試用期限以商店顯示內容為準。',
      ),
    };
  }
}
