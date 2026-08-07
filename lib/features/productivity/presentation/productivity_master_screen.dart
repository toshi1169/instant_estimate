import 'package:flutter/material.dart';
import '../application/productivity_controller.dart';
import '../domain/productivity_record.dart';

class ProductivityMasterScreen extends StatelessWidget {
  const ProductivityMasterScreen({required this.controller, super.key});
  final ProductivityController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('歩掛・生産性マスタ')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final summaries = controller.summaries;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '保存済み実績',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${controller.records.length} / ${controller.recordLimit}件',
                      ),
                    ],
                  ),
                ),
              ),
              if (!controller.canAdd)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '保存上限に達しています。既存データは引き続き閲覧できます。',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (summaries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('保存された実績はありません')),
                )
              else
                ...summaries.map(
                  (summary) => _SummaryCard(
                    summary: summary,
                    onDelete: (record) => _delete(context, record),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _delete(BuildContext context, ProductivityRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('実績を削除'),
        content: Text('${record.siteName}の実績を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(record.id);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.onDelete});
  final ProductivitySummary summary;
  final ValueChanged<ProductivityRecord> onDelete;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      title: Text(
        summary.taskName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${summary.trade}・${summary.unit}・実績${summary.recordCount}件',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      children: [
        _row(
          '基準歩掛',
          summary.standardLaborRate == null
              ? '—'
              : '${summary.standardLaborRate!.toStringAsFixed(3)} 人工/${summary.unit}',
        ),
        _row(
          '平均実績歩掛',
          '${summary.averageActualLaborRate.toStringAsFixed(3)} 人工/${summary.unit}',
        ),
        _row(
          '平均生産性',
          '${summary.averageProductivity.toStringAsFixed(2)} ${summary.unit}/人工',
        ),
        _row('最小歩掛', summary.minimumLaborRate.toStringAsFixed(3)),
        _row('最大歩掛', summary.maximumLaborRate.toStringAsFixed(3)),
        const Divider(height: 24),
        ...summary.records.map(
          (record) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(record.siteName),
            subtitle: Text(
              '${_date(record.workDate)}　${record.quantity} ${record.unit}\n${record.workers}人 × ${record.workDays}日 = ${record.actualLabor.toStringAsFixed(2)}人工${record.conditions.isEmpty ? '' : '\n${record.conditions}'}',
            ),
            trailing: IconButton(
              tooltip: '削除',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onDelete(record),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value),
      ],
    ),
  );
  static String _date(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
}
