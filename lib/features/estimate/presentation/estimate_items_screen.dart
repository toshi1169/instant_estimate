import 'package:flutter/material.dart';

import '../application/estimate_controller.dart';
import '../domain/estimate_item.dart';
import 'estimate_item_editor_screen.dart';

enum _EstimateItemAction { edit, delete }

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
                            onAction: (action) => _handleAction(
                              context,
                              controller.items[index],
                              action,
                            ),
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

  Future<void> _handleAction(
    BuildContext context,
    EstimateItem item,
    _EstimateItemAction action,
  ) async {
    switch (action) {
      case _EstimateItemAction.edit:
        final result = await Navigator.of(context)
            .push<EstimateItemEditorResult>(
              MaterialPageRoute(
                builder: (_) => EstimateItemEditorScreen(
                  initialDraft: item.toDraft(),
                  isEditing: true,
                ),
              ),
            );
        if (result == null || !context.mounted) return;
        try {
          await controller.update(item.id, result.draft);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('見積明細を更新しました')));
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('見積明細を更新できませんでした')));
          }
        }
      case _EstimateItemAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('見積明細を削除'),
            content: Text(
              '「${item.name.isEmpty ? '名称未入力' : item.name}」を削除しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('削除'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        try {
          await controller.delete(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('見積明細を削除しました')));
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('見積明細を削除できませんでした')));
          }
        }
    }
  }
}

class _EstimateItemCard extends StatelessWidget {
  const _EstimateItemCard({
    required this.item,
    required this.index,
    required this.onAction,
  });

  final EstimateItem item;
  final int index;
  final ValueChanged<_EstimateItemAction> onAction;

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
                PopupMenuButton<_EstimateItemAction>(
                  key: Key('estimateItemMenu$index'),
                  onSelected: onAction,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _EstimateItemAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('編集'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _EstimateItemAction.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('削除'),
                      ),
                    ),
                  ],
                ),
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
