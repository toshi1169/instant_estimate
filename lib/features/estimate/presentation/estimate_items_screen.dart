import 'package:flutter/material.dart';

import '../application/estimate_controller.dart';
import '../domain/estimate_item.dart';

class EstimateItemsScreen extends StatelessWidget {
  const EstimateItemsScreen({required this.controller, super.key});

  final EstimateController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('名称未設定の見積')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Text('${controller.items.length}件'),
                      const Spacer(),
                      Text(
                        '合計  ¥ ${_money(controller.totalAmount)}',
                        key: const Key('estimateTotalAmount'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: controller.items.isEmpty
                      ? const Center(
                          child: Text(
                            '見積明細はまだありません',
                            key: Key('emptyEstimateItems'),
                          ),
                        )
                      : ListView.separated(
                          key: const Key('estimateItemsList'),
                          padding: const EdgeInsets.all(12),
                          itemCount: controller.items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => _EstimateItemCard(
                            item: controller.items[index],
                            index: index,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EstimateItemCard extends StatelessWidget {
  const _EstimateItemCard({required this.item, required this.index});

  final EstimateItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final title = item.name.isEmpty ? '名称未入力' : item.name;
    return Card(
      key: Key('estimateItem$index'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (item.trade.isNotEmpty) Text(item.trade),
              ],
            ),
            if (item.specification.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.specification),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('${_number(item.quantity)} ${item.unit}'.trim()),
                ),
                Text(
                  item.amount == null ? '金額未設定' : '¥ ${_money(item.amount!)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('摘要：${item.description}'),
            ],
          ],
        ),
      ),
    );
  }
}

String _number(double? value) {
  if (value == null) return '数量未設定';
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
}

String _money(double value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return rounded < 0 ? '-$grouped' : grouped;
}
