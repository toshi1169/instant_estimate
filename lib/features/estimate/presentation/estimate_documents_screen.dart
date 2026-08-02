import 'package:flutter/material.dart';

import '../application/estimate_controller.dart';
import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import 'estimate_info_editor_screen.dart';
import 'estimate_items_screen.dart';

enum _EstimateDocumentAction { delete }

class EstimateDocumentsScreen extends StatelessWidget {
  const EstimateDocumentsScreen({required this.controller, super.key});

  final EstimateController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('インスタント見積')),
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
                      Text('${controller.estimates.length} / 5件'),
                      const Spacer(),
                      const Text('無料版の保存上限：5件'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    key: const Key('estimateDocumentsList'),
                    padding: const EdgeInsets.all(12),
                    itemCount: controller.estimates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final estimate = controller.estimates[index];
                      return _EstimateDocumentCard(
                        estimate: estimate,
                        index: index,
                        isActive: estimate.info.id == controller.info.id,
                        onTap: () => _openEstimate(context, estimate),
                        onAction: (action) =>
                            _handleAction(context, estimate, action),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createEstimateDocument'),
        onPressed: () => _createEstimate(context),
        icon: const Icon(Icons.add),
        label: const Text('新しい見積'),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    EstimateDocument estimate,
    _EstimateDocumentAction action,
  ) async {
    switch (action) {
      case _EstimateDocumentAction.delete:
        if (controller.estimates.length <= 1) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('最後の見積は削除できません')));
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('見積を削除'),
            content: Text(
              '「${estimate.info.displayName}」を削除しますか？\n含まれる明細もすべて削除されます。',
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
          await controller.deleteEstimate(estimate.info.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('見積を削除しました')));
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('見積を削除できませんでした')));
          }
        }
    }
  }

  Future<void> _createEstimate(BuildContext context) async {
    if (controller.estimates.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('無料版では見積を5件まで保存できます')));
      return;
    }
    final info = await Navigator.of(context).push<EstimateInfo>(
      MaterialPageRoute(
        builder: (_) => EstimateInfoEditorScreen(
          initialInfo: EstimateInfo.initial(DateTime.now()),
        ),
      ),
    );
    if (info == null || !context.mounted) return;
    try {
      await controller.createEstimate(info);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('新しい見積を作成できませんでした')));
      }
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstimateItemsScreen(controller: controller),
      ),
    );
  }

  Future<void> _openEstimate(
    BuildContext context,
    EstimateDocument estimate,
  ) async {
    try {
      await controller.selectEstimate(estimate.info.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('見積を開けませんでした')));
      }
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstimateItemsScreen(controller: controller),
      ),
    );
  }
}

class _EstimateDocumentCard extends StatelessWidget {
  const _EstimateDocumentCard({
    required this.estimate,
    required this.index,
    required this.isActive,
    required this.onTap,
    required this.onAction,
  });

  final EstimateDocument estimate;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  final ValueChanged<_EstimateDocumentAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('estimateDocument$index'),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(child: Text(estimate.info.displayName)),
            if (isActive)
              const Chip(
                key: Key('activeEstimateDocument'),
                label: Text('追加先'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            [
              if (estimate.info.siteName.isNotEmpty) estimate.info.siteName,
              '${estimate.items.length}明細',
              '合計 ¥ ${_money(estimate.totalAmount)}',
            ].join('　'),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<_EstimateDocumentAction>(
              key: Key('estimateDocumentMenu$index'),
              tooltip: '見積メニュー',
              onSelected: onAction,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _EstimateDocumentAction.delete,
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('削除'),
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

String _money(double value) {
  final rounded = value.round();
  return rounded.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}
