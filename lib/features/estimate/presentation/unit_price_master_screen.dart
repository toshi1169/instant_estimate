import 'package:flutter/material.dart';

import '../application/estimate_controller.dart';
import '../domain/unit_price_master.dart';
import 'unit_price_master_editor_screen.dart';

enum _UnitPriceAction { edit, delete }

class UnitPriceMasterScreen extends StatelessWidget {
  const UnitPriceMasterScreen({required this.controller, super.key});

  final EstimateController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('単価マスタ')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final prices = controller.unitPriceMasters;
            if (prices.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '登録された単価はありません\n右下の「単価を登録」から追加できます',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              key: const Key('unitPriceMasterList'),
              padding: const EdgeInsets.all(12),
              itemCount: prices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final price = prices[index];
                return Card(
                  child: ListTile(
                    key: Key('unitPriceMaster-${price.id}'),
                    title: Text(price.name),
                    subtitle: Text(_subtitle(price)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          price.unitPrice == null
                              ? '未入力'
                              : '¥ ${_displayPrice(price.unitPrice!)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        PopupMenuButton<_UnitPriceAction>(
                          onSelected: (action) =>
                              _handleAction(context, price, action),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _UnitPriceAction.edit,
                              child: Text('編集'),
                            ),
                            PopupMenuItem(
                              value: _UnitPriceAction.delete,
                              child: Text('削除'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _edit(context, price),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addUnitPriceMaster'),
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('単価を登録'),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final draft = await Navigator.of(context).push<UnitPriceMasterDraft>(
      MaterialPageRoute(builder: (_) => const UnitPriceMasterEditorScreen()),
    );
    if (draft == null || !context.mounted) return;
    try {
      await controller.addUnitPriceMaster(draft);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('単価を登録しました')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('単価を登録できませんでした')));
      }
    }
  }

  Future<void> _edit(BuildContext context, UnitPriceMaster price) async {
    final draft = await Navigator.of(context).push<UnitPriceMasterDraft>(
      MaterialPageRoute(
        builder: (_) => UnitPriceMasterEditorScreen(
          initialDraft: price.toDraft(),
          isEditing: true,
        ),
      ),
    );
    if (draft == null || !context.mounted) return;
    try {
      await controller.updateUnitPriceMaster(price.id, draft);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('単価を更新しました')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('単価を更新できませんでした')));
      }
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    UnitPriceMaster price,
    _UnitPriceAction action,
  ) async {
    switch (action) {
      case _UnitPriceAction.edit:
        await _edit(context, price);
      case _UnitPriceAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('単価を削除'),
            content: Text('「${price.name}」を単価マスタから削除しますか？'),
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
          await controller.deleteUnitPriceMaster(price.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('単価を削除しました')));
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('単価を削除できませんでした')));
          }
        }
    }
  }
}

String _subtitle(UnitPriceMaster price) {
  final parts = <String>[
    if (price.trade.isNotEmpty) price.trade,
    if (price.specification.isNotEmpty) price.specification,
    if (price.unit.isNotEmpty) '単位：${price.unit}',
    if (price.description.isNotEmpty) price.description,
  ];
  return parts.isEmpty ? '詳細未入力' : parts.join(' ／ ');
}

String _displayPrice(double value) {
  final text = value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
  final parts = text.split('.');
  final grouped = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length == 1 ? grouped : '$grouped.${parts.last}';
}
