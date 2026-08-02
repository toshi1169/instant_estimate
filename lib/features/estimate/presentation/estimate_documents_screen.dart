import 'package:flutter/material.dart';

import '../application/estimate_controller.dart';
import '../domain/estimate_document.dart';
import '../domain/estimate_info.dart';
import 'estimate_info_editor_screen.dart';
import 'estimate_items_screen.dart';

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
  });

  final EstimateDocument estimate;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

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
        trailing: const Icon(Icons.chevron_right),
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
