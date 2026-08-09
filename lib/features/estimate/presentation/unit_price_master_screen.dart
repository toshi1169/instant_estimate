import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../application/estimate_controller.dart';
import '../domain/unit_price_master.dart';
import 'unit_price_master_editor_screen.dart';

enum _UnitPriceAction { edit, delete }

class UnitPriceMasterScreen extends StatefulWidget {
  const UnitPriceMasterScreen({required this.controller, super.key});

  final EstimateController controller;

  @override
  State<UnitPriceMasterScreen> createState() => _UnitPriceMasterScreenState();
}

class _UnitPriceMasterScreenState extends State<UnitPriceMasterScreen> {
  final _search = TextEditingController();

  EstimateController get controller => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.unitPriceMaster)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final allPrices = controller.unitPriceMasters;
            if (allPrices.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.text('登録された単価はありません\n右下の「単価を登録」から追加できます'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final prices = allPrices
                .where(
                  (price) => matchesUnitPriceMasterQuery(price, _search.text),
                )
                .toList(growable: false);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: TextField(
                    key: const Key('unitPriceMasterSearch'),
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.text('工種・名称・仕様・単位・摘要を検索'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.text('検索をクリア'),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      l10n.itemCountWithLimit(prices.length, allPrices.length),
                    ),
                  ),
                ),
                Expanded(
                  child: prices.isEmpty
                      ? Center(child: Text(l10n.text('一致する単価がありません')))
                      : ListView.separated(
                          key: const Key('unitPriceMasterList'),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
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
                                          ? l10n.text('未入力')
                                          : '¥ ${_displayPrice(price.unitPrice!)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    PopupMenuButton<_UnitPriceAction>(
                                      onSelected: (action) =>
                                          _handleAction(context, price, action),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: _UnitPriceAction.edit,
                                          child: Text(l10n.text('編集')),
                                        ),
                                        PopupMenuItem(
                                          value: _UnitPriceAction.delete,
                                          child: Text(l10n.delete),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () => _edit(context, price),
                              ),
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
        key: const Key('addUnitPriceMaster'),
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).text('単価を登録')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('単価を登録しました')),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('単価を登録できませんでした')),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('単価を更新しました')),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('単価を更新できませんでした')),
          ),
        );
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
            title: Text(AppLocalizations.of(context).text('単価を削除')),
            content: Text(
              AppLocalizations.of(context).isEnglish
                  ? 'Delete "${price.name}" from the unit price master?'
                  : '「${price.name}」を単価マスタから削除しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context).delete),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        try {
          await controller.deleteUnitPriceMaster(price.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).text('単価を削除しました')),
              ),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text('単価を削除できませんでした'),
                ),
              ),
            );
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
