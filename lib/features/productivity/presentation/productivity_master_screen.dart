import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../application/productivity_controller.dart';
import '../domain/productivity_record.dart';

class ProductivityMasterScreen extends StatelessWidget {
  const ProductivityMasterScreen({required this.controller, super.key});
  final ProductivityController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context).productivityMaster),
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context);
          final summaries = controller.summaries;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.text('保存済み実績'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        l10n.itemCountWithLimit(
                          controller.records.length,
                          controller.recordLimit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!controller.canAdd)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.text('保存上限に達しています。既存データは引き続き閲覧できます。'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (summaries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).text('保存された実績はありません'),
                    ),
                  ),
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
        title: Text(AppLocalizations.of(context).text('実績を削除')),
        content: Text(
          AppLocalizations.of(context).choose(
            japanese: '${record.siteName}の実績を削除しますか？',
            english: 'Delete the actual record for ${record.siteName}?',
            simplifiedChinese: '要删除${record.siteName}的实际记录吗？',
            traditionalChinese: '要刪除${record.siteName}的實績紀錄嗎？',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).delete),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          summary.taskName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          l10n.choose(
            japanese:
                '${summary.trade}・${summary.unit}・実績${summary.recordCount}件',
            english:
                '${l10n.text(summary.trade)} · ${l10n.productivityUnit(summary.unit)} · ${summary.recordCount} records',
            simplifiedChinese:
                '${l10n.text(summary.trade)}・${l10n.productivityUnit(summary.unit)}・${summary.recordCount}条记录',
            traditionalChinese:
                '${l10n.text(summary.trade)}・${l10n.productivityUnit(summary.unit)}・${summary.recordCount}筆實績',
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          _row(
            l10n.text('基準生産性'),
            summary.standardProductivity == null
                ? '—'
                : _productivity(
                    l10n,
                    summary.standardProductivity!,
                    summary.unit,
                  ),
          ),
          _row(
            l10n.text('平均実績生産性'),
            _productivity(l10n, summary.averageProductivity, summary.unit),
          ),
          _row(
            l10n.text('平均実績歩掛'),
            _laborRate(l10n, summary.averageActualLaborRate, summary.unit),
          ),
          if (summary.averageHourlyProductivity != null)
            _row(
              l10n.text('平均時間当たり生産性'),
              _hourlyProductivity(
                l10n,
                summary.averageHourlyProductivity!,
                summary.unit,
              ),
            ),
          _row(
            l10n.text('最小歩掛'),
            _laborRate(l10n, summary.minimumLaborRate, summary.unit),
          ),
          _row(
            l10n.text('最大歩掛'),
            _laborRate(l10n, summary.maximumLaborRate, summary.unit),
          ),
          const Divider(height: 24),
          ...summary.records.map(
            (record) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(record.siteName),
              subtitle: Text(_recordDetails(l10n, record)),
              trailing: IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(record),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
  static String _date(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

  static String _laborRate(
    AppLocalizations l10n,
    double value,
    String storedUnit,
  ) {
    final unit = l10n.productivityUnit(storedUnit);
    final suffix = l10n.choose(
      japanese: '人工/$unit',
      english: 'labor-days/$unit',
      simplifiedChinese: '人工/$unit',
      traditionalChinese: '人工/$unit',
    );
    return '${value.toStringAsFixed(3)} $suffix';
  }

  static String _productivity(
    AppLocalizations l10n,
    double value,
    String storedUnit,
  ) {
    final unit = l10n.productivityUnit(storedUnit);
    final suffix = l10n.choose(
      japanese: '$unit/人日',
      english: '$unit/person-day',
      simplifiedChinese: '$unit/人日',
      traditionalChinese: '$unit/人日',
    );
    return '${value.toStringAsFixed(2)} $suffix';
  }

  static String _hourlyProductivity(
    AppLocalizations l10n,
    double value,
    String storedUnit,
  ) {
    final unit = l10n.productivityUnit(storedUnit);
    final suffix = l10n.choose(
      japanese: '$unit/人時',
      english: '$unit/person-hour',
      simplifiedChinese: '$unit/人工时',
      traditionalChinese: '$unit/人工時',
    );
    return '${value.toStringAsFixed(2)} $suffix';
  }

  static String _recordDetails(
    AppLocalizations l10n,
    ProductivityRecord record,
  ) {
    final unit = l10n.productivityUnit(record.unit);
    final work = l10n.choose(
      japanese:
          '${_compactNumber(record.workers)}人 × ${_compactNumber(record.workDays)}日 = ${record.actualLabor.toStringAsFixed(2)}人工',
      english:
          '${_compactNumber(record.workers)} workers × ${_compactNumber(record.workDays)} days = ${record.actualLabor.toStringAsFixed(2)} labor-days',
      simplifiedChinese:
          '${_compactNumber(record.workers)}人 × ${_compactNumber(record.workDays)}天 = ${record.actualLabor.toStringAsFixed(2)}人工',
      traditionalChinese:
          '${_compactNumber(record.workers)}人 × ${_compactNumber(record.workDays)}天 = ${record.actualLabor.toStringAsFixed(2)}人工',
    );
    final details = <String>[
      '${_date(record.workDate)}　${record.quantity} $unit',
      work,
      if (record.totalPersonHours != null)
        '${l10n.text('延べ人工時間')} ${record.totalPersonHours!.toStringAsFixed(2)}',
      if (record.hourlyProductivity != null)
        '${l10n.text('時間当たり生産性')} ${_hourlyProductivity(l10n, record.hourlyProductivity!, record.unit)}',
      if (record.conditions.isNotEmpty) record.conditions,
    ];
    return details.join('\n');
  }

  static String _compactNumber(double value) {
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
