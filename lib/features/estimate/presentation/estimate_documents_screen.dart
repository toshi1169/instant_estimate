import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../application/estimate_controller.dart';
import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import 'estimate_info_editor_screen.dart';
import 'estimate_items_screen.dart';
import 'unit_price_master_screen.dart';

enum _EstimateDocumentAction { duplicate, delete }

class EstimateDocumentsScreen extends StatelessWidget {
  const EstimateDocumentsScreen({required this.controller, super.key});

  final EstimateController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.instantEstimate),
        actions: [
          IconButton(
            key: const Key('openUnitPriceMaster'),
            tooltip: strings.unitPriceMaster,
            icon: const Icon(Icons.price_change_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UnitPriceMasterScreen(controller: controller),
              ),
            ),
          ),
        ],
      ),
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
                      Text(
                        controller.estimateLimit == null
                            ? strings.itemCount(controller.estimates.length)
                            : strings.itemCountWithLimit(
                                controller.estimates.length,
                                controller.estimateLimit!,
                              ),
                      ),
                      const Spacer(),
                      Text(
                        controller.estimateLimit == null
                            ? strings.text('完全版：件数制限なし')
                            : strings.currentSaveLimit(
                                controller.estimateLimit!,
                              ),
                      ),
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
        label: Text(strings.text('新しい見積')),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    EstimateDocument estimate,
    _EstimateDocumentAction action,
  ) async {
    switch (action) {
      case _EstimateDocumentAction.duplicate:
        if (!controller.canCreateEstimate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).freeEstimateLimit),
            ),
          );
          return;
        }
        try {
          await controller.duplicateEstimate(estimate.info.id);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text('見積を複製できませんでした'),
                ),
              ),
            );
          }
          return;
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('見積を複製しました')),
          ),
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EstimateItemsScreen(controller: controller),
          ),
        );
      case _EstimateDocumentAction.delete:
        if (controller.estimates.length <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).text('最後の見積は削除できません')),
            ),
          );
          return;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).text('見積を削除')),
            content: Text(
              AppLocalizations.of(
                context,
              ).deleteEstimateQuestion(estimate.info.displayName),
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
          await controller.deleteEstimate(estimate.info.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).text('見積を削除しました')),
              ),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).text('見積を削除できませんでした'),
                ),
              ),
            );
          }
        }
    }
  }

  Future<void> _createEstimate(BuildContext context) async {
    if (!controller.canCreateEstimate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).freeEstimateLimit)),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).text('新しい見積を作成できませんでした'),
            ),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).text('見積を開けませんでした')),
          ),
        );
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
    final strings = AppLocalizations.of(context);
    return Card(
      key: Key('estimateDocument$index'),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(child: Text(estimate.info.displayName)),
            if (isActive)
              Chip(
                key: Key('activeEstimateDocument'),
                label: Text(strings.text('追加先')),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            [
              if (estimate.info.siteName.isNotEmpty) estimate.info.siteName,
              strings.estimateDetails(estimate.items.length),
              '${strings.text('税込')} ¥ ${_money(estimate.grandTotalAmount.toDouble())}',
            ].join('　'),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<_EstimateDocumentAction>(
              key: Key('estimateDocumentMenu$index'),
              tooltip: strings.text('見積メニュー'),
              onSelected: onAction,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _EstimateDocumentAction.duplicate,
                  child: ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(strings.text('複製')),
                  ),
                ),
                PopupMenuItem(
                  value: _EstimateDocumentAction.delete,
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(strings.delete),
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
