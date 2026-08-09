import 'package:flutter/material.dart';

import '../../../core/domain/app_access_plan.dart';

class AccessPlanScreen extends StatelessWidget {
  const AccessPlanScreen({required this.plan, super.key});

  final AppAccessPlan plan;

  @override
  Widget build(BuildContext context) {
    final isFull = plan == AppAccessPlan.full;
    final benefits = isFull
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
          ];

    return Scaffold(
      appBar: AppBar(title: Text(plan.displayName)),
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
                      plan.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.priceLabel,
                      key: const Key('accessPlanPrice'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.hasSevenDayTrial) ...[
                      const SizedBox(height: 6),
                      const Text('初回のみ7日間無料体験'),
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
            Text(
              '購入手続きはストア公開準備の工程で有効になります。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
