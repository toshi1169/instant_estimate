import 'package:flutter/material.dart';

import '../../../core/domain/app_access_plan.dart';
import '../../../core/localization/app_localizations.dart';
import '../domain/purchase_store.dart';

class AccessPlanScreen extends StatelessWidget {
  const AccessPlanScreen({
    required this.plan,
    this.currentPlan = AppAccessPlan.free,
    this.purchaseStore,
    super.key,
  });

  final AppAccessPlan plan;
  final AppAccessPlan currentPlan;
  final PurchaseStore? purchaseStore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFull = plan == AppAccessPlan.full;
    final benefits = l10n.isEnglish
        ? (isFull
              ? const [
                  'Remove all ads',
                  'Unlimited saved estimates',
                  'Unlimited unit price master records',
                  'Save up to 100 productivity records',
                  'Access future full-plan features',
                ]
              : const [
                  'Remove banner and video ads',
                  'One-time purchase',
                  'Save up to 5 estimates',
                  'Save up to 10 unit price records',
                ])
        : (isFull
              ? const [
                  'すべての広告を非表示',
                  '見積の保存件数を無制限に拡張',
                  '単価マスタの保存件数を無制限に拡張',
                  '歩掛・生産性実績を100件まで保存',
                  '将来追加される完全版対象機能',
                ]
              : const [
                  'バナー広告と動画広告をすべて非表示',
                  '一度の購入で継続利用',
                  '見積は5件まで保存',
                  '単価マスタは10件まで保存',
                ]);
    final planName = l10n.isEnglish
        ? (isFull ? 'Full plan' : 'Ad-free plan')
        : (isFull ? '完全版' : '広告なし版');
    final fallbackPriceLabel = l10n.isEnglish
        ? switch (plan) {
            AppAccessPlan.free => 'Free',
            AppAccessPlan.adFree => '¥300 (one-time purchase)',
            AppAccessPlan.full => '¥500 / month',
          }
        : plan.priceLabel;

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
                        l10n.isEnglish
                            ? '7-day free trial for first-time users'
                            : '初回のみ7日間無料体験',
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
                      ? (l10n.isEnglish ? 'Current plan' : '現在のプラン')
                      : product == null
                      ? (l10n.isEnglish ? 'Connect to store' : 'ストアへ接続')
                      : (l10n.isEnglish ? 'Purchase' : '購入する'),
                ),
              ),
              TextButton.icon(
                key: const Key('restorePurchasesButton'),
                onPressed: purchaseState?.isBusy ?? false
                    ? null
                    : store.restorePurchases,
                icon: const Icon(Icons.restore),
                label: Text(l10n.isEnglish ? 'Restore purchases' : '購入履歴を復元'),
              ),
              const SizedBox(height: 8),
              Text(
                _purchaseStatusText(l10n, purchaseState),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else
              Text(
                l10n.isEnglish
                    ? 'Purchases will be enabled when the store release is prepared.'
                    : '購入手続きはストア公開準備の工程で有効になります。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _purchaseStatusText(AppLocalizations l10n, PurchaseStoreState? state) {
    return switch (state?.operation) {
      PurchaseOperation.loading =>
        l10n.isEnglish ? 'Connecting to the store…' : 'ストアへ接続しています…',
      PurchaseOperation.purchasing =>
        l10n.isEnglish ? 'Processing purchase…' : '購入手続き中です…',
      PurchaseOperation.restoring =>
        l10n.isEnglish ? 'Restoring purchases…' : '購入履歴を復元しています…',
      PurchaseOperation.completed =>
        l10n.isEnglish ? 'Purchase restored.' : '購入内容を反映しました',
      PurchaseOperation.unavailable =>
        l10n.isEnglish
            ? 'This product is not available in the current store.'
            : '現在のストアでは商品を取得できません',
      PurchaseOperation.error =>
        l10n.isEnglish
            ? 'Could not complete the store operation. Please try again.'
            : 'ストア処理を完了できませんでした。再度お試しください',
      _ =>
        l10n.isEnglish
            ? 'The price and trial terms shown by the store apply.'
            : '価格・無料体験期間はストアに表示される内容が適用されます',
    };
  }
}
